variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where resources are created."
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Existing Log Analytics workspace name used as the diagnostics destination."
  default     = "test-loganalytics"
}

variable "location" {
  type        = string
  description = "Primary Azure region."
  default     = "eastus2"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names."
  default     = "langfuse-aca"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to supported resources."
  default     = {}
}

variable "vnet_name" {
  type        = string
  description = "Existing VNet name."
}

variable "vnet_resource_group_name" {
  type        = string
  description = "Resource group containing the existing VNet."
}

variable "container_apps_infrastructure_subnet_id" {
  type        = string
  description = "Existing ACA infrastructure subnet ID. Leave null to create one."
  default     = null
}

variable "container_apps_infrastructure_subnet_cidr" {
  type        = string
  description = "CIDR for a new ACA infrastructure subnet when no ID is provided."
  default     = null
}

variable "container_apps_infrastructure_resource_group_name" {
  type        = string
  description = "Optional platform-managed infrastructure resource group name for the Container Apps Environment. Leave null to let Azure generate it."
  default     = null
}

variable "postgres_subnet_id" {
  type        = string
  description = "Existing delegated subnet ID for PostgreSQL Flexible Server. Leave null to create one."
  default     = null
}

variable "postgres_subnet_cidr" {
  type        = string
  description = "CIDR for a new PostgreSQL delegated subnet when no ID is provided."
  default     = null
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Existing private endpoints subnet ID. Leave null to create one."
  default     = null
}

variable "private_endpoints_subnet_cidr" {
  type        = string
  description = "CIDR for a new private endpoints subnet when no ID is provided."
  default     = null
}

variable "clickhouse_vm_subnet_id" {
  type        = string
  description = "Existing ClickHouse VM subnet ID. Leave null to create one."
  default     = null
}

variable "clickhouse_vm_subnet_cidr" {
  type        = string
  description = "CIDR for a new ClickHouse VM subnet when no ID is provided."
  default     = null
}
variable "container_apps_subnet_cidr" {
  type        = string
  description = "CIDR for a new Container Apps subnet."
  default     = null
}

variable "postgres_location" {
  type        = string
  description = "Optional region override for PostgreSQL Flexible Server."
  default     = null
}

variable "redis_location" {
  type        = string
  description = "Optional region override for Azure Cache for Redis."
  default     = null
}

variable "clickhouse_location" {
  type        = string
  description = "Optional region override for the ClickHouse VM."
  default     = null
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL major version."
  default     = "16"
}

variable "postgres_db_name" {
  type        = string
  description = "Langfuse PostgreSQL database name."
  default     = "postgres"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL administrator login."
  default     = "postgres"
}

variable "postgres_sku_name" {
  type        = string
  description = "PostgreSQL Flexible Server SKU."
  default     = "B_Standard_B2ms"
}

variable "postgres_storage_mb" {
  type        = number
  description = "PostgreSQL storage in MB."
  default     = 32768
}

variable "redis_sku_name" {
  type        = string
  description = "Azure Cache for Redis SKU."
  default     = "Basic"
}

variable "redis_capacity" {
  type        = number
  description = "Azure Cache for Redis capacity."
  default     = 1
}

variable "clickhouse_user" {
  type        = string
  description = "ClickHouse username."
  default     = "clickhouse"
}

variable "clickhouse_vm_size" {
  type        = string
  description = "ClickHouse VM size."
  default     = "Standard_B2s"
}

variable "clickhouse_disk_size_gb" {
  type        = number
  description = "ClickHouse managed disk size."
  default     = 256
}

variable "langfuse_image_tag" {
  type        = string
  description = "Langfuse image tag."
  default     = "3"
}

variable "telemetry_enabled" {
  type        = bool
  description = "Whether Langfuse telemetry is enabled."
  default     = true
}

variable "enable_otel_collector" {
  type        = bool
  description = "Deploy OpenTelemetry Collector (contrib) in the Container Apps environment and point Langfuse OTLP exports at it when true."
  default     = true
}

variable "otel_collector_image_tag" {
  type        = string
  description = "Image tag for docker.io/otel/opentelemetry-collector-contrib (OTLP receivers; debug exporter for visibility)."
  default     = "0.114.0"
}

variable "nextauth_url" {
  type        = string
  description = "Optional public Langfuse URL (e.g. https://langfuse.example.com). If unset, defaults to the private Container Apps URL in the module."
  default     = null
}

variable "minio_root_user" {
  type        = string
  description = "MinIO root user."
  default     = "minio"
}

variable "existing_storage_account_name" {
  type        = string
  description = "Optional existing storage account for the MinIO Azure Files share. Leave null to create one."
  default     = null
}

variable "minio_file_share_quota_gb" {
  type        = number
  description = "Quota for the MinIO Azure Files share."
  default     = 100
}

variable "enable_container_apps_nat_gateway" {
  type        = bool
  description = "Attach a NAT gateway to the Container Apps subnet for outbound internet (Docker Hub image pulls, etc.). Recommended for internal-only Container Apps environments."
  default     = true
}

variable "minio_image_tag" {
  type        = string
  description = "MinIO image tag on docker.io (e.g. latest)."
  default     = "latest"
}