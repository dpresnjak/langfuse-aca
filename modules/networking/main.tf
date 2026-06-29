data "azurerm_virtual_network" "existing" {
  count               = var.create_vnet ? 0 : 1
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

resource "azurerm_virtual_network" "this" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.vnet_resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

locals {
  virtual_network_name = var.create_vnet ? azurerm_virtual_network.this[0].name : var.vnet_name
  virtual_network_id   = var.create_vnet ? azurerm_virtual_network.this[0].id : data.azurerm_virtual_network.existing[0].id
}

resource "azurerm_subnet" "container_apps" {
  count                = var.container_apps_subnet_id == null ? 1 : 0
  name                 = "${var.name_prefix}-aca-infra"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.container_apps_subnet_cidr]

  depends_on = [azurerm_virtual_network.this]

  delegation {
    name = "container-apps"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_public_ip" "container_apps_nat" {
  count               = var.container_apps_nat_gateway_enabled ? 1 : 0
  name                = "${var.name_prefix}-aca-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "container_apps" {
  count               = var.container_apps_nat_gateway_enabled ? 1 : 0
  name                = "${var.name_prefix}-aca-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "container_apps" {
  count                = var.container_apps_nat_gateway_enabled ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.container_apps[0].id
  public_ip_address_id = azurerm_public_ip.container_apps_nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "container_apps" {
  count          = var.container_apps_nat_gateway_enabled ? 1 : 0
  subnet_id      = local.container_apps_subnet_id
  nat_gateway_id = azurerm_nat_gateway.container_apps[0].id

  depends_on = [
    azurerm_nat_gateway.container_apps,
    azurerm_nat_gateway_public_ip_association.container_apps,
  ]
}

resource "azurerm_subnet" "postgres" {
  count                = var.enable_postgres_flexible_server && var.postgres_subnet_id == null ? 1 : 0
  name                 = "${var.name_prefix}-postgres"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.postgres_subnet_cidr]

  delegation {
    name = "postgres-flexible-server"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  count                = var.private_endpoints_subnet_id == null ? 1 : 0
  name                 = "${var.name_prefix}-private-endpoints"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.private_endpoints_subnet_cidr]
}

resource "azurerm_subnet" "clickhouse_vm" {
  count                = var.enable_clickhouse_vm && var.clickhouse_vm_subnet_id == null ? 1 : 0
  name                 = "${var.name_prefix}-clickhouse-vm"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.clickhouse_vm_subnet_cidr]
}

locals {
  container_apps_subnet_id      = coalesce(var.container_apps_subnet_id, try(azurerm_subnet.container_apps[0].id, null))
  postgres_subnet_id = (
    var.enable_postgres_flexible_server
    ? coalesce(var.postgres_subnet_id, azurerm_subnet.postgres[0].id)
    : var.postgres_subnet_id
  )
  private_endpoint_subnet_id    = coalesce(var.private_endpoints_subnet_id, try(azurerm_subnet.private_endpoints[0].id, null))
  clickhouse_vm_subnet_id = (
    var.enable_clickhouse_vm
    ? coalesce(var.clickhouse_vm_subnet_id, try(azurerm_subnet.clickhouse_vm[0].id, null))
    : var.clickhouse_vm_subnet_id
  )
  application_gateway_subnet_id = var.application_gateway_subnet_id
}

resource "azurerm_private_dns_zone" "postgres" {
  count               = var.enable_postgres_flexible_server ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.enable_postgres_flexible_server ? 1 : 0
  name                  = "${var.name_prefix}-postgres"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = local.virtual_network_id
  tags                  = var.tags
}

# resource "azurerm_private_dns_zone" "redis" {
#   name                = "privatelink.redis.cache.windows.net"
#   resource_group_name = var.resource_group_name
#   tags                = var.tags
# }
#
# resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
#   name                  = "${var.name_prefix}-redis"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.redis.name
#   virtual_network_id    = data.azurerm_virtual_network.this.id
#   tags                  = var.tags
# }
#
# resource "azurerm_private_endpoint" "redis" {
#   name                = "${var.name_prefix}-redis-pe"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = local.private_endpoint_subnet_id
#   tags                = var.tags
#
#   private_service_connection {
#     name                           = "${var.name_prefix}-redis"
#     private_connection_resource_id = var.redis_cache_id
#     subresource_names              = ["redisCache"]
#     is_manual_connection           = false
#   }
#
#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
#   }
#
#   depends_on = [azurerm_private_dns_zone_virtual_network_link.redis]
# }

resource "azurerm_network_security_group" "clickhouse" {
  count               = var.enable_clickhouse_vm ? 1 : 0
  name                = "${var.name_prefix}-clickhouse-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-clickhouse-from-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8123", "9000"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "clickhouse" {
  count               = var.enable_clickhouse_vm ? 1 : 0
  name                = "${var.name_prefix}-clickhouse-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = coalesce(var.clickhouse_vm_subnet_id, try(azurerm_subnet.clickhouse_vm[0].id, null))
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet.clickhouse_vm]
}

resource "azurerm_network_interface_security_group_association" "clickhouse" {
  count                     = var.enable_clickhouse_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.clickhouse[0].id
  network_security_group_id = azurerm_network_security_group.clickhouse[0].id
}
