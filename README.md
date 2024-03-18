# SAP Edge Integration Cell on Azure Accelerator

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=773743527)

This repos serves as an accelerator for SAP Edge Integration Cell (EIC) on Azure Kubernetes Service (AKS). It provides a set of terraform scripts and templates to automate the deployment of the required infrastructure and software components.

Scenarios range from hybrid setups like connecting a local ERP to SAP Sales Cloud, to complete on-premises scenarios like SAP PI/PO to ECC communication within a factory. EIC requires outbound internet connectivity for heartbeats and updates though.

> [!NOTE]
> Learn more about running EIC on validated hardware at the "edge" in your factory, plant, shop floor etc. with Azure Stack HCI [here](https://learn.microsoft.com/azure-stack/hci/).
> AKS gets deployed to HCI via [Azure Arc](https://learn.microsoft.com/azure/aks/hybrid/resource-manager-quickstart). Adjust the terraform scripts to use the [azurerm_arc_kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster) provider accordingly.

## Getting Started

- [Overview and Installation Guide](https://blogs.sap.com/2023/11/16/next-gen-hybrid-integration-with-sap-integration-suite-edge-integration-cell-introduction-setup/)

### Folder structure

|Folder|Description|
|---|---|
|quickstart|Provides a non production quickstart sample|
|production-ready|Provides a production ready (e.g. HA-Cluster) setup|

### Prerequisites

- [Please see SAP Documentation for latest updates](https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-your-kubernetes-cluster)
- [Prepare for your deployment on AKS](https://help.sap.com/docs/integration-suite/sap-integration-suite/prepare-for-deployment-on-azure-kubernetes-service-aks)

> [!NOTE]
> Always verify latest stable AKS version supported by SAP.

#### Setup

You need to set the following Environment Variables:

|Name|Description|
|---|---|
|BTP_USERNAME|The Username to access SAP BTP|
|BTP_PASSWORD|The Password to access SAP BTP|

## Further Reading

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
