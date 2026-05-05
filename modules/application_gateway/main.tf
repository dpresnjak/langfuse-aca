########################################################
## Currently unused module. AppGw managed externally. ##
########################################################

resource "azurerm_public_ip" "this" {
  name                = "${var.name_prefix}-agw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_security_group" "appgw" {
  name                = "${var.name_prefix}-agw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "gateway_manager" {
  name                        = "AllowGatewayManager"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

# Standard_v2 / WAF_v2 require inbound Internet (not only GatewayManager) on these ports for management.
# https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups
resource "azurerm_network_security_rule" "v2_management_ports_internet" {
  name                        = "AllowV2MgmtPortsInternet"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_network_security_rule" "azure_lb" {
  name                        = "AllowAzureLoadBalancer"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_network_security_rule" "http_inbound" {
  name                        = "AllowHttpInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_network_security_rule" "clickhouse_inbound" {
  count                       = var.expose_clickhouse ? 1 : 0
  name                        = "AllowClickHouseInbound"
  priority                    = 115
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8123"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

# Do not use lifecycle.ignore_changes on probe/backend_http_settings: it hides drift and leaves unhealthy backends (502)
# until someone fixes the gateway in the portal. If azurerm returns "inconsistent final plan" on apply, run once:
# terraform apply -replace='module.application_gateway[0].azurerm_application_gateway.this'
resource "azurerm_application_gateway" "this" {
  name                = "${var.name_prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = var.sku_capacity
  }

  depends_on = [azurerm_subnet_network_security_group_association.appgw]

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "http-80"
    port = 80
  }

  dynamic "frontend_port" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name = "clickhouse-8123"
      port = 8123
    }
  }

  frontend_ip_configuration {
    name                 = "public-fe"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  backend_address_pool {
    name  = "langfuse"
    fqdns = [var.langfuse_web_host]
  }

  dynamic "backend_address_pool" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name         = "clickhouse"
      ip_addresses = [var.clickhouse_private_ip]
    }
  }

  probe {
    name                                      = "langfuse-probe"
    protocol                                  = "Https"
    path                                      = "/api/public/health"
    host                                      = var.langfuse_web_host
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      body = ""
      # Langfuse returns 200 when OK and 503 when degraded (see self-hosting health docs). Do not treat 4xx as healthy.
      status_code = ["200"]
    }
  }

  dynamic "probe" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name                                      = "clickhouse-probe"
      protocol                                  = "Http"
      path                                      = "/ping"
      host                                      = var.clickhouse_private_ip
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = false

      match {
        body        = ""
        status_code = ["200-499"]
      }
    }
  }

  backend_http_settings {
    name                  = "langfuse-bes"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 120
    probe_name            = "langfuse-probe"
    # Explicit host avoids ACA platform 404 ("stopped or does not exist") when pick_host_name_from_backend_address
    # does not reliably apply the Container App FQDN for HTTPS + FQDN pool (Host/SNI must match langfuse-web.<env>).
    host_name                           = var.langfuse_web_host
    pick_host_name_from_backend_address = false
  }

  dynamic "backend_http_settings" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name                                = "clickhouse-bes"
      cookie_based_affinity               = "Disabled"
      port                                = 8123
      protocol                            = "Http"
      request_timeout                     = 120
      probe_name                          = "clickhouse-probe"
      host_name                           = var.clickhouse_private_ip
      pick_host_name_from_backend_address = false
    }
  }

  http_listener {
    name                           = "langfuse-http"
    frontend_ip_configuration_name = "public-fe"
    frontend_port_name             = "http-80"
    protocol                       = "Http"
  }

  dynamic "http_listener" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name                           = "clickhouse-http"
      frontend_ip_configuration_name = "public-fe"
      frontend_port_name             = "clickhouse-8123"
      protocol                       = "Http"
    }
  }

  request_routing_rule {
    name                       = "langfuse-rule"
    rule_type                  = "Basic"
    priority                   = 10
    http_listener_name         = "langfuse-http"
    backend_address_pool_name  = "langfuse"
    backend_http_settings_name = "langfuse-bes"
  }

  dynamic "request_routing_rule" {
    for_each = var.expose_clickhouse ? [1] : []
    content {
      name                       = "clickhouse-rule"
      rule_type                  = "Basic"
      priority                   = 20
      http_listener_name         = "clickhouse-http"
      backend_address_pool_name  = "clickhouse"
      backend_http_settings_name = "clickhouse-bes"
    }
  }
}
