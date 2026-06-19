# Troubleshooting — SAP Edge Integration Cell on Azure

> **Audience**: SRE, Support
> **Last verified**: June 2026
> **Scope**: Common failure modes during deployment, runtime, and day-2 operations

---

## Diagnostic Quick Reference

Before diving into specific issues, gather baseline diagnostics:

```bash
# AKS cluster health
az aks show --resource-group <rg> --name <cluster> --query "powerState" --output table

# Node status
kubectl get nodes -o wide

# All pods across all namespaces with status
kubectl get pods --all-namespaces --field-selector=status.phase!=Running

# Istio ingress gateway status
kubectl -n istio-system get pods
kubectl -n istio-system get service istio-ingressgateway

# Recent events (last 1 hour, sorted)
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -50
```

---

## Infrastructure Deployment Issues

### Terraform Init Fails with Provider Errors

| Severity | **Medium** |
|----------|-----------|
| Symptom | `terraform init` fails with provider download or version constraint errors |
| Cause | Provider version mismatch or network issue |
| Resolution | Steps below |

1. Verify you are running from inside the sample directory (`quickstart/aks/` or `production-ready/aks/`), not the repo root.
2. Check `provider.tf` for the version constraint — quickstart pins `azurerm ~> 3.0`.
3. Clear cached providers and retry:
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   terraform init
   ```
4. If behind a corporate proxy, ensure `HTTPS_PROXY` is set.

### Terraform Apply Fails with Quota Errors

| Severity | **High** |
|----------|---------|
| Symptom | `terraform apply` fails with `QuotaExceeded` or `SkuNotAvailable` |
| Cause | Insufficient subscription quota or VM SKU not available in region |
| Resolution | Steps below |

1. Check quota:
   ```bash
   az vm list-usage --location <region> --output table | Select-String "Standard D"
   ```
2. If quota is insufficient, request an increase via the Azure Portal → Subscriptions → Usage + quotas.
3. If the SKU is unavailable in the region, check alternative regions:
   ```bash
   az vm list-skus --size Standard_D8ds --output table
   ```

### AKS Cluster Stuck in "Creating" State

| Severity | **High** |
|----------|---------|
| Symptom | AKS cluster provisioning does not complete within 15 minutes |
| Cause | Subscription policy restrictions, network issues, or resource provider not registered |
| Resolution | Steps below |

1. Check provisioning state:
   ```bash
   az aks show --resource-group <rg> --name <cluster> --query "provisioningState"
   ```
2. Review activity log for the resource group:
   ```bash
   az monitor activity-log list --resource-group <rg> --status Failed --output table
   ```
3. Ensure required resource providers are registered:
   ```bash
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.Compute
   ```
   Or set `ARM_SKIP_PROVIDER_REGISTRATION=true` as noted in the [quickstart docs](../../quickstart/aks/README.md).

---

## EIC Installation Issues

### Istio Ingress Gateway Has No External IP

| Severity | **Critical** |
|----------|-------------|
| Symptom | `kubectl -n istio-system get service istio-ingressgateway` shows `<pending>` for EXTERNAL-IP |
| Cause | LoadBalancer service cannot allocate a public IP |
| Resolution | Steps below |

1. Check for Azure LoadBalancer events:
   ```bash
   kubectl -n istio-system describe service istio-ingressgateway
   ```
2. Verify public IP quota in your subscription.
3. Ensure the AKS cluster has the correct `network_profile.load_balancer_sku = "standard"`.
4. If using a private cluster, a public LoadBalancer may be blocked by policy — consider an internal LoadBalancer with Azure Application Gateway.

### EIC Pods CrashLooping

| Severity | **Critical** |
|----------|-------------|
| Symptom | SAP EIC pods are in `CrashLoopBackOff` status |
| Cause | Configuration error, missing secrets, or insufficient resources |
| Resolution | Steps below |

1. Identify the failing pods:
   ```bash
   kubectl get pods --all-namespaces | Select-String "CrashLoop"
   ```
2. Check pod logs:
   ```bash
   kubectl logs <pod-name> -n <namespace> --previous
   ```
3. Check pod resource requests vs node capacity:
   ```bash
   kubectl describe node <node-name> | Select-String -Context 0,20 "Allocated resources"
   ```
4. If resource-constrained, scale the node pool:
   ```bash
   az aks nodepool scale --resource-group <rg> --cluster-name <cluster> --name default --node-count 3
   ```

### EIC Heartbeat Failure to SAP BTP

| Severity | **Critical** |
|----------|-------------|
| Symptom | SAP BTP shows EIC runtime as "Disconnected" or "Unreachable" |
| Cause | Outbound HTTPS (443) blocked from cluster to SAP BTP |
| Resolution | Steps below |

1. Test outbound connectivity from a pod:
   ```bash
   kubectl run test-egress --image=busybox --rm -it --restart=Never -- wget -qO- https://help.sap.com --timeout=10
   ```
2. If blocked, check:
   - Azure NSG rules on the AKS subnet
   - Azure Firewall or UDR rules if using a hub-spoke topology
   - Corporate proxy settings
3. For private clusters, ensure a NAT Gateway or Azure Firewall allows outbound HTTPS to SAP BTP endpoints.

---

## Runtime & Operational Issues

### Integration Flow Endpoint Returns 502/503

| Severity | **High** |
|----------|---------|
| Symptom | HTTP calls to integration flow endpoints return 502 Bad Gateway or 503 Service Unavailable |
| Cause | Istio routing misconfiguration, backend pod not ready, or DNS not pointing to correct IP |
| Resolution | Steps below |

1. Verify the DNS record points to the current Istio ingress gateway IP:
   ```bash
   kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```
2. Check Istio virtual service and gateway configuration.
3. Verify the target integration flow is deployed and its pod is running.
4. Check Istio proxy logs:
   ```bash
   kubectl -n istio-system logs deployment/istio-ingressgateway
   ```

### Node Pool Scaling Failures

| Severity | **Medium** |
|----------|-----------|
| Symptom | `az aks nodepool scale` fails or new nodes are stuck in NotReady |
| Cause | Quota limits, subnet exhaustion, or image pull failures |
| Resolution | Steps below |

1. Check node status and conditions:
   ```bash
   kubectl describe node <node-name> | Select-String "Conditions" -Context 0,10
   ```
2. Verify subnet has available IP addresses (for Azure CNI):
   ```bash
   az network vnet subnet show --resource-group <rg> --vnet-name <vnet> --name <subnet> --query "addressPrefix"
   ```
3. Check AKS cluster autoscaler events if autoscaler is enabled:
   ```bash
   kubectl -n kube-system logs deployment/cluster-autoscaler | tail -30
   ```

### Certificate Expiry

| Severity | **High** |
|----------|---------|
| Symptom | HTTPS calls to integration endpoints fail with TLS errors |
| Cause | TLS certificate for the ingress domain has expired |
| Resolution | Steps below |

1. Check certificate expiry:
   ```bash
   echo | openssl s_client -connect <endpoint>:443 2>/dev/null | openssl x509 -noout -dates
   ```
2. Renew the certificate and update the Kubernetes TLS secret.
3. Restart the Istio ingress gateway to pick up the new certificate:
   ```bash
   kubectl -n istio-system rollout restart deployment/istio-ingressgateway
   ```

---

## Diagnostics Summary Table

| Issue | Severity | Key Diagnostic Command |
|-------|----------|----------------------|
| Terraform provider errors | Medium | `terraform init` in correct directory |
| Quota exceeded | High | `az vm list-usage --location <region>` |
| AKS stuck creating | High | `az aks show --query provisioningState` |
| No external IP on ingress | Critical | `kubectl -n istio-system get svc istio-ingressgateway` |
| EIC pods CrashLoopBackOff | Critical | `kubectl logs <pod> -n <ns> --previous` |
| BTP heartbeat failure | Critical | Test outbound: `wget` from pod to `help.sap.com` |
| 502/503 on iFlow endpoint | High | Check DNS, Istio config, pod readiness |
| Node scaling failure | Medium | `kubectl describe node`, quota check |
| Certificate expiry | High | `openssl s_client -connect <endpoint>:443` |

---

## Related Resources

- [AKS Troubleshooting Guide (Microsoft Learn)](https://learn.microsoft.com/troubleshoot/azure/azure-kubernetes/welcome-azure-kubernetes)
- [SAP EIC Documentation](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell)
- [Istio Troubleshooting](https://istio.io/latest/docs/ops/diagnostic-tools/)
