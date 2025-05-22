resource "azurerm_resource_group" "k8s" {
  name     = "rg-${var.resource_group_name}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "quickstart" {
  name                = "k8s-${var.resource_group_name}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = "k8s-${var.resource_group_name}"
  kubernetes_version  = "1.30.4" 

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D8ds_V5"
    node_count = var.node_count
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