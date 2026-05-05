variable "name_prefix" {
  type        = string
  description = "Prefix used for Redis resource names."
}

variable "location" {
  type        = string
  description = "Azure region for Azure Cache for Redis."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for Redis resources."
}

variable "sku_name" {
  type        = string
  description = "Redis SKU name (Basic, Standard, Premium)."
}

variable "capacity" {
  type        = number
  description = "Redis capacity."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Redis resources."
  default     = {}
}
