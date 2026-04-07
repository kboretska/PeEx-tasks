resource "random_string" "stg_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  # Storage account name: 3-24 chars, lowercase alphanumeric only
  storage_account_name = substr(
    lower(replace("${var.name_prefix}${random_string.stg_suffix.result}", "-", "")),
    0,
    24
  )
}

resource "azurerm_storage_account" "app" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  # Hot/Cool applies to Standard GPv2; omit for Premium
  access_tier = var.storage_account_tier == "Standard" ? var.storage_access_tier : null

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "appdata" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.app.name
  container_access_type = "private"
}
