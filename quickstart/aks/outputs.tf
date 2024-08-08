output "id" {
  value = azurerm_kubernetes_cluster.quickstart.id
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.quickstart.kube_config_raw
  sensitive = true
}

output "client_key" {
  value = azurerm_kubernetes_cluster.quickstart.kube_config.0.client_key
  sensitive = true
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.quickstart.kube_config.0.client_certificate
  sensitive = true
}

output "host" {
  value = azurerm_kubernetes_cluster.quickstart.kube_config.0.host
  sensitive = true
}