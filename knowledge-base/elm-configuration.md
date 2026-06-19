# SAP Edge Lifecycle Management (ELM) Configuration Hints — SAP Edge Integration Cell on Azure

> **Audience**: SRE, DevOps, Platform Engineering
> **Last verified**: June 2026
> **Related IaC**: [quickstart/aks](../quickstart/aks/README.md), [production-ready/aks](../production-ready/aks/README.md)

---

## Overview

SAP Edge Lifecycle Management (ELM) is the tool used to deploy and manage SAP Edge Integration Cell on Kubernetes clusters. This article documents the ELM connector configuration parameters, recommended values for POC vs production scenarios, and guidance for AKS-specific choices.

ELM is invoked via the `elm.exe` CLI or through the SAP BTP Cockpit UI. The parameters below appear during the interactive deployment wizard.

---

## Kubernetes Provider Selection

| Option | When to use |
|--------|-------------|
| **Azure Kubernetes Service (AKS)** | Always select for AKS clusters provisioned by this accelerator |
| Generic | Only if running on a non-listed distro |

---

## Storage Class Selection for Monitoring

ELM prompts for a storage class and an approach to validate it.

### Validation Approach

| Option | Recommendation |
|--------|---------------|
| **1. Check the selected storage class for usability after selection** | ✅ Recommended for POC — fastest, minimal delay |
| 2. Check storage classes before selection | Use in production if you need to confirm compatibility upfront |
| 3. Do not check the selected storage class for usability | Not recommended |

### Storage Class Choice (AKS)

| Storage Class | Type | POC | Production | Notes |
|---------------|------|-----|------------|-------|
| **default** | Azure Managed Disk (Standard) | ✅ Recommended | ❌ | Simplest, no extra config needed |
| managed-csi | Azure Managed Disk (CSI, Standard LRS) | ✅ | ✅ | Modern CSI driver, good default for production |
| managed-csi-premium | Azure Managed Disk (CSI, Premium LRS) | ❌ | ✅ Recommended | Low-latency SSD, best for production monitoring |
| azurefile-csi | Azure Files (CSI, Standard) | ❌ | ❌ | RWX capable but higher latency, rarely needed for monitoring |
| azurefile-csi-premium | Azure Files (CSI, Premium) | ❌ | ⚠️ | Only if RWX access mode is required |

**POC guidance**: Select `default` — zero configuration, works immediately.

**Production guidance**: Select `managed-csi-premium` for monitoring persistence with low-latency SSD-backed volumes.

---

## Registry Configuration

### Source Registry (SAP Container Images)

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| Container Registry Address | SAP Docker registry CDN | `73555000100900004766.dockersrv.cdn.repositories.cloud.sap` |
| Notary Address | Image signing verification | `https://signing.repositories.cloud.sap` |
| Username | SAP repository user (S-user or technical user) | `0000037255-<user>` |
| Password | SAP repository password | *(from SAP credentials)* |

### Target Registry

| Option | When to use |
|--------|-------------|
| **Generic** | ✅ Default — use the same SAP registry as target (POC) |
| Wellknown | When mirroring to a private ACR or other registry (production) |

For POC, set the Target Registry Address to the same SAP CDN registry. For production, mirror images to a private Azure Container Registry (ACR) for air-gapped or controlled deployments.

---

## Cloud User & Service Key

| Parameter | Description | Where to find |
|-----------|-------------|---------------|
| Cloud User Secret Name | K8s secret storing cloud credentials | Default: `cloud-user-secret` |
| Cloud User Email | SAP BTP user email | Your SAP BTP user |
| ELM Service Key Secret Name | K8s secret for ELM service binding | Default: `elmo-service-key-secret` |
| Client ID | OAuth client ID from ELM service key | SAP BTP Cockpit → Service Instances → ELM → Service Key |
| Client Secret | OAuth client secret | Same location |
| Tenant URL | OAuth token endpoint | `https://<subdomain>.authentication.<region>.hana.ondemand.com` |

---

## ELM Connector Settings

| Parameter | Description | Example |
|-----------|-------------|---------|
| Link to ELM | ELM service endpoint | `edge-lifecycle-manager-prod.cfapps.<region>.hana.ondemand.com` |
| Region Hostname | Cloud Foundry region | `cf.<region>.hana.ondemand.com` |
| Subaccount ID | SAP BTP subaccount GUID | *(from BTP Cockpit)* |
| Display Name | Friendly name for the connector | e.g. `azure-poc`, `azure-production` |
| Edge Node ID | Unique ID assigned to the edge node | *(generated during node registration)* |
| Location ID | Logical location identifier | *(auto-generated or user-defined)* |

---

## Network / Proxy Configuration

| Parameter | POC | Production |
|-----------|-----|------------|
| HTTPS Proxy | Leave empty | Set if cluster egress goes through a corporate proxy |
| NO_PROXY List | Leave empty | Add internal CIDRs, `.svc`, `.cluster.local`, metadata endpoints |

---

## Custom Labels & Annotations

| Parameter | POC | Production |
|-----------|-----|------------|
| Custom Labels for ELM namespace | Leave empty | Add for governance (cost center, team, environment tags) |
| Custom Annotations for ELM namespace | Leave empty | Add for policy engines (Azure Policy, OPA/Gatekeeper) |

---

## Quick Decision Matrix (POC vs Production)

| Decision | POC (simplest) | Production |
|----------|----------------|------------|
| Kubernetes Provider | AKS | AKS |
| Storage class validation | Option 1 (check after) | Option 2 (check before) |
| Storage class | `default` | `managed-csi-premium` |
| Target Registry | Same as source (SAP CDN) | Private ACR |
| Proxy settings | Empty | Configure per network policy |
| Labels/Annotations | Empty | Add governance metadata |

---

## Related Resources

| Resource | URL |
|----------|-----|
| SAP Help: Setting Up Edge Integration Cell | https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell |
| SAP Help: Prepare AKS for EIC | https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-for-deployment-on-azure-kubernetes-service-aks |
| SAP Help: Deploy Edge Integration Cell | https://help.sap.com/docs/integration-suite/sap-integration-suite/deploy-edge-integration-cell |
| SAP Help: Edge Lifecycle Management | https://help.sap.com/docs/integration-suite/sap-integration-suite/edge-lifecycle-management |
| SAP Note 3247839 (Prerequisites) | https://me.sap.com/notes/3247839 |
| Microsoft Learn: SAP EIC with Azure | https://learn.microsoft.com/azure/sap/workloads/sap-edge-integration-cell-with-azure |
| AKS Storage Classes | https://learn.microsoft.com/azure/aks/concepts-storage#storage-classes |
