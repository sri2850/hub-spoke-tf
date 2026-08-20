# Private DNS Zone for Postgres
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.spoke.name
}

# Link Private DNS Zone to the Spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "vnet-link-postgres-spoke"
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = module.spoke_network.vnet_id
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "this" {
  name                   = "psql-${var.environment}-app-sec01" # Must be globally unique
  resource_group_name    = azurerm_resource_group.spoke.name
  location               = azurerm_resource_group.spoke.location
  version                = "16"
  delegated_subnet_id    = module.spoke_network.subnet_ids["db-subnet"]
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = "psqladmin"
  administrator_password = random_password.db_admin_password.result
  zone                   = "1"

  storage_mb   = 32768
  sku_name     = "B_Standard_B1ms"
  auto_grow_enabled = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}