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

### Endpoint Error: `artifactNotFound` / "No API endpoint is registered with this host and path"

| Severity | **High** |
|----------|---------|
| Symptom | API call returns `{"artifactNotFound","message":"No API endpoint is registered with this host and path. Please ensure that the respective artifact is successfully deployed."}` |
| Cause | Host/path does not match the deployed iFlow endpoint, artifact is not deployed to EIC runtime, request targets the wrong virtual host, or runtime routing state is stale after deployment changes |
| Resolution | Steps below |

1. Confirm ingress endpoint and host are aligned:
   ```bash
   kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```
2. Confirm the request host mapping is correct for your setup (custom DNS or `nip.io` in temporary PoC scenarios).
3. In SAP Integration Suite, verify the target iFlow is **deployed to Edge Integration Cell runtime** (not only saved or deployed to cloud runtime).
4. Verify the request path exactly matches the HTTP sender endpoint path configured in the iFlow.
5. Validate EIC runtime namespaces are healthy (`edge-icell`, `edge-icell-services`, `edge-icell-ela`, `edgelm`):
   ```bash
   kubectl get pods -n edge-icell
   kubectl get pods -n edge-icell-services
   kubectl get pods -n edge-icell-ela
   kubectl get pods -n edgelm
   ```
6. If all checks above are healthy but `artifactNotFound` persists, restart ingress and EIC service deployments to refresh route/runtime state:
   ```bash
   kubectl -n istio-system rollout restart deployment/istio-ingressgateway
   kubectl -n edge-icell-services rollout restart deployment --all
   ```
7. Re-test the endpoint after pods are back to `Running` and `Ready`.

### Outbound TLS Error: `java.net.ConnectException: PKIX path building failed`

| Severity | **High** |
|----------|---------|
| Symptom | Runtime logs show `java.net.ConnectException: PKIX path building failed ... unable to find valid certification path to requested target` |
| Cause | Remote server certificate chain is not trusted by the runtime trust store (missing CA/intermediate certs or corporate TLS interception CA not imported) |
| Resolution | Steps below |

1. Identify the failing target endpoint from iFlow logs/trace.
2. Inspect the certificate chain presented by the target:
   ```bash
   echo | openssl s_client -connect <target-host>:443 -showcerts
   ```
3. Import the required root/intermediate CA certificates into the trust material used by the integration runtime (SAP Integration Suite/EIC trust setup).
4. If your company uses TLS interception/proxy, import the corporate proxy CA as trusted.
5. Re-test the iFlow call. For client-side PoC smoke tests from your workstation, `curl -k` only bypasses local client verification and does not fix runtime trust for outbound calls from EIC.

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
| `artifactNotFound` for host/path | High | Verify iFlow deployment + host/path mapping; if still failing with healthy pods, restart ingress + `edge-icell-services` deployments |
| `PKIX path building failed` outbound TLS | High | Inspect chain with `openssl s_client`, import missing CAs |
| Node scaling failure | Medium | `kubectl describe node`, quota check |
| Certificate expiry | High | `openssl s_client -connect <endpoint>:443` |

---

## Related Resources

- [AKS Troubleshooting Guide (Microsoft Learn)](https://learn.microsoft.com/troubleshoot/azure/azure-kubernetes/welcome-azure-kubernetes)
- [SAP EIC Documentation](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell)
- [Istio Troubleshooting](https://istio.io/latest/docs/ops/diagnostic-tools/)
