# Edge Integration Cell on Azure Kubernetes Service (AKS) - production-ready

This page helps you quickly find the right production-ready guidance for SAP Edge Integration Cell (EIC) on AKS.

## Find Information by Goal

Use this section to jump directly to what you need.

| Your goal | Go to |
|---|---|
| Provision a working AKS environment quickly | [Quickstart AKS deployment](../../quickstart/aks/README.md) |
| Understand production architecture expectations | [Production Architecture Direction](#production-architecture-direction) |
| Apply Azure Well-Architected AKS patterns | [AKS baseline references](#aks-baseline-references) |
| Add production PostgreSQL and Redis after the AKS baseline | [Azure PaaS production delta](../azure-paas/README.md) |
| Check SAP EIC prerequisites and sizing | [Knowledge Base: Prerequisites](../../knowledge-base/prerequisites.md) |
| Plan operations, monitoring, and troubleshooting | [Knowledge Base: Runbooks](../../knowledge-base/README.md#runbooks--troubleshooting-runbooks) |
| Continue with SAP-side setup after AKS | [SAP documentation and ELM handover](#sap-documentation-and-elm-handover) |

## Current Status

- Maturity: production-ready AKS assets are a scaffold and not a complete turnkey deployment yet.
- Scope of this page: provide architecture direction, references, and topic routing.
- If you need immediate execution: start from [quickstart/aks](../../quickstart/aks/README.md) and then harden toward baseline patterns.

## Production Architecture Direction

The production-ready path for this repository is aligned with Azure Well-Architected principles and the AKS baseline architecture.

Design expectations for production scenarios:

- Network segmentation and explicit ingress/egress strategy
- Identity-first access model and least-privilege RBAC
- Security controls for cluster, workload, and secrets
- Operational readiness for upgrades, incident response, and recovery
- Clear separation of concerns between Azure platform setup and SAP EIC runtime onboarding

## AKS Baseline References

Use the baseline references below as the primary source for enterprise AKS architecture patterns.

- [AKS Baseline implementation repository](https://github.com/mspnp/aks-baseline)
- [AKS Baseline reference architecture (Microsoft Learn)](https://aka.ms/architecture/aks-baseline)

These references are the foundation for production-grade networking, security, and operations.

## Recommended Reading Order

If you are designing a production rollout, this sequence is recommended:

1. [Knowledge Base: Architecture Overview](../../knowledge-base/architecture.md)
2. [Knowledge Base: Prerequisites and sizing](../../knowledge-base/prerequisites.md)
3. [AKS baseline references](#aks-baseline-references)
4. [Azure PaaS production delta (PostgreSQL and Redis)](../azure-paas/README.md)
5. [Quickstart AKS sample for practical deployment flow](../../quickstart/aks/README.md)
6. [Knowledge Base: Operations and Day-2 runbook](../../knowledge-base/runbooks/operations.md)
7. [Knowledge Base: Troubleshooting runbook](../../knowledge-base/runbooks/troubleshooting.md)

## Topic Map

Use this map when you need focused guidance for specific workstreams.

| Topic | Primary reference |
|---|---|
| Core architecture and component model | [knowledge-base/architecture.md](../../knowledge-base/architecture.md) |
| Sizing, versions, and environment prechecks | [knowledge-base/prerequisites.md](../../knowledge-base/prerequisites.md) |
| ELM setup considerations | [knowledge-base/elm-configuration.md](../../knowledge-base/elm-configuration.md) |
| Day-2 operations and maintenance | [knowledge-base/runbooks/operations.md](../../knowledge-base/runbooks/operations.md) |
| Incident triage and diagnostics | [knowledge-base/runbooks/troubleshooting.md](../../knowledge-base/runbooks/troubleshooting.md) |
| Known failure pattern example | [knowledge-base/runbooks/commerce-memory-leak.md](../../knowledge-base/runbooks/commerce-memory-leak.md) |

## SAP Documentation and ELM Handover

This accelerator focuses on Azure infrastructure and operational enablement. For SAP-specific runtime installation and lifecycle steps, continue with SAP documentation:

- [Set up and manage SAP Edge Integration Cell](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell)
- [Prepare deployment on AKS](https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-for-deployment-on-azure-kubernetes-service-aks)
- [SAP EIC reference architecture](https://architecture.learning.sap.com/docs/ref-arch/263f576c90/2)

## Working Guidance for Contributors

When extending production-ready AKS content in this repository:

- Prefer linking to AKS baseline resources rather than duplicating baseline implementation content.
- Keep this page as a navigation hub and place deep operational content in the knowledge base.
- Update links in this page whenever new production-ready AKS assets are added.
