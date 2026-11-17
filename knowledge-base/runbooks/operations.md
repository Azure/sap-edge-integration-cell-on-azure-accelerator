# Operations & Runbooks — SAP Edge Integration Cell on Azure

> **Audience**: SRE, Platform Engineering
> **Last verified**: November 2026 (alerting reference and PostgreSQL TLS guidance; other procedures last verified June 2026)
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

### PostgreSQL TLS Certificates and Alert Coverage

**Scope**: EIC connecting to **Azure Database for PostgreSQL Flexible Server**. First confirm the database service and the EIC version in use; self-managed PostgreSQL and other services can have different certificate ownership and monitoring.

The [Flexible Server metrics reference](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-dbforpostgresql-flexibleservers-metrics) does **not list a certificate-expiration metric**. Do not assume a native metric alert warns before PostgreSQL TLS certificates expire, or that SAP EIC alerting covers this dependency.

| Certificate or signal | Ownership and SRE implication |
|-----------------------|-------------------------------|
| PostgreSQL server certificate and intermediate CAs | Microsoft manages rotation. According to the [PostgreSQL TLS guidance](https://learn.microsoft.com/azure/postgresql/security/security-tls), routine server and intermediate CA rotations are not announced in advance. Monitoring only the current server certificate's expiry cannot predict a future trust-chain change. |
| Root CAs trusted by the EIC database client | Microsoft announces root CA changes in advance; operators must verify that the actual EIC database-client trust configuration trusts the required roots. Microsoft advises against pinning individual server certificates or trusting intermediate certificates as roots. Confirm the SAP-supported configuration for the deployed EIC version before changing it. |
| TLS client certificates | Flexible Server does not support TLS client-certificate authentication (mTLS). Do not assume an expiring client certificate is the cause without first identifying the actual database service and connection configuration. |
| `connections_failed` and `is_db_alive` | Available platform metrics can support connection-failure and availability alerts, but neither is an expiry warning or proof that EIC trusts the server certificate. Client-side TLS rejection need not be fully reflected in server-side metrics. |

Recommended **local monitoring design**, not a built-in SAP or Azure alert guarantee:

1. Inventory the database FQDN, service type, EIC version, database-client truststore or CA bundle actually in use, certificate validity dates, and renewal owner. Do not assume the relevant trust material is an AKS TLS secret or the ingress certificate.
2. Monitor expiry of the certificates in that actual trust configuration. Example warning windows are 30, 14, and 7 days before expiry; these are local policy choices, not vendor thresholds. Assign an owner to review Microsoft's TLS/root CA change guidance as well: expiry alerts alone do not cover rotations.
3. Use a scheduled check that establishes a **new**, read-only database connection from the EIC network path, with hostname and chain verification and equivalent database-client trust settings. A generic probe with a different truststore does not prove EIC connectivity; an existing pooled connection can mask problems with new handshakes. Alert separately on failed checks and missing check results.
4. Correlate probe failures with EIC database-client TLS errors and PostgreSQL metrics. Route confirmed failures affecting EIC database access as **High**, escalating to **Critical** for a confirmed runtime outage under the local incident policy. Never disable TLS or certificate validation to make a check pass.

**SAP evidence limitation**: A SAP Notes search for EIC PostgreSQL certificate-expiry failures returned no matching notes during this update. No SAP-specific certificate-expiry alert or truststore-update procedure was verified; consult the [SAP EIC alerting reference](#sap-eic-alerting-reference) and confirm version applicability with SAP before making runtime changes.

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

### SAP EIC Alerting Reference

Consult [Alerting (SAP Help Portal)](https://help.sap.com/docs/integration-suite/isuite-edge-integration-cell/alerting) when planning or reviewing alert coverage for SAP Edge Integration Cell. Use the current SAP documentation to verify applicable prerequisites, configuration instructions, and alert behavior for your deployed EIC version.

| SRE task | Guidance |
|----------|----------|
| Review alert coverage | Consult SAP's EIC alerting page alongside AKS infrastructure monitoring; do not treat infrastructure metrics alone as proof of EIC runtime health. |
| Record incident evidence | Capture the alert source, original severity, message, timestamps, affected EIC instance, and any supplied component or namespace identifiers before correlating with AKS observations. |
| Interpret local thresholds | The Azure Monitor thresholds below are repository recommendations, not SAP-defined EIC alert thresholds or severity mappings. |
| Use this reference with an SRE agent | Retrieve the SAP page before citing its details. If its content is unavailable, state that limitation rather than infer alert definitions or remediation steps from this link. |

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
- [SAP EIC Alerting](https://help.sap.com/docs/integration-suite/isuite-edge-integration-cell/alerting)
- [Azure PostgreSQL Flexible Server TLS and Certificate Rotation](https://learn.microsoft.com/azure/postgresql/security/security-tls)
- [Azure PostgreSQL Flexible Server Supported Metrics](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-dbforpostgresql-flexibleservers-metrics)
- [Velero for AKS Backup](https://learn.microsoft.com/azure/aks/hybrid/backup-workload-cluster)
