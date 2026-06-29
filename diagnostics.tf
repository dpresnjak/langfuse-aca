locals {
  minio_storage_account_id = (
    var.existing_storage_account_name == null
    ? azurerm_storage_account.minio[0].id
    : data.azurerm_storage_account.existing[0].id
  )

  # Keys must be static at plan time; only values may be unknown until apply.
  diagnostics_static_keys = concat(
    [
      "container_apps_environment",
      "langfuse_web_app",
      "langfuse_worker_app",
      "minio_app",
      "redis_app",
      "minio_storage_account",
    ],
    var.use_postgres_container_app ? ["postgres_app"] : ["postgres"],
    var.use_clickhouse_container_app ? ["clickhouse_app"] : ["clickhouse_vm"],
    var.enable_otel_collector ? ["otel_collector_app"] : [],
  )

  diagnostics_resource_ids = {
    container_apps_environment = module.container_app.id
    langfuse_web_app           = module.container_app.langfuse_web_app_id
    langfuse_worker_app        = module.container_app.langfuse_worker_app_id
    minio_app                  = module.container_app.minio_app_id
    redis_app                  = module.container_app.redis_app_id
    otel_collector_app         = module.container_app.otel_collector_app_id
    minio_storage_account      = local.minio_storage_account_id
    clickhouse_vm              = try(module.clickhouse[0].vm_id, null)
    clickhouse_app             = module.container_app.clickhouse_app_id
    postgres_app               = module.container_app.postgres_app_id
    postgres                   = try(module.psql[0].server_id, null)
  }

  diagnostics_targets_enabled = {
    for k in local.diagnostics_static_keys : k => local.diagnostics_resource_ids[k]
  }
}

data "azurerm_monitor_diagnostic_categories" "this" {
  for_each = local.diagnostics_targets_enabled

  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = local.diagnostics_targets_enabled

  name                       = "diag-${var.name_prefix}-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this.id

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.this[each.key].log_category_types)

    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.this[each.key].metrics)

    content {
      category = metric.value
    }
  }
}
