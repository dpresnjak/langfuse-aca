resource "azurerm_storage_account" "minio" {
  count                    = var.existing_storage_account_name == null ? 1 : 0
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_share" "minio" {
  name                 = "minio-data"
  storage_account_name = local.storage_account_name
  quota                = var.minio_file_share_quota_gb
}

