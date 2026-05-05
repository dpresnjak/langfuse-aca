output "id" {
  value       = module.environment.id
  description = "Container Apps Environment resource ID."
}

output "name" {
  value       = module.environment.name
  description = "Container Apps Environment name."
}

output "default_domain" {
  value       = module.environment.default_domain
  description = "Default domain for apps in the Container Apps Environment."
}

output "environment_static_ip_address" {
  value       = module.environment.static_ip_address
  description = "Internal static IP (ILB) of the Container Apps environment; use as a private backend target (e.g. Application Gateway)."
}

output "infrastructure_resource_group" {
  value       = module.environment.infrastructure_resource_group
  description = "Azure-managed infrastructure resource group used by the Container Apps Environment."
}

output "langfuse_web_host" {
  value       = local.web_host
  description = "Internal FQDN for Langfuse web."
}

output "langfuse_web_url" {
  value       = "https://${local.web_host}"
  description = "Private Langfuse web URL."
}

output "minio_url" {
  value       = local.minio_external_url
  description = "Private MinIO API URL."
}

output "langfuse_web_app_id" {
  value       = azurerm_container_app.langfuse_web.id
  description = "Langfuse web Container App resource ID."
}

output "langfuse_worker_app_id" {
  value       = azurerm_container_app.langfuse_worker.id
  description = "Langfuse worker Container App resource ID."
}

output "minio_app_id" {
  value       = azurerm_container_app.minio.id
  description = "MinIO Container App resource ID."
}

output "otel_collector_app_id" {
  value       = try(azurerm_container_app.otel_collector[0].id, null)
  description = "OpenTelemetry Collector Container App resource ID (null if disabled)."
}

output "otel_collector_host" {
  value       = var.enable_otel_collector ? "otel-collector.${module.environment.default_domain}" : null
  description = "Internal hostname for OTLP when the OpenTelemetry Collector app is enabled."
}

output "otel_collector_otlp_https_base" {
  value       = var.enable_otel_collector ? "https://otel-collector.${module.environment.default_domain}" : null
  description = "Base URL for OTLP over HTTP/protobuf (TLS on 443 via Container Apps ingress)."
}
