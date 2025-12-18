resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-ecom"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = "adminuser"
  administrator_password = var.mysql_password

  sku_name   = "B_Standard_B2s"
  version    = "8.0.21"
  backup_retention_days = 7
}

resource "azurerm_mysql_flexible_database" "appdb" {
  name                = "ecomdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
