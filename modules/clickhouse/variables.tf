variable "name_prefix" {
  type        = string
  description = "Prefix used for ClickHouse resource names."
}

variable "location" {
  type        = string
  description = "Azure region for ClickHouse VM resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for ClickHouse VM resources."
}

variable "network_interface_id" {
  type        = string
  description = "NIC ID for the ClickHouse VM."
}

variable "vm_size" {
  type        = string
  description = "VM size for ClickHouse."
}

variable "disk_size_gb" {
  type        = number
  description = "Managed data disk size for ClickHouse."
}

variable "clickhouse_user" {
  type        = string
  description = "ClickHouse username."
}

variable "clickhouse_password" {
  type        = string
  description = "ClickHouse password."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to ClickHouse resources."
  default     = {}
}
