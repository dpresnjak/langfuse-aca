# Langfuse on Azure Container Apps (internal) – Terraform

Deploy a self-hosted **Langfuse** stack into an **existing Azure landing zone** (existing Resource Group + VNet), using an **internal** Azure Container Apps Environment (ILB).  
This repo is designed to integrate with a **centralized Application Gateway** that is managed **outside** this Terraform (often in a different subscription/VNet).

## What gets deployed

- **Azure Container Apps Environment (internal / ILB)** + private DNS for internal app FQDN resolution
- **Container Apps**
  - `langfuse-web` (HTTP ingress, VNet-scoped)
  - `langfuse-worker` (no ingress)
  - `minio` (internal-only ingress used by Langfuse)
  - `otel-collector` (optional; internal-only ingress, used by Langfuse OTLP exports)
- **PostgreSQL Flexible Server** (private)
- **Azure Cache for Redis** (private)
- **ClickHouse** on a VM (private)
- **Private Endpoint** for Redis
- **Diagnostic Settings** for the major resources to the configured Log Analytics workspace

## High-level architecture

```
flowchart TB
  subgraph landingZoneVNet[LandingZoneVNet]
    subgraph acaEnv[ContainerAppsEnvironment(InternalILB)]
      langfuseWeb[langfuse-web]
      langfuseWorker[langfuse-worker]
      minio[minio]
      otel[otel-collector]
    end
    pg[PostgresFlexibleServer]
    redis[AzureCacheForRedis]
    ch[ClickHouseVM]
  end

  langfuseWeb --> pg
  langfuseWeb --> redis
  langfuseWeb --> ch
  langfuseWeb --> minio
  langfuseWeb --> otel

  langfuseWorker --> pg
  langfuseWorker --> redis
  langfuseWorker --> ch
  langfuseWorker --> minio
  langfuseWorker --> otel
```

## Prerequisites

- **Terraform** \(>= 1.5\)
- Azure credentials with permission to create resources in:
  - `resource_group_name`
  - the existing VNet/subnets you reference (if you let Terraform create any subnets, you need subnet/VNet write permissions)
- An existing **Log Analytics workspace** (used for diagnostics destination)
- Existing landing zone **VNet** and required subnets (recommended)
  - ACA infrastructure subnet must be delegated to `Microsoft.App/environments`
  - PostgreSQL subnet must be delegated to `Microsoft.DBforPostgreSQL/flexibleServers`
  - Private endpoints subnet must allow private endpoints

## Configuration

Inputs are defined in `variables.tf`. Use `terraform.tfvars` for environment-specific values.

### Required inputs (typical)

- **Azure**:
  - `subscription_id`
  - `resource_group_name`
  - `location`
  - `name_prefix`
- **Existing landing zone VNet**:
  - `vnet_name`
  - `vnet_resource_group_name`
- **Log Analytics destination**:
  - `log_analytics_workspace_name`
- **Subnets**:
  - `container_apps_infrastructure_subnet_id` (recommended for existing landing zone)
  - `postgres_subnet_id` or `postgres_subnet_cidr`
  - `private_endpoints_subnet_id` or `private_endpoints_subnet_cidr`
  - `clickhouse_vm_subnet_id` or `clickhouse_vm_subnet_cidr`

> If you provide a subnet ID, Terraform will **use it**. If you leave an ID null and provide a CIDR, Terraform will **create** that subnet in the existing VNet.

### Optional inputs

- `existing_storage_account_name`: reuse an existing Storage Account for the MinIO Azure Files share
- `enable_otel_collector` / `otel_collector_image_tag`
- `nextauth_url`: set this to the **public URL** your users will browse (recommended when fronted by a central gateway)

## Deploy

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Central Application Gateway integration (managed outside this repo)

This stack exposes **contract outputs** in `outputs.tf` to configure a centralized Application Gateway.

Use these outputs:

- **Backend target / Host/SNI**:
  - `appgw_contract_backend_host`
  - `appgw_contract_backend_host_name_override`
- **Backend protocol/port**:
  - `appgw_contract_backend_protocol` (Https)
  - `appgw_contract_backend_port` (443)
- **Probe**:
  - `appgw_contract_probe_protocol` (Https)
  - `appgw_contract_probe_path` (`/api/public/health`)
  - `appgw_contract_probe_expected_status_codes` (`["200"]`)
- **Private DNS requirements**:
  - `appgw_contract_private_dns_zone_name`
  - `appgw_contract_private_dns_a_records` (both `@` and `*` → CAE ILB IP)

### Important: DNS + routing

The centralized AppGW VNet must be able to resolve `langfuse-web.<defaultDomain>` **to the Container Apps Environment ILB IP** and route to it.\n\nCommon patterns:\n- Link the private DNS zone (named as the CAE `defaultDomain`) to the AppGW VNet, **or**\n- Use DNS forwarding from the hub to the landing zone’s resolver that can resolve that private zone.

## Diagnostics

`diagnostics.tf` configures `azurerm_monitor_diagnostic_setting` for:\n- Container Apps Environment\n- Container Apps (Langfuse web/worker, MinIO, OTEL collector)\n- Redis, Postgres\n- Storage account used for MinIO share\n- ClickHouse VM\n\nAll diagnostics are sent to the Log Analytics workspace `data.azurerm_log_analytics_workspace.this` (configured by `log_analytics_workspace_name`). Categories are discovered via `azurerm_monitor_diagnostic_categories` so the config stays compatible as Azure adds/removes categories.

## OpenTelemetry Collector

When `enable_otel_collector = true`, Langfuse apps get OTLP exporter env vars pointing at `https://otel-collector.<defaultDomain>` (HTTP/protobuf). The collector is configured with a `debug` exporter by default (logs to stdout / Log Analytics).

If you want to export to Azure Monitor / Grafana / another backend, update the collector YAML in `modules/container_app/main.tf` (`local.otel_collector_yaml`) accordingly.

## Troubleshooting

- **502 via central AppGW**:\n  - Verify the AppGW backend **Host/SNI override** matches `appgw_contract_backend_host`\n  - Ensure the AppGW VNet can resolve the private DNS zone `appgw_contract_private_dns_zone_name`\n  - Ensure routing exists between the AppGW subnet/VNet and the landing zone VNet/subnet where the CAE ILB lives
- **Backend shows healthy but still errors**:\n  - Make sure the probe only accepts `200` (this stack’s contract output enforces that)\n- **Container Apps internal FQDN doesn’t resolve**:\n  - Ensure the private DNS zone for the CAE `defaultDomain` is linked to the landing zone VNet (this stack does this)\n- **Provider drift / apply issues**:\n  - This stack intentionally does not manage AppGW resources to avoid common azurerm AppGW plan drift issues.

