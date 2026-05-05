output "langfuse_web_url" {
  value       = module.container_app.langfuse_web_url
  description = "Private Langfuse web URL."
}

output "langfuse_web_host" {
  value       = module.container_app.langfuse_web_host
  description = "Internal hostname for Langfuse web."
}

output "appgw_contract_backend_host" {
  value       = module.container_app.langfuse_web_host
  description = "Central App Gateway backend host (FQDN) for Langfuse. Use as backend pool target and Host/SNI override."
}

output "appgw_contract_backend_protocol" {
  value       = "Https"
  description = "Central App Gateway backend protocol for Langfuse."
}

output "appgw_contract_backend_port" {
  value       = 443
  description = "Central App Gateway backend port for Langfuse."
}

output "appgw_contract_backend_host_name_override" {
  value       = module.container_app.langfuse_web_host
  description = "Central App Gateway backend HTTP settings host_name override (must match Langfuse internal FQDN for routing + TLS SNI)."
}

output "appgw_contract_probe_protocol" {
  value       = "Https"
  description = "Central App Gateway health probe protocol for Langfuse."
}

output "appgw_contract_probe_path" {
  value       = "/api/public/health"
  description = "Central App Gateway health probe path for Langfuse."
}

output "appgw_contract_probe_expected_status_codes" {
  value       = ["200"]
  description = "Central App Gateway health probe should treat only these status codes as healthy."
}

output "minio_url" {
  value       = module.container_app.minio_url
  description = "Private MinIO API URL."
}

output "otel_collector_host" {
  value       = module.container_app.otel_collector_host
  description = "Internal OTLP collector hostname in the Container Apps environment (null if disabled)."
}

output "otel_collector_otlp_https_base" {
  value       = module.container_app.otel_collector_otlp_https_base
  description = "OTLP HTTP/protobuf base URL for the in-environment collector (null if disabled)."
}

output "postgres_fqdn" {
  value       = module.psql.fqdn
  description = "PostgreSQL Flexible Server private FQDN."
}

output "redis_hostname" {
  value       = module.redis.hostname
  description = "Azure Cache for Redis hostname."
}

output "clickhouse_private_ip" {
  value       = module.networking.clickhouse_private_ip
  description = "ClickHouse VM private IP."
}

output "container_apps_environment_id" {
  value       = module.container_app.id
  description = "Container Apps Environment resource ID."
}

output "container_apps_infrastructure_resource_group" {
  value       = module.container_app.infrastructure_resource_group
  description = "Azure-managed infrastructure resource group used by the Container Apps Environment."
}

output "clickhouse_ssh_private_key_pem" {
  value       = module.clickhouse.ssh_private_key_pem
  description = "Generated ClickHouse VM private key. Store securely."
  sensitive   = true
}

output "container_apps_environment_static_ip" {
  value       = module.container_app.environment_static_ip_address
  description = "Internal ILB IP for the Container Apps environment (backend target for reverse proxies)."
}

output "appgw_contract_private_dns_zone_name" {
  value       = module.container_app.default_domain
  description = "Private DNS zone name that must exist/be resolvable from the central AppGW VNet: this is the Container Apps environment defaultDomain."
}

output "appgw_contract_private_dns_a_records" {
  value = {
    "@" = module.container_app.environment_static_ip_address
    "*" = module.container_app.environment_static_ip_address
  }
  description = "A records required in the private DNS zone so <app>.<defaultDomain> resolves to the Container Apps ILB IP."
}

output "container_apps_nat_gateway_public_ip" {
  value       = module.networking.container_apps_nat_gateway_public_ip
  description = "Outbound SNAT IP for the Container Apps subnet when NAT is enabled (allow-list on third-party APIs if needed)."
}