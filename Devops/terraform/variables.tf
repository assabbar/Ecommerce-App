variable "location" {
  type    = string
  default = "France Central"
}

variable "mysql_password" {
  type      = string
  sensitive = true
}

variable "eventhub_namespace_sku" {
  type    = string
  default = "Standard"
}

variable "cosmosdb_account_name" {
  type    = string
  default = "cosmosecomdb"
}
