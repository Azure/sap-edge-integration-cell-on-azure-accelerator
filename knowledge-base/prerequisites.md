# Prerequisites & Sizing — SAP Edge Integration Cell on Azure

> **Audience**: SRE, DevOps
> **Last verified**: June 2026
> **SAP Reference**: [SAP Note 3247839](https://me.sap.com/notes/3247839)

---

## Pre-Deployment Checklist

Use this checklist before provisioning infrastructure for SAP EIC on AKS:

- [ ] Azure subscription with sufficient quota for target VM SKUs
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform installed (or use the provided [devcontainer](../.devcontainer/devcontainer.json) / [Codespaces](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=773743527))
- [ ] SAP BTP global account with SAP Integration Suite subscription
- [ ] `edge_integration_cell` service plan entitlement assigned to the target subaccount
- [ ] Cloud Integration (CPI) capability activated in the SAP BTP subaccount
- [ ] DNS zone available for creating endpoint records
- [ ] TLS certificate for the integration flow endpoint domain
- [ ] Outbound HTTPS (port 443) connectivity from the AKS cluster to SAP BTP

---

## Supported AKS Versions

> ⚠️ **Always verify the latest SAP-supported stable AKS version before deployment.** SAP only certifies specific Kubernetes versions for EIC. Deploying on an unsupported version may cause installation failures or unsupported-configuration notices from SAP.

**How to check:**

1. Review [SAP Note 3247839](https://me.sap.com/notes/3247839) for the current supported version list.
2. Cross-reference with [AKS supported Kubernetes versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions).
3. Use the Azure CLI to list available versions in your region:

```bash
# List available AKS versions in a specific region
az aks get-versions --location <region> --output table
```

**Current quickstart pin**: `1.30.4` (in [`quickstart/aks/main.tf`](../quickstart/aks/main.tf)) — verify this is still SAP-supported before use.

---

## VM SKU Requirements

SAP EIC requires sufficient compute capacity for the integration runtime, Istio service mesh, and platform components.

### Minimum Requirements (Quickstart / Non-Production)

| Parameter | Value | Notes |
|-----------|-------|-------|
| VM SKU | `Standard_D8ds_V5` | 8 vCPUs, 32 GiB RAM, temp storage SSD |
| Node count | 2 | Default in quickstart; adjust via `node_count` variable |
| Network plugin | `kubenet` | Simplest option; production should evaluate Azure CNI |
| Load balancer | Standard SKU | Required for outbound and inbound traffic |

### Production Sizing Guidance

| Consideration | Recommendation |
|---------------|----------------|
| Node count | 3+ nodes for high availability across availability zones |
| VM SKU | `Standard_D8ds_V5` or larger depending on iFlow throughput |
| OS disk | Managed Premium SSD (default for D-series) |
| Ephemeral OS disk | Evaluate for performance-sensitive workloads |
| Max pods per node | Default 110 (kubenet); evaluate based on EIC pod density |
| PostgreSQL | `GP_Standard_D2s_v3` for the EIC data store (production-ready tier) |

### Verify VM SKU Availability

```bash
# Check if a specific VM SKU is available in your target region
az vm list-skus --location <region> --size Standard_D8ds --output table
```

---

## Azure Resource Requirements

### Quickstart Terraform Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `resource_group_name` | Yes | Prefix for resource group and AKS cluster names | `eic-on-azure` |
| `location` | Yes | Azure region for deployment | `westeurope` |
| `node_count` | No | Number of nodes in the default pool (default: 2) | `3` |

### SAP BTP Terraform Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `globalaccount` | Yes | SAP BTP global account subdomain |
| `subaccount_id` | Yes | Target SAP BTP subaccount ID |
| `BTP_USERNAME` (env) | Yes | SAP BTP authentication username |
| `BTP_PASSWORD` (env) | Yes | SAP BTP authentication password |

---

## Network Prerequisites

| Requirement | Detail |
|-------------|--------|
| Outbound HTTPS | Port 443 to SAP BTP endpoints — **mandatory** for heartbeat and artifact sync |
| Inbound HTTPS | Port 443 to AKS LoadBalancer IP — required for external integration flow invocation |
| DNS | A-record pointing to the Istio ingress gateway external IP |
| TLS | Valid certificate for the integration flow endpoint FQDN |

### Azure-Specific Networking

- **kubenet** (quickstart): Simpler setup, nodes get Azure VNet IPs, pods get IPs from a separate CIDR. Sufficient for dev/test.
- **Azure CNI** (production recommendation): Pods receive VNet IPs directly. Required for tighter network policy enforcement and VNet integration with other Azure services.
- **Private AKS clusters**: Supported but requires additional configuration for SAP BTP outbound connectivity (e.g., Azure Firewall, NAT Gateway).

---

## Azure Subscription Quotas to Verify

Before deploying, ensure your subscription has sufficient quota:

```bash
# Check compute quota in your target region
az vm list-usage --location <region> --output table | Select-String "Standard D"
```

| Resource | Minimum Quota |
|----------|---------------|
| Standard Dv5 Family vCPUs | 16+ (for 2× D8ds_V5 nodes) |
| Public IP Addresses | 1+ (for LoadBalancer) |
| Standard Load Balancers | 1 |
| Managed Disks | Per node count |

---

## Related Resources

- [SAP Note 3247839 — EIC Prerequisites](https://me.sap.com/notes/3247839)
- [Prepare for deployment on AKS (SAP Docs)](https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-for-deployment-on-azure-kubernetes-service-aks)
- [AKS Supported Kubernetes Versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions)
- [Azure VM Sizes — Dv5 Series](https://learn.microsoft.com/azure/virtual-machines/dv5-dsv5-series)
