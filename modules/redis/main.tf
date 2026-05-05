locals {
  family = contains(["Premium"], var.sku_name) ? "P" : "C"
}

resource "azurerm_redis_cache" "this" {
  name                = "${var.name_prefix}-redis2"
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity = var.capacity
  family   = local.family
  sku_name = var.sku_name

  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  non_ssl_port_enabled          = false

  redis_configuration {
    maxmemory_policy = "noeviction"
  }

  tags = var.tags
}
