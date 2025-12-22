output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "mysql_server_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.mongo.name
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.eh_ns.name
}

# output "backend_namespace" {
#   value = kubernetes_namespace.backend.metadata[0].name
# }

# output "frontend_namespace" {
#   value = kubernetes_namespace.frontend.metadata[0].name
# }

# output "monitoring_namespace" {
#   value = kubernetes_namespace.monitoring.metadata[0].name
# }
