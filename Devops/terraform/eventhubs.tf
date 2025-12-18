resource "azurerm_eventhub_namespace" "eh_ns" {
  name                = "eh-ecom"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "hub" {
  name                = "ecom-events"
  namespace_name      = azurerm_eventhub_namespace.eh_ns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
