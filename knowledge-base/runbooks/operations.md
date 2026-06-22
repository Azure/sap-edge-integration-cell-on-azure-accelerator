# Operations & Runbooks — SAP Edge Integration Cell on Azure

> **Audience**: SRE, Platform Engineering
> **Last verified**: June 2026
> **Scope**: Day-2 operations for SAP EIC running on AKS

---

## Health Check Runbook

Run these checks regularly or when investigating alerts:

### Cluster-Level Health

```bash
# AKS cluster power state and provisioning status
az aks show --resource-group <rg> --name <cluster> --query "{powerState:powerState.code, provisioning:provisioningState}" --output table

# Node health
kubectl get nodes -o wide

# Resource utilization per node
kubectl top nodes

# Pods not in Running state
kubectl get pods --all-namespaces --field-selector=status.phase!=Running
```

### EIC-Specific Health

```bash
# Istio control plane health
kubectl -n istio-system get pods

# Istio ingress gateway — verify external IP is assigned
kubectl -n istio-system get service istio-ingressgateway

# Check EIC namespaces for pod readiness
kubectl get pods --all-namespaces -l app.kubernetes.io/part-of=edge-integration-cell
```

### SAP BTP Connectivity

```bash
# Test outbound connectivity from cluster to SAP BTP
kubectl run test-egress --image=busybox --rm -it --restart=Never -- wget -qO- https://help.sap.com --timeout=10
```

Verify the EIC runtime status in the SAP BTP cockpit → Integration Suite → Edge Lifecyle Management.

---

## Scaling

### Manual Node Pool Scaling

Scale the default node pool to handle increased integration flow workloads:

```bash
# Scale to 3 nodes
az aks nodepool scale \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name default \
  --node-count 3

# Verify new nodes are Ready
kubectl get nodes -w
```

### Enabling Cluster Autoscaler

For dynamic scaling based on pod resource demand:

```bash
az aks nodepool update \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name default \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5
```

> ⚠️ Ensure your subscription quota supports the max node count × VM vCPUs.

### Verifying Scaling

```bash
# Check current node count and allocatable resources
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory

# Monitor autoscaler decisions
kubectl -n kube-system logs deployment/cluster-autoscaler --tail=50
```

---

## Kubernetes Version Upgrades

### Pre-Upgrade Checklist

1. **Verify SAP support**: Check [SAP Note 3247839](https://me.sap.com/notes/3247839) — SAP only supports specific Kubernetes versions.
2. **Check available versions**:
   ```bash
   az aks get-upgrades --resource-group <rg> --name <cluster> --output table
   ```
3. **Review breaking changes**: Check the [AKS release notes](https://github.com/Azure/AKS/releases) for deprecations.
4. **Backup**: Ensure EIC configuration is backed up in SAP BTP.

### Upgrade Procedure

```bash
# Upgrade control plane first
az aks upgrade \
  --resource-group <rg> \
  --name <cluster> \
  --kubernetes-version <target-version> \
  --control-plane-only

# Then upgrade node pools (one at a time in production)
az aks nodepool upgrade \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name default \
  --kubernetes-version <target-version>
```

### Post-Upgrade Verification

```bash
# Confirm version
az aks show --resource-group <rg> --name <cluster> --query "kubernetesVersion"

# Verify all nodes upgraded
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion

# Check EIC pods restarted cleanly
kubectl get pods --all-namespaces --field-selector=status.phase!=Running
```

---

## Certificate Management

### TLS Certificate Rotation for Istio Ingress

When the TLS certificate for your integration flow endpoint needs renewal:

1. Obtain a new certificate for your FQDN (e.g., `eic.example.com`).
2. Update the Kubernetes TLS secret:
   ```bash
   kubectl -n istio-system create secret tls eic-tls-cert \
     --cert=path/to/tls.crt \
     --key=path/to/tls.key \
     --dry-run=client -o yaml | kubectl apply -f -
   ```
3. Restart the Istio ingress gateway:
   ```bash
   kubectl -n istio-system rollout restart deployment/istio-ingressgateway
   ```
4. Verify the new certificate:
   ```bash
   echo | openssl s_client -connect <endpoint>:443 2>/dev/null | openssl x509 -noout -dates -subject
   ```

### AKS Cluster Certificate Rotation

AKS auto-rotates cluster certificates. To manually trigger rotation:

```bash
az aks rotate-certs --resource-group <rg> --name <cluster>
```

> ⚠️ This operation restarts all nodes. Plan for downtime.

---

## Monitoring

### Recommended Azure Monitor Metrics

| Metric | Resource | Alert Threshold | Rationale |
|--------|----------|----------------|-----------|
| Node CPU % | AKS nodes | > 80% sustained for 10 min | Scaling trigger |
| Node Memory % | AKS nodes | > 85% sustained for 10 min | OOM risk |
| Pod Restart Count | All namespaces | > 5 in 15 min | CrashLoop detection |
| LoadBalancer Health | Public IP | < 100% | Ingress availability |
| Outbound data bytes | AKS | Anomaly detection | BTP sync issues |

### Enabling Container Insights

```bash
az aks enable-addons \
  --resource-group <rg> \
  --name <cluster> \
  --addons monitoring \
  --workspace-resource-id <log-analytics-workspace-id>
```

### Key Log Queries (KQL)

```kql
// Pods with restart count > 3 in the last hour
KubePodInventory
| where TimeGenerated > ago(1h)
| where ContainerRestartCount > 3
| project TimeGenerated, Namespace, Name, ContainerRestartCount
| order by ContainerRestartCount desc

// Failed outbound connections (potential BTP heartbeat issues)
AzureDiagnostics
| where Category == "kube-audit"
| where TimeGenerated > ago(1h)
| where ResultType == "Failed"
| summarize count() by bin(TimeGenerated, 5m)
```

---

## Disaster Recovery

### Backup Strategy

| Component | Backup Method | Frequency |
|-----------|---------------|-----------|
| Integration flows (iFlows) | Managed by SAP BTP — iFlows are synced from the cloud | Continuous |
| Kubernetes cluster state | Velero or Azure Backup for AKS (preview) | Daily |
| PostgreSQL (production-ready) | Azure-managed backups (7-day retention default) | Continuous |
| TLS certificates | Store in Azure Key Vault | On rotation |
| `terraform.tfvars` | Store securely outside the repo | On change |

### Recovery Procedure

For a complete cluster re-deployment:

1. Re-provision infrastructure:
   ```bash
   cd quickstart/aks  # or production-ready/aks
   terraform init
   terraform apply
   ```
2. Re-install EIC via SAP BTP Edge Lifecycle Management.
3. Re-deploy integration flows from SAP Integration Suite.
4. Update DNS records to point to the new Istio ingress gateway IP.
5. Re-apply TLS certificates.

> Integration flows are stored in SAP BTP and re-synced automatically. The main recovery effort is infrastructure and networking.

---

## Related Resources

- [AKS Operations Best Practices (Microsoft Learn)](https://learn.microsoft.com/azure/aks/best-practices)
- [AKS Monitoring with Container Insights](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)
- [SAP EIC Edge Lifecycle Management](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell)
- [Velero for AKS Backup](https://learn.microsoft.com/azure/aks/hybrid/backup-workload-cluster)
