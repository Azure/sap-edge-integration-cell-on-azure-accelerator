resource "azurerm_resource_group" "k8s" {
  name     = "rg-${var.resource_group_name}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "quickstart" {
  name                = "k8s-${var.resource_group_name}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  kubernetes_version  = "1.28.10" 

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D4ds_V5"
  }

  network_profile {
    network_plugin = "kubenet"
    load_balancer_sku = "standard"
  }

  sku_tier = "Free"
  identity {
    type = "SystemAssigned"
  }
}