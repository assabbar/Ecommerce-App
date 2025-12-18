resource "azurerm_cosmosdb_account" "mongo" {
  name                = var.cosmosdb_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  offer_type          = "Standard"
  kind                = "MongoDB"
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "db" {
  name                = "ecom-mongo-db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.mongo.name
}

resource "azurerm_cosmosdb_mongo_collection" "coll" {
  name                = "products"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.mongo.name
  database_name       = azurerm_cosmosdb_mongo_database.db.name
  throughput          = 400
  shard_key           = "_id"
  
  index {
    keys   = ["_id"]
    unique = true
  }
}
