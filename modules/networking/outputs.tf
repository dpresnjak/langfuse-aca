output "virtual_network_id" {
  value       = data.azurerm_virtual_network.this.id
  description = "Virtual network resource ID."
}

output "private_endpoints_subnet_id" {
  value       = local.private_endpoint_subnet_id
  description = "Subnet ID used for private endpoints (Redis, ACR, etc.)."
}

output "container_apps_subnet_id" {
  value       = local.container_apps_subnet_id
  description = "Subnet ID used by the Container Apps Environment."
}

output "postgres_subnet_id" {
  value       = local.postgres_subnet_id
  description = "Delegated subnet ID used by PostgreSQL Flexible Server."
}

output "postgres_private_dns_zone_id" {
  value       = azurerm_private_dns_zone.postgres.id
  description = "Private DNS zone ID for PostgreSQL Flexible Server."
}

output "redis_private_endpoint_id" {
  value       = azurerm_private_endpoint.redis.id
  description = "Private endpoint ID for Azure Cache for Redis."
}

output "clickhouse_network_interface_id" {
  value       = azurerm_network_interface.clickhouse.id
  description = "NIC ID for the ClickHouse VM."
}

output "clickhouse_private_ip" {
  value       = azurerm_network_interface.clickhouse.private_ip_address
  description = "Private IP assigned to the ClickHouse VM NIC."
}

output "application_gateway_subnet_id" {
  value       = local.application_gateway_subnet_id
  description = "Optional subnet ID for an Application Gateway if provided."
}

output "container_apps_nat_gateway_public_ip" {
  value = (
    length(azurerm_public_ip.container_apps_nat) > 0
    ? azurerm_public_ip.container_apps_nat[0].ip_address
    : null
  )
  description = "Outbound public IPv4 for Container Apps subnet traffic when NAT gateway is enabled."
}
