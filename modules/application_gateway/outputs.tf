output "public_ip_address" {
  value       = azurerm_public_ip.this.ip_address
  description = "Public IPv4 address of the Application Gateway."
}

output "langfuse_public_http_url" {
  value       = "http://${azurerm_public_ip.this.ip_address}/"
  description = "Public HTTP URL to Langfuse through the Application Gateway (set nextauth_url to match)."
}

output "clickhouse_public_http_url" {
  value       = var.expose_clickhouse ? "http://${azurerm_public_ip.this.ip_address}:8123/" : null
  description = "Public HTTP URL to ClickHouse HTTP interface, if exposed."
}

output "id" {
  value       = azurerm_application_gateway.this.id
  description = "Application Gateway resource ID."
}
