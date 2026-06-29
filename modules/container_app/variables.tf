variable "name_prefix" {
  type        = string
  description = "Prefix used for the Container Apps Environment name."
}

variable "location" {
  type        = string
  description = "Azure region for the Container Apps Environment."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group where the Container Apps Environment is created."
}

variable "infrastructure_subnet_id" {
  type        = string
  description = "Subnet ID used by the Container Apps Environment control plane."
}

variable "virtual_network_id" {
  type        = string
  description = "VNet ID for linking private DNS so internal FQDNs (e.g. for Application Gateway) resolve to the Container Apps ILB."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID."
}

variable "infrastructure_resource_group_name" {
  type        = string
  description = "Optional platform-managed infrastructure resource group name. Leave null to let Azure generate it."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Container Apps Environment resources."
  default     = {}
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for the MinIO Azure Files mount."
}

variable "storage_share_name" {
  type        = string
  description = "Storage share name for the MinIO Azure Files mount."
}

variable "storage_access_key" {
  type        = string
  description = "Storage account access key for the MinIO Azure Files mount."
  sensitive   = true
}

variable "database_url" {
  type        = string
  description = "PostgreSQL connection string for Langfuse."
  sensitive   = true
}

variable "use_postgres_container_app" {
  type        = bool
  description = "Deploy PostgreSQL as a Container App in this environment (POC)."
  default     = false
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username when use_postgres_container_app is true."
  default     = "postgres"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password when use_postgres_container_app is true."
  sensitive   = true
  default     = null
}

variable "postgres_db_name" {
  type        = string
  description = "PostgreSQL database name when use_postgres_container_app is true."
  default     = "postgres"
}

variable "postgres_image_tag" {
  type        = string
  description = "PostgreSQL image tag on docker.io."
  default     = "16-alpine"
}

variable "salt" {
  type        = string
  description = "Langfuse SALT secret."
  sensitive   = true
}

variable "encryption_key" {
  type        = string
  description = "Langfuse encryption key."
  sensitive   = true
}

variable "nextauth_secret" {
  type        = string
  description = "NextAuth secret for Langfuse web."
  sensitive   = true
}

variable "use_clickhouse_container_app" {
  type        = bool
  description = "Deploy ClickHouse as a Container App in this environment (POC)."
  default     = false
}

variable "clickhouse_password" {
  type        = string
  description = "ClickHouse password."
  sensitive   = true
}

variable "clickhouse_image_tag" {
  type        = string
  description = "ClickHouse server image tag on docker.io."
  default     = "24.12"
}

variable "redis_password" {
  type        = string
  description = "Redis password for the in-environment Redis Container App."
  sensitive   = true
}

variable "minio_password" {
  type        = string
  description = "MinIO root password."
  sensitive   = true
}

variable "nextauth_url" {
  type        = string
  description = "Optional external/base URL for Langfuse. Defaults to the private ACA hostname."
  default     = null
}

variable "langfuse_image_tag" {
  type        = string
  description = "Langfuse image tag."
}

variable "telemetry_enabled" {
  type        = bool
  description = "Whether Langfuse telemetry is enabled."
}

variable "clickhouse_url" {
  type        = string
  description = "HTTP URL for ClickHouse."
}

variable "clickhouse_migration_url" {
  type        = string
  description = "Native protocol ClickHouse migration URL."
  sensitive   = true
}

variable "clickhouse_user" {
  type        = string
  description = "ClickHouse username."
}

# variable "redis_host" {
#   type        = string
#   description = "Redis hostname."
# }
#
# variable "redis_port" {
#   type        = number
#   description = "Redis TLS port."
# }

variable "minio_root_user" {
  type        = string
  description = "MinIO root user."
}

variable "minio_image_tag" {
  type        = string
  description = "MinIO image tag on docker.io."
  default     = "latest"
}

variable "redis_image_tag" {
  type        = string
  description = "Redis image tag on docker.io."
  default     = "7-alpine"
}

variable "enable_otel_collector" {
  type        = bool
  description = "Deploy OpenTelemetry Collector in the environment and add OTLP exporter env vars to Langfuse apps."
  default     = true
}

variable "otel_collector_image_tag" {
  type        = string
  description = "Tag for docker.io/otel/opentelemetry-collector-contrib."
  default     = "0.114.0"
}
