resource "azurerm_postgresql_flexible_server" "this" {
  name                   = "${var.name_prefix}-pg2"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  sku_name               = var.sku_name
  storage_mb             = var.storage_mb
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  public_network_access_enabled = false
  backup_retention_days         = 7

  lifecycle {
    ignore_changes = [zone]
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "langfuse" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
