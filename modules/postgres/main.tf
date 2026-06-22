resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "nutriai-postgres-db-${var.environment}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "postgres-dns-link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = "nutriai-postgres-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "15"
  delegated_subnet_id           = var.database_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres_dns.id
  administrator_login           = var.admin_user
  administrator_password        = var.admin_password
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  backup_retention_days         = var.backup_retention_days
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_link]

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "nutriai"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
