locals {
  tags = merge(
    {
      deployment = "langfuse-azure-container-apps"
      source     = "terraform-template"
    },
    var.tags,
  )

  postgres_location   = coalesce(var.postgres_location, var.location)
  redis_location      = coalesce(var.redis_location, var.location)
  clickhouse_location = coalesce(var.clickhouse_location, var.location)

  storage_account_name = (
    var.existing_storage_account_name == null
    ? substr(lower(replace("${var.name_prefix}${random_string.storage_suffix[0].result}", "-", "")), 0, 24)
    : var.existing_storage_account_name
  )

  storage_access_key = (
    var.existing_storage_account_name == null
    ? azurerm_storage_account.minio[0].primary_access_key
    : data.azurerm_storage_account.existing[0].primary_access_key
  )
}

############
## Redis. ##
############
module "redis" {
  source = "./modules/redis"

  name_prefix         = var.name_prefix
  location            = local.redis_location
  resource_group_name = var.resource_group_name
  sku_name            = var.redis_sku_name
  capacity            = var.redis_capacity
  tags                = local.tags
}

#################  
## Networking. ##
#################
module "networking" {
  source = "./modules/networking"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  vnet_name                = var.vnet_name
  vnet_resource_group_name = var.vnet_resource_group_name
  container_apps_subnet_id   = var.container_apps_infrastructure_subnet_id
  container_apps_subnet_cidr = var.container_apps_subnet_cidr

  postgres_subnet_id   = var.postgres_subnet_id
  postgres_subnet_cidr = var.postgres_subnet_cidr

  private_endpoints_subnet_id   = var.private_endpoints_subnet_id
  private_endpoints_subnet_cidr = var.private_endpoints_subnet_cidr

  clickhouse_vm_subnet_id   = var.clickhouse_vm_subnet_id
  clickhouse_vm_subnet_cidr = var.clickhouse_vm_subnet_cidr

  container_apps_nat_gateway_enabled = var.enable_container_apps_nat_gateway

  redis_cache_id = module.redis.id
  tags           = local.tags
}

#################
## PostgreSQL. ##
#################
module "psql" {
  source = "./modules/psql"

  name_prefix            = var.name_prefix
  location               = local.postgres_location
  resource_group_name    = var.resource_group_name
  postgres_version       = var.postgres_version
  administrator_login    = var.postgres_user
  administrator_password = random_password.postgres.result
  database_name          = var.postgres_db_name
  sku_name               = var.postgres_sku_name
  storage_mb             = var.postgres_storage_mb

  delegated_subnet_id = module.networking.postgres_subnet_id
  private_dns_zone_id = module.networking.postgres_private_dns_zone_id
  tags                = local.tags

  depends_on = [module.networking]
}

#################
## ClickHouse. ##
#################
module "clickhouse" {
  source = "./modules/clickhouse"

  name_prefix          = var.name_prefix
  location             = local.clickhouse_location
  resource_group_name  = var.resource_group_name
  network_interface_id = module.networking.clickhouse_network_interface_id
  vm_size              = var.clickhouse_vm_size
  disk_size_gb         = var.clickhouse_disk_size_gb
  clickhouse_user      = var.clickhouse_user
  clickhouse_password  = random_password.clickhouse.result
  tags                 = local.tags
}

#################
## Container App. ##
#################
module "container_app" {
  source = "./modules/container_app"

  name_prefix                        = var.name_prefix
  location                           = var.location
  resource_group_name                = var.resource_group_name
  infrastructure_subnet_id           = module.networking.container_apps_subnet_id
  virtual_network_id                 = module.networking.virtual_network_id
  log_analytics_workspace_id         = data.azurerm_log_analytics_workspace.this.id
  infrastructure_resource_group_name = var.container_apps_infrastructure_resource_group_name
  tags                               = local.tags

  storage_account_name = local.storage_account_name
  storage_share_name   = azurerm_storage_share.minio.name
  storage_access_key   = local.storage_access_key

  database_url             = "postgresql://${var.postgres_user}:${urlencode(random_password.postgres.result)}@${module.psql.fqdn}:5432/${module.psql.database_name}?sslmode=require"
  salt                     = random_bytes.salt.base64
  encryption_key           = random_bytes.encryption_key.hex
  nextauth_secret          = random_bytes.nextauth_secret.base64
  clickhouse_password      = random_password.clickhouse.result
  clickhouse_migration_url = "clickhouse://${var.clickhouse_user}:${urlencode(random_password.clickhouse.result)}@${module.networking.clickhouse_private_ip}:9000"
  redis_password           = module.redis.primary_access_key
  minio_password           = random_password.minio.result

  nextauth_url = (
    var.nextauth_url != null && trimspace(var.nextauth_url) != ""
    ? var.nextauth_url
    : null
  )
  langfuse_image_tag = var.langfuse_image_tag
  telemetry_enabled  = var.telemetry_enabled
  clickhouse_url     = "http://${module.networking.clickhouse_private_ip}:8123"
  clickhouse_user    = var.clickhouse_user
  redis_host         = module.redis.hostname
  redis_port         = module.redis.ssl_port
  minio_root_user    = var.minio_root_user

  minio_image_tag = var.minio_image_tag

  enable_otel_collector      = var.enable_otel_collector
  otel_collector_image_tag   = var.otel_collector_image_tag

  depends_on = [
    module.psql,
    module.clickhouse,
    module.networking,
    azurerm_storage_share.minio,
  ]
}