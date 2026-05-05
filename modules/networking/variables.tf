variable "name_prefix" {
  type        = string
  description = "Prefix used for networking resource names."
}

variable "location" {
  type        = string
  description = "Azure region for regional networking resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for created resources."
}

variable "vnet_name" {
  type        = string
  description = "Existing VNet name."
}

variable "vnet_resource_group_name" {
  type        = string
  description = "Resource group containing the existing VNet."
}

variable "postgres_subnet_id" {
  type        = string
  description = "Existing delegated subnet ID for PostgreSQL Flexible Server. If null, the module can create one when postgres_subnet_cidr is set."
  default     = null
}

variable "postgres_subnet_cidr" {
  type        = string
  description = "CIDR for a new PostgreSQL Flexible Server delegated subnet when postgres_subnet_id is null."
  default     = null
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Existing subnet ID for private endpoints. If null, the module can create one when private_endpoints_subnet_cidr is set."
  default     = null
}

variable "private_endpoints_subnet_cidr" {
  type        = string
  description = "CIDR for a new private endpoints subnet when private_endpoints_subnet_id is null."
  default     = null
}

variable "container_apps_subnet_id" {
  type        = string
  description = "Existing delegated subnet ID for the Container Apps environment infrastructure. If null, the module can create one when container_apps_subnet_cidr is set."
  default     = null
}

variable "container_apps_subnet_cidr" {
  type        = string
  description = "CIDR for a new Container Apps subnet when container_apps_subnet_id is null."
  default     = null
}

variable "container_apps_nat_gateway_enabled" {
  type        = bool
  description = "Attach a Standard NAT gateway to the Container Apps subnet so workloads can reach the internet (e.g. Docker Hub) while the environment stays internal-only."
  default     = true
}

variable "clickhouse_vm_subnet_id" {
  type        = string
  description = "Existing subnet ID for the ClickHouse VM. If null, the module can create one when clickhouse_vm_subnet_cidr is set."
  default     = null
}

variable "clickhouse_vm_subnet_cidr" {
  type        = string
  description = "CIDR for a new ClickHouse VM subnet when clickhouse_vm_subnet_id is null."
  default     = null
}

variable "application_gateway_subnet_id" {
  type        = string
  description = "Optional existing subnet ID for an Application Gateway (only used if you still create an AppGW in this repo)."
  default     = null
}

variable "redis_cache_id" {
  type        = string
  description = "Azure Cache for Redis resource ID used to create a private endpoint."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to networking resources."
  default     = {}
}
