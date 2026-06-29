resource "random_password" "postgres" {
  length  = 32
  special = false
}

resource "random_password" "clickhouse" {
  length  = 32
  special = false
}

resource "random_password" "minio" {
  length  = 32
  special = false
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "random_bytes" "salt" {
  length = 32
}

resource "random_bytes" "nextauth_secret" {
  length = 32
}

resource "random_bytes" "encryption_key" {
  length = 32
}

resource "random_string" "storage_suffix" {
  count   = var.existing_storage_account_name == null ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

