terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 🚀 THIS BLOCK DIRECTS TERRAFORM TO USE YOUR BLOB STORAGE FOR STATE
  backend "azurerm" {
    resource_group_name  = "subhash-mgmt-rg"
    storage_account_name = "subhashtfstate2026"
    container_name       = "tfstate"
    key                  = "core.terraform.tfstate" # Separate state file for core
  }

# 1. Create resource group
resource "azurerm_resource_group" "student_rg" {
  name     = "subhash-student-resources"
  location = "East US"
}

# 2. Create resource container registry
resource "azurerm_container_registry" "acr" {
  name                = "subhashdevopsregistry"
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 3. Fetch current logged-in user context data
data "azurerm_client_config" "current" {}

# 4. Create the Key Vault Instance
resource "azurerm_key_vault" "vault" {
  name                        = "subhashdevops-vault"
  location                    = azurerm_resource_group.student_rg.location
  resource_group_name         = azurerm_resource_group.student_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Grant your terminal identity rights to add secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }
}

# 5. Securely seed your sensitive variables into the vault
resource "azurerm_key_vault_secret" "django_secret" {
  name         = "django-secret-key"  
  value        = var.django_secret_key
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "postgres-db-password"  
  value        = var.postgres_db_password
  key_vault_id = azurerm_key_vault.vault.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}