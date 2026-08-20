data "azurerm_client_config" "current" {}

# Generate strong random passwords
resource "random_password" "db_admin_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_password" "vm_admin_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Key Vault (RBAC Mode)
resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.environment}-app-sec01" # Must be globally unique
  location                   = azurerm_resource_group.spoke.location
  resource_group_name        = azurerm_resource_group.spoke.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# User-Assigned Managed Identity for the App Tier
resource "azurerm_user_assigned_identity" "app" {
  name                = "uai-app-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
}

# Grant App Identity "Key Vault Secrets User"
resource "azurerm_role_assignment" "app_kv_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Store PostgreSQL Password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "postgres-admin-password"
  value        = random_password.db_admin_password.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault.this
  ]
}