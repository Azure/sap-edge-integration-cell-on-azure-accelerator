# Architecture Overview — SAP Edge Integration Cell on Azure

> **Audience**: SRE, Platform Engineering
> **Last verified**: June 2026
> **Related IaC**: [`quickstart/aks/`](../quickstart/aks/), [`production-ready/aks/`](../production-ready/aks/)

---

## What Is SAP Edge Integration Cell?

SAP Edge Integration Cell (EIC) is a hybrid integration runtime from SAP that runs **outside SAP BTP** — on customer-managed Kubernetes clusters. It executes SAP Integration Suite integration flows (iFlows) locally while maintaining a control-plane heartbeat connection back to SAP BTP.

**Key characteristics:**

- Runs on any CNCF-conformant Kubernetes distribution; this accelerator targets **Azure Kubernetes Service (AKS)**.
- Requires **outbound internet connectivity** for heartbeats, updates, and artifact synchronization with SAP BTP.
- Does **not** require inbound connectivity from SAP BTP to the cluster.
- Supports hybrid scenarios (cloud-to-on-premises) and fully on-premises scenarios (e.g., SAP PI/PO to ECC within a factory network).

---

## Azure Resource Topology

A typical SAP EIC deployment on AKS provisions the following Azure resources:

### Quickstart Topology (Non-Production)

```
Azure Subscription
└── Resource Group (rg-<name>)
    └── AKS Cluster (k8s-<name>)
        ├── Default Node Pool (Standard_D8ds_V5, 2 nodes)
        ├── Network Plugin: kubenet
        ├── Load Balancer SKU: Standard
        ├── SKU Tier: Free
        └── Identity: SystemAssigned
```

**Terraform source**: [`quickstart/aks/main.tf`](../quickstart/aks/main.tf)

### Production-Ready Topology (In Development)

The production-ready topology extends the quickstart with:

- **Azure Database for PostgreSQL Flexible Server** — persistent data store for EIC.
- **Virtual Network with dedicated subnets** — network isolation and service endpoints.
- **Network Security Groups** — ingress/egress control.
- **Private DNS Zones** — private resolution for PostgreSQL.
- **SSH key management** — secure node access via `azapi_resource_action`.
- Builds on the [AKS baseline reference architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks).

**Terraform source**: [`production-ready/aks/main.tf`](../production-ready/aks/main.tf)

> ⚠️ The production-ready module is under active development and is **not yet internally consistent**. See the [repo README](../README.md) for details.

---

## Kubernetes Components Inside the Cluster

Once EIC is installed on AKS (via SAP's deployment process), the cluster runs:

| Namespace | Components | Purpose |
|-----------|------------|---------|
| `istio-system` | Istio Ingress Gateway, Istiod | Service mesh, TLS termination, traffic routing |
| SAP-managed namespaces | EIC runtime pods, message broker, key store | Integration flow execution, message processing |

### Istio Ingress Gateway

- Exposes integration flow HTTP endpoints externally via a **LoadBalancer** service.
- The external IP of `istio-ingressgateway` in `istio-system` must be mapped to a DNS record for endpoint access.
- TLS certificates must be configured for production use.

```bash
# Retrieve the external IP of the Istio ingress gateway
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## Data Flow

```
┌─────────────────────┐      HTTPS (outbound)      ┌──────────────────┐
│  AKS Cluster        │ ──────────────────────────► │  SAP BTP         │
│  (Edge Int. Cell)   │   heartbeat, artifact sync  │  (Control Plane) │
│                     │ ◄────────────────────────── │                  │
│  ┌───────────────┐  │      config, iFlow deploy   └──────────────────┘
│  │ iFlow Runtime │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │      HTTPS / RFC / SFTP
│  │ Istio Ingress │◄─┼──────────────────────────── External Callers
│  └───────────────┘  │
│          │          │
│  ┌───────▼───────┐  │      JDBC / HTTPS / RFC
│  │ Backend       │──┼──────────────────────────► On-Prem Systems
│  │ Connectivity  │  │                            (SAP ERP, S/4HANA,
│  └───────────────┘  │                             PI/PO, databases)
└─────────────────────┘
```

### Connectivity Model

| Direction | Protocol | Purpose | Firewall Requirement |
|-----------|----------|---------|---------------------|
| Cluster → SAP BTP | HTTPS (443) | Heartbeat, artifact sync, license validation | **Outbound required** |
| External → Cluster | HTTPS (443) | Integration flow invocation via Istio ingress | Inbound to LoadBalancer IP |
| Cluster → On-Prem | JDBC, RFC, SFTP, HTTPS | Backend system connectivity | Network-specific |

---

## SAP BTP Integration

The SAP BTP side requires:

- **SAP Integration Suite** subscription with the `edge_integration_cell` service plan entitlement.
- A **Cloud Integration (CPI)** capability activated in the subaccount.
- Terraform automation for BTP entitlements is available in [`quickstart/sap/`](../quickstart/sap/).

| BTP Terraform Variable | Description |
|------------------------|-------------|
| `globalaccount` | SAP BTP global account subdomain |
| `subaccount_id` | Target subaccount ID |
| `BTP_USERNAME` (env) | SAP BTP login username |
| `BTP_PASSWORD` (env) | SAP BTP login password |

---

## Related Resources

- [SAP EIC on Azure — Microsoft Learn](https://learn.microsoft.com/azure/sap/workloads/sap-edge-integration-cell-with-azure)
- [SAP EIC Documentation](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell)
- [AKS Baseline Reference Architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks)
- [SAP BTP Terraform Provider](https://registry.terraform.io/providers/SAP/btp/latest/docs)
