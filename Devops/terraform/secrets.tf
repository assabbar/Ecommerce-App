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
