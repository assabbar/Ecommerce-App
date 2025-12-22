##########################################################################
# Kubernetes Secrets pour credentials
##########################################################################

resource "kubernetes_secret" "mysql_credentials" {
  provider = kubernetes.aks

  metadata {
    name      = "mysql-credentials"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  type = "Opaque"

  data = {
    "mysql-password" = var.mysql_password
    "mysql-user"     = "root"
    "mysql-host"     = azurerm_mysql_flexible_server.mysql.fqdn
  }

  depends_on = [kubernetes_namespace.backend]
}
resource "kubernetes_secret" "cosmosdb_credentials" {
  provider = kubernetes.aks

  metadata {
    name      = "cosmosdb-credentials"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  type = "Opaque"

  data = {
    "uri" = "mongodb://${azurerm_cosmosdb_account.mongo.name}:${azurerm_cosmosdb_account.mongo.primary_readonly_key}@${azurerm_cosmosdb_account.mongo.name}.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retryWrites=false&maxIdleTimeMS=120000&appName=@${azurerm_cosmosdb_account.mongo.name}@"
  }

  depends_on = [kubernetes_namespace.backend, azurerm_cosmosdb_account.mongo]
}