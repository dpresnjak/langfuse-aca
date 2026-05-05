variable "name_prefix" {
  type        = string
  description = "Prefix for Application Gateway and related resource names."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Application Gateway and public IP."
}

variable "subnet_id" {
  type        = string
  description = "Dedicated subnet ID for Application Gateway (no delegations)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}

variable "langfuse_web_host" {
  type        = string
  description = "Langfuse web hostname (Host/SNI sent to the internal Container Apps endpoint)."
}

variable "clickhouse_private_ip" {
  type        = string
  description = "ClickHouse VM private IP for optional HTTP backend."
}

variable "expose_clickhouse" {
  type        = bool
  description = "If true, exposes ClickHouse HTTP (8123) on the public frontend port 8123."
  default     = true
}

variable "sku_capacity" {
  type        = number
  description = "Application Gateway capacity units (instances)."
  default     = 1
}
