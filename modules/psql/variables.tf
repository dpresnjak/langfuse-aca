variable "name_prefix" {
  type        = string
  description = "Prefix used for PostgreSQL resource names."
}

variable "location" {
  type        = string
  description = "Azure region for PostgreSQL Flexible Server."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for PostgreSQL resources."
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL major version."
}

variable "administrator_login" {
  type        = string
  description = "PostgreSQL administrator login."
}

variable "administrator_password" {
  type        = string
  description = "PostgreSQL administrator password."
  sensitive   = true
}

variable "database_name" {
  type        = string
  description = "Langfuse database name."
}

variable "sku_name" {
  type        = string
  description = "PostgreSQL Flexible Server SKU."
}

variable "storage_mb" {
  type        = number
  description = "PostgreSQL storage in MB."
}

variable "delegated_subnet_id" {
  type        = string
  description = "Delegated subnet ID for PostgreSQL Flexible Server."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for PostgreSQL Flexible Server."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to PostgreSQL resources."
  default     = {}
}
