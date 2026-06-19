# SAP Edge Integration Cell on Azure — Knowledge Base

> **Purpose**: This directory is a curated, agent-friendly knowledge source for [Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/) and human operators managing SAP Edge Integration Cell (EIC) on Azure. Add this repository as a **web page** source in Azure SRE Agent to enable AI-assisted diagnostics and operations for your SAP EIC workloads.

---

## How to use with Azure SRE Agent

1. Open your [Azure SRE Agent configuration](https://sre.azure.com/).
2. Select **Add knowledge source → Web page**.
3. Add the URL of this index page:
   `https://github.com/Azure/sap-edge-integration-cell-on-azure-accelerator/blob/main/knowledge-base/README.md`
4. Optionally add individual article URLs from the index below for more focused knowledge scoping.

---

## Article Index

### Knowledge Articles

| Article | Description | Audience |
|---------|-------------|----------|
| [Architecture Overview](architecture.md) | SAP EIC components, Azure resource topology, networking model, and data flow | SRE, Platform Engineering |
| [Prerequisites & Sizing](prerequisites.md) | Supported AKS versions, VM SKUs, SAP notes, resource requirements, and pre-deployment checklist | SRE, DevOps |

### Runbooks & Troubleshooting (`runbooks/`)

| Runbook | Description | Audience |
|---------|-------------|----------|
| [Troubleshooting Guide](runbooks/troubleshooting.md) | Common failure modes, diagnostic commands, and resolution steps | SRE, Support |
| [Operations & Day-2](runbooks/operations.md) | Monitoring, scaling, certificate rotation, upgrades, and disaster recovery | SRE, Platform Engineering |
| [Commerce Memory Leak](runbooks/commerce-memory-leak.md) | OOMKilled restart loop caused by unbounded search cache — diagnosis, remediation, and verification | SRE, Support |

---

## Conventions for Knowledge Articles

All articles in this directory follow an **agent-friendly format** optimized for LLM consumption:

- **Self-contained pages** — each article is independently understandable without reading others.
- **Structured headings** — H2 for major topics, H3 for sub-procedures, enabling precise section retrieval.
- **Diagnostic tables** — symptoms, causes, and actions in machine-parseable table format.
- **Explicit severity/impact** — issues tagged with severity (Critical / High / Medium / Low) for triage prioritization.
- **Command blocks with context** — every CLI snippet includes a comment explaining when and why to run it.
- **Links to authoritative sources** — SAP notes, Microsoft Learn docs, and upstream references for validation.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add or update articles.

---

## Quick Reference Links

| Resource | URL |
|----------|-----|
| SAP EIC Documentation | https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell |
| SAP EIC Prerequisites (SAP Note 3247839) | https://me.sap.com/notes/3247839 |
| AKS Preparation Guide | https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-for-deployment-on-azure-kubernetes-service-aks |
| AKS Baseline Reference Architecture | https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks |
| Microsoft Learn: SAP EIC with Azure | https://learn.microsoft.com/azure/sap/workloads/sap-edge-integration-cell-with-azure |
| This Accelerator (IaC) | https://github.com/Azure/sap-edge-integration-cell-on-azure-accelerator |
