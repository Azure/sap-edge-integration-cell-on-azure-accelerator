# SAP Edge Integration Cell on Azure Accelerator

Infrastructure-as-code that automates deployment of the infrastructure required to run [SAP Edge Integration Cell](https://help.sap.com/docs/integration-suite/sap-integration-suite/setting-up-and-managing-edge-integration-cell) (EIC) on Azure Kubernetes Service (AKS), plus SAP BTP entitlement setup. There is no application code here — only IaC templates and Markdown docs.

## Repository layout

The repo is split into two maturity tiers, each containing parallel target environments:

- `quickstart/` — non-production samples meant to provision quickly. **Keep these as light as possible**: the goal is the shortest path for a customer to see a working SAP Edge Integration Cell. Resist adding networking, hardening, or extra services here — that belongs in `production-ready/`.
  - `aks/` — minimal AKS cluster (the primary working sample, Terraform).
  - `sap/` — SAP BTP entitlement for the `edge_integration_cell` plan via the `SAP/btp` Terraform provider.
  - `azure-local/` — docs only (`🚧UNDER CONSTRUCTION🚧`).
- `production-ready/` — well-architected blueprints (`aks/`, `sap/`, `azure-local/`). Most are stubs marked `🚧UNDER CONSTRUCTION🚧`; the existing `production-ready/aks/*.tf` is in-development scaffolding and **not yet internally consistent** (e.g. `main.tf` references resources such as `azurerm_resource_group.rg`, `random_pet.*`, `azurerm_virtual_network.default` that aren't all defined).

### Production-ready relies on the AKS baseline — link, don't copy

The production-ready direction is to build on the **Azure Well-Architected Framework**. All WAF/AKS-baseline scripting lives in the upstream baseline repositories and **must only be linked from here, never copied**, to avoid redundancy and to always benefit from their ongoing updates:

- [AKS baseline reference architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks/baseline-aks)
- [mspnp/aks-baseline](https://github.com/mspnp/aks-baseline)

This repo's production-ready content should layer the EIC-specific pieces on top of (and reference) that baseline rather than reimplementing cluster hardening, networking, or governance.

### IaC is multi-language

Terraform is the current implementation but **not the only IaC** going forward — production-ready blueprints will introduce Bicep (WAF-aligned). When adding to `production-ready/`, prefer Bicep for new WAF blueprint work; keep Terraform and Bicep assets clearly separated by directory so each environment stays a self-contained, independently deployable unit.

Each Terraform sample is a **self-contained root module** with its own `provider.tf`, `variables.tf`, `main.tf` (and optionally `outputs.tf`, plus feature files like `postgresql-fs-db.tf`, `ssh.tf`). Deploy from inside the specific sample directory, not the repo root. The root `versions.tf` is not part of any deployable module.

## Working with Terraform here

Always `cd` into the target sample directory first (e.g. `quickstart/aks`), then:

```bash
terraform init
terraform plan
terraform apply
```

- Variables are supplied via a `terraform.tfvars` file the user creates locally (not committed). See each sample's `README.md` for expected variable names (e.g. `resource_group_name`, `location`).
- There is **no remote backend and no CI that runs Terraform** — `apply` happens manually from a workstation, Azure Cloud Shell, or the devcontainer. Authentication is via Azure CLI (`az account set --subscription <id>`). Docs reference `ARM_SKIP_PROVIDER_REGISTRATION=true` to skip provider registration.
- `quickstart/sap` targets SAP BTP (not Azure) and requires `globalaccount` / `subaccount_id`; it assumes SAP CPI is already available in the subaccount.

## Conventions

These are written for long-term, multi-contributor and agentic maintenance — favor changes that keep samples self-describing and reduce per-release manual edits.

- **Move away from hardcoded versions toward configurable inputs.** Current samples pin values inline that should become variables with sensible defaults — notably `kubernetes_version` and VM sizes in `quickstart/aks/main.tf`. Prefer exposing these as `variables.tf` inputs (documented in the README) over editing `main.tf` per deployment. SAP only supports specific AKS versions, so make the version configurable and document the "verify latest SAP-supported stable AKS version" check rather than freezing a value.
- **Provider pins are currently inconsistent and should be converging upward.** Root `versions.tf` and several docs target `azurerm ~> 4.x`, but sample `provider.tf` files still pin `azurerm ~> 3.0`. When touching a sample, align it toward the `4.x` baseline where feasible; if you must keep an older pin, leave a note why. Don't silently introduce a third divergent pin.
- Resource naming uses interpolation prefixes (e.g. `"k8s-${var.resource_group_name}"`, `"rg-${var.resource_group_name}"`, `random_pet`-based names in production-ready). Keep new resources consistent with the surrounding file's scheme.
- Docs are a primary deliverable: each sample's `README.md` documents variables and step-by-step usage. When you add or rename a variable, update that sample's README in the same change. The manual EIC install still relies on SAP's video/guide because not all steps are automated yet.

## Documentation links

Markdown link health is enforced by `.github/workflows/links-watcher.yml` (lychee, daily + `workflow_dispatch`). Broken links fail the job and auto-file/update a GitHub issue. Keep added Markdown links valid; `portal.azure.com`, `developers.sap.com`, and `shell.azure.com` are excluded from checking.

## Knowledge Base (`knowledge-base/`)

The `knowledge-base/` directory is a curated, **agent-friendly knowledge source** designed for consumption by [Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/) via the "web page" source type, and by human operators. Community members and agents extend SAP EIC-specific operational knowledge here.

### Conventions for knowledge-base content

- **Each article is self-contained** — independently understandable without reading the full repo.
- **Structured headings** — H2 for major topics, H3 for sub-procedures. Agents use heading hierarchy for section retrieval.
- **Tables for structured data** — symptoms/causes/resolutions, parameters/descriptions, metrics/thresholds.
- **Severity tags** on troubleshooting entries (`Critical`, `High`, `Medium`, `Low`).
- **Command blocks include context comments** explaining when and why to run.
- **Links to authoritative sources** (SAP notes, Microsoft Learn) in a `## Related Resources` footer.
- **No inline images** — agents consume text; describe visuals in prose or tables.
- New articles must be added to the **Article Index** table in `knowledge-base/README.md`.
- See `knowledge-base/CONTRIBUTING.md` for the full article template and contribution workflow.

### What goes where

| Content | Location |
|---------|----------|
| Terraform variable docs, step-by-step deployment | Sample `README.md` (e.g., `quickstart/aks/README.md`) |
| Architecture, operations, troubleshooting, runbooks | `knowledge-base/` |
| IaC templates | `quickstart/` or `production-ready/` |

The knowledge base **references** sample READMEs and IaC files via relative links but does not duplicate their content.

## Devcontainer

`.devcontainer/devcontainer.json` provides Ubuntu + Azure CLI + Terraform (latest) and the HashiCorp Terraform / GitHub Actions / Azure CLI VS Code extensions. Use it (or Codespaces) for a ready-to-run environment. When Bicep blueprints land, the Azure CLI already present covers `az bicep`/`az deployment`.
