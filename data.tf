data "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

data "azurerm_storage_account" "existing" {
  count               = var.existing_storage_account_name == null ? 0 : 1
  name                = var.existing_storage_account_name
  resource_group_name = var.resource_group_name
}

