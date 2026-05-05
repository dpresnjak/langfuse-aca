locals {
  minio_storage_account_id = (
    var.existing_storage_account_name == null
    ? azurerm_storage_account.minio[0].id
    : data.azurerm_storage_account.existing[0].id
  )

  diagnostics_targets = {
    container_apps_environment = module.container_app.id
    langfuse_web_app           = module.container_app.langfuse_web_app_id
    langfuse_worker_app        = module.container_app.langfuse_worker_app_id
    minio_app                  = module.container_app.minio_app_id
    otel_collector_app         = module.container_app.otel_collector_app_id
    redis                      = module.redis.id
    postgres                   = module.psql.server_id
    minio_storage_account      = local.minio_storage_account_id
    clickhouse_vm              = module.clickhouse.vm_id
  }

  diagnostics_targets_enabled = {
    for k, v in local.diagnostics_targets : k => v if v != null
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
    for_each = toset(data.azurerm_monitor_diagnostic_categories.this[each.key].metric_category_types)

    content {
      category = metric.value
    }
  }
}

