# Edge Integration Cell quickstart on Azure Local (formerly Azure Stack HCI)

🚧UNDER CONSTRUCTION🚧

Run SAP Edge Integration Cell (EIC) on validated hardware at the "edge" in your factory, plant, shop floor etc. with [Azure Local (formerly Azure Stack HCI)](https://learn.microsoft.com/azure/azure-local/).

AKS gets deployed to Azure Local via [Azure Arc](https://learn.microsoft.com/azure/aks/hybrid/resource-manager-quickstart). Terraform scripts use the [azurerm_arc_kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster) provider which is different from plain AKS.
