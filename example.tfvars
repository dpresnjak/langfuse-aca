subscription_id = ""
location        = "uksouth"
name_prefix     = "langfuse-dev"

# Optional: override NEXTAUTH_URL if you use a custom domain or reverse proxy.
# nextauth_url = "https://langfuse.example.com"

tags = {
  Owner = ""
}

resource_group_name = ""
# Leave null to let Azure create the platform-managed infrastructure resource group automatically.
container_apps_infrastructure_resource_group_name = null

# New VNet in uksouth (subnets created by Terraform when IDs are omitted below).
create_vnet        = true
vnet_name          = "langfuse-dev-vnet"
vnet_address_space = ["192.168.0.0/16"]
vnet_resource_group_name = ""

postgres_subnet_cidr          = "192.168.5.0/24"
private_endpoints_subnet_cidr = "192.168.7.0/24"
clickhouse_vm_subnet_cidr     = "192.168.6.0/24"
container_apps_subnet_cidr    = "192.168.8.0/24"

# Outbound for ACA subnet: NAT gateway allows docker.io image pulls for internal-only Container Apps.
enable_container_apps_nat_gateway = true

# PostgreSQL: Container App (POC) or Flexible Server
use_postgres_container_app = true
postgres_db_name           = "postgres"
# Flexible Server only (when use_postgres_container_app = false):
# postgres_version    = "16"
# postgres_sku_name   = "B_Standard_B2ms"
# postgres_storage_mb = 32768

# ClickHouse: Container App (POC) or Linux VM
use_clickhouse_container_app = true
# VM only (when use_clickhouse_container_app = false):
# clickhouse_vm_size      = "Standard_D2as_v5"
# clickhouse_disk_size_gb = 256
