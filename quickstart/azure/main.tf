resource "azurerm_resource_group" "k8s" {
  name     = "rg-${var.resource_group_name}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "quickstart" {
  name                = "k8s-${var.resource_group_name}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = "k8s-${var.resource_group_name}"
  kubernetes_version  = "1.27.9" 

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  sku_tier = "Free"
  
  identity {
    type = "SystemAssigned"
  }
}