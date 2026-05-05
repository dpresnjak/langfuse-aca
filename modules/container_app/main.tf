module "environment" {
  source = "Azure/avm-res-app-managedenvironment/azurerm"

  name                = "${var.name_prefix}-cae"
  location            = var.location
  resource_group_name = var.resource_group_name

  infrastructure_subnet_id            = var.infrastructure_subnet_id
  infrastructure_resource_group_name  = var.infrastructure_resource_group_name
  internal_load_balancer_enabled      = true
  public_network_access_enabled       = false
  log_analytics_workspace             = { resource_id = var.log_analytics_workspace_id }
  log_analytics_workspace_destination = "log-analytics"
  tags                                = var.tags
}

# Internal ILB FQDNs do not resolve from other subnets without this (Application Gateway health would show "Cannot connect").
# https://learn.microsoft.com/en-us/azure/container-apps/waf-app-gateway#create-and-configure-an-azure-private-dns-zone
resource "azurerm_private_dns_zone" "container_apps_env" {
  name                = module.environment.default_domain
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_apps_env" {
  name                  = "${var.name_prefix}-cae-dnslink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps_env.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "container_apps_env_apex" {
  name                = "@"
  zone_name           = azurerm_private_dns_zone.container_apps_env.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [module.environment.static_ip_address]
}

resource "azurerm_private_dns_a_record" "container_apps_env_wildcard" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.container_apps_env.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [module.environment.static_ip_address]
}

resource "azurerm_container_app_environment_storage" "minio" {
  name                         = "minio"
  container_app_environment_id = module.environment.id
  account_name                 = var.storage_account_name
  share_name                   = var.storage_share_name
  access_key                   = var.storage_access_key
  access_mode                  = "ReadWrite"
}

locals {
  web_host           = "langfuse-web.${module.environment.default_domain}"
  minio_host         = "minio.${module.environment.default_domain}"
  nextauth_base_url  = coalesce(var.nextauth_url, "https://${local.web_host}")
  minio_internal_url = "http://minio:9000"
  minio_external_url = "https://${local.minio_host}"

  minio_image           = "docker.io/minio/minio:${var.minio_image_tag}"
  langfuse_web_image    = "docker.io/langfuse/langfuse:${var.langfuse_image_tag}"
  langfuse_worker_image = "docker.io/langfuse/langfuse-worker:${var.langfuse_image_tag}"

  # Azure Cache for Redis: TLS via rediss://; password must be URL-encoded (keys often contain +/=).
  # Langfuse reads REDIS_TLS_*_PATH, not REDIS_TLS_CA — do not set bogus /certs paths.
  redis_connection_string = "rediss://:${urlencode(var.redis_password)}@${var.redis_host}:${var.redis_port}"

  langfuse_otel_env = var.enable_otel_collector ? [
    { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = "https://otel-collector.${module.environment.default_domain}" },
    { name = "OTEL_EXPORTER_OTLP_PROTOCOL", value = "http/protobuf" },
  ] : []

  otel_collector_yaml = <<-EOT
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  debug:
    verbosity: detailed

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
    path: /

service:
  extensions: [health_check]
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [debug]
    metrics:
      receivers: [otlp]
      exporters: [debug]
    logs:
      receivers: [otlp]
      exporters: [debug]
EOT

  otel_collector_image = "docker.io/otel/opentelemetry-collector-contrib:${var.otel_collector_image_tag}"

  langfuse_common_env = concat(
    [
      { name = "NEXTAUTH_URL", value = local.nextauth_base_url },
      { name = "DATABASE_URL", secret_name = "database-url" },
      { name = "SALT", secret_name = "salt" },
      { name = "ENCRYPTION_KEY", secret_name = "encryption-key" },
      { name = "TELEMETRY_ENABLED", value = tostring(var.telemetry_enabled) },
      { name = "LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES", value = "false" },
      { name = "CLICKHOUSE_MIGRATION_URL", secret_name = "clickhouse-migration-url" },
      { name = "CLICKHOUSE_URL", value = var.clickhouse_url },
      { name = "CLICKHOUSE_USER", value = var.clickhouse_user },
      { name = "CLICKHOUSE_PASSWORD", secret_name = "clickhouse-password" },
      { name = "CLICKHOUSE_CLUSTER_ENABLED", value = "false" },
      { name = "LANGFUSE_USE_AZURE_BLOB", value = "false" },
      { name = "LANGFUSE_USE_OCI_NATIVE_OBJECT_STORAGE", value = "false" },
      { name = "LANGFUSE_OCI_AUTH_TYPE", value = "workload_identity" },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_BUCKET", value = "langfuse" },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_REGION", value = "auto" },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID", value = var.minio_root_user },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY", secret_name = "minio-password" },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT", value = local.minio_internal_url },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE", value = "true" },
      { name = "LANGFUSE_S3_EVENT_UPLOAD_PREFIX", value = "events/" },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_BUCKET", value = "langfuse" },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_REGION", value = "auto" },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID", value = var.minio_root_user },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY", secret_name = "minio-password" },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT", value = local.minio_external_url },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE", value = "true" },
      { name = "LANGFUSE_S3_MEDIA_UPLOAD_PREFIX", value = "media/" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_ENABLED", value = "false" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_BUCKET", value = "langfuse" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_PREFIX", value = "exports/" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_REGION", value = "auto" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_ENDPOINT", value = local.minio_internal_url },
      { name = "LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT", value = local.minio_external_url },
      { name = "LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID", value = var.minio_root_user },
      { name = "LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY", secret_name = "minio-password" },
      { name = "LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE", value = "true" },
      { name = "REDIS_CONNECTION_STRING", secret_name = "redis-connection-string" },
      { name = "REDIS_TLS_ENABLED", value = "false" },
      { name = "EMAIL_FROM_ADDRESS", value = "" },
      { name = "SMTP_CONNECTION_URL", value = "" },
    ],
    local.langfuse_otel_env,
  )
}

