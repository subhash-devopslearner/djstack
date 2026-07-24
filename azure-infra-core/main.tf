# ==============================================================================
# 1. TERRAFORM & PROVIDER CONFIGURATION
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote State Storage
  backend "azurerm" {
    resource_group_name  = "subhash-mgmt-rg"
    storage_account_name = "subhashtfstate2026"
    container_name       = "tfstate"
    key                  = "core.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ==============================================================================
# 2. DATA SOURCES & IMPORT BLOCKS
# ==============================================================================

# Context data for the current subscription & runner context
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# Adopts the pre-existing Resource Group into remote state
import {
  to = azurerm_resource_group.student_rg
  id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/subhash-student-resources"
}

# ==============================================================================
# 3. CORE INFRASTRUCTURE RESOURCES
# ==============================================================================

# Core Resource Group
resource "azurerm_resource_group" "student_rg" {
  name     = "subhash-student-resources"
  location = "East US"
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "subhashdevopsregistry"
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# User-Assigned Managed Identity (for Django App)
resource "azurerm_user_assigned_identity" "django_identity" {
  name                = "django-app-identity"
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
}

# ==============================================================================
# 4. SECURITY & SECRETS (KEY VAULT)
# ==============================================================================

resource "azurerm_key_vault" "vault" {
  name                        = "subhashdevops-vault"
  location                    = azurerm_resource_group.student_rg.location
  resource_group_name         = azurerm_resource_group.student_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Policy A: Runner / Admin permissions (To write/manage secrets)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  # Policy B: Managed Identity permissions (To read secrets at runtime)
  access_policy {
    tenant_id = azurerm_user_assigned_identity.django_identity.tenant_id
    object_id = azurerm_user_assigned_identity.django_identity.principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

# Key Vault Secret Entries
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

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}