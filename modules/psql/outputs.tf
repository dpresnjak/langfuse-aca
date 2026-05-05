output "fqdn" {
  value       = azurerm_postgresql_flexible_server.this.fqdn
  description = "Private FQDN of the PostgreSQL Flexible Server."
}

output "database_name" {
  value       = azurerm_postgresql_flexible_server_database.langfuse.name
  description = "Created database name."
}

output "server_id" {
  value       = azurerm_postgresql_flexible_server.this.id
  description = "PostgreSQL Flexible Server resource ID."
}