resource "azurerm_container_app" "minio" {
  name                         = "minio"
  container_app_environment_id = module.environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  secret {
    name  = "minio-password"
    value = var.minio_password
  }

  template {
    min_replicas = 1
    max_replicas = 1

    volume {
      name         = "miniodata"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.minio.name
    }

    container {
      name    = "minio"
      image   = local.minio_image
      cpu     = 0.5
      memory  = "1.0Gi"
      command = ["sh", "-c", "mkdir -p /data/langfuse && exec minio server /data --address ':9000' --console-address ':9001'"]

      env {
        name  = "MINIO_ROOT_USER"
        value = var.minio_root_user
      }
      env {
        name        = "MINIO_ROOT_PASSWORD"
        secret_name = "minio-password"
      }
      env {
        name  = "MINIO_SERVER_URL"
        value = local.minio_external_url
      }

      volume_mounts {
        name = "miniodata"
        path = "/data"
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 9000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "otel_collector" {
  count = var.enable_otel_collector ? 1 : 0

  name                         = "otel-collector"
  container_app_environment_id = module.environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  depends_on = [azurerm_container_app.minio]

  secret {
    name  = "otel-collector-config"
    value = local.otel_collector_yaml
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "otel-collector"
      image  = local.otel_collector_image
      cpu    = 0.5
      memory = "1.0Gi"
      # azurerm_container_app Secret volumes do not support a secrets{} mapping in this provider; load YAML from env instead.
      env {
        name        = "OTELCOL_CONFIG_YAML"
        secret_name = "otel-collector-config"
      }
      command = ["/otelcol-contrib", "--config=env:OTELCOL_CONFIG_YAML"]
    }
  }

  # CAE-only scope: only Langfuse apps in this managed environment can send OTLP.
  ingress {
    external_enabled = false
    target_port      = 4318
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "langfuse_web" {
  name                         = "langfuse-web"
  container_app_environment_id = module.environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  depends_on = [azurerm_container_app.minio]

  secret {
    name  = "database-url"
    value = var.database_url
  }
  secret {
    name  = "salt"
    value = var.salt
  }
  secret {
    name  = "encryption-key"
    value = var.encryption_key
  }
  secret {
    name  = "nextauth-secret"
    value = var.nextauth_secret
  }
  secret {
    name  = "clickhouse-password"
    value = var.clickhouse_password
  }
  secret {
    name  = "clickhouse-migration-url"
    value = var.clickhouse_migration_url
  }
  secret {
    name  = "redis-connection-string"
    value = local.redis_connection_string
  }
  secret {
    name  = "minio-password"
    value = var.minio_password
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "langfuse-web"
      image  = local.langfuse_web_image
      cpu    = 1.0
      memory = "2.0Gi"

      dynamic "env" {
        for_each = concat(local.langfuse_common_env, [{ name = "NEXTAUTH_SECRET", secret_name = "nextauth-secret" }])
        content {
          name        = env.value.name
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret_name", null)
        }
      }
    }
  }

  # external_enabled = false → portal "Limited to Container Apps Environment" (only other apps in this CAE).
  # Application Gateway lives in another subnet → must use "Limited to VNet": external_enabled = true on the app
  # while the environment stays internal (ILB). See https://github.com/hashicorp/terraform-provider-azurerm/issues/20693
  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "langfuse_worker" {
  name                         = "langfuse-worker"
  container_app_environment_id = module.environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  depends_on = [azurerm_container_app.minio]

  secret {
    name  = "database-url"
    value = var.database_url
  }
  secret {
    name  = "salt"
    value = var.salt
  }
  secret {
    name  = "encryption-key"
    value = var.encryption_key
  }
  secret {
    name  = "clickhouse-password"
    value = var.clickhouse_password
  }
  secret {
    name  = "clickhouse-migration-url"
    value = var.clickhouse_migration_url
  }
  secret {
    name  = "redis-connection-string"
    value = local.redis_connection_string
  }
  secret {
    name  = "minio-password"
    value = var.minio_password
  }

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "langfuse-worker"
      image  = local.langfuse_worker_image
      cpu    = 1.0
      memory = "2.0Gi"

      dynamic "env" {
        for_each = local.langfuse_common_env
        content {
          name        = env.value.name
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret_name", null)
        }
      }
    }
  }
}
