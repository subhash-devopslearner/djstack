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

# 🚀 APP LAYER BACKEND
  backend "azurerm" {
    resource_group_name  = "subhash-mgmt-rg"
    storage_account_name = "subhashtfstate2026"
    container_name       = "tfstate"
    key                  = "apps.terraform.tfstate" # Separate state file for apps
}

# 1. READ existing infrastructure
data "azurerm_resource_group" "existing_rg" {
  name = "subhash-student-resources"
}

data "azurerm_container_registry" "existing_acr" {
  name                = "subhashdevopsregistry"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

# Fetch Key Vault and its secrets dynamically
data "azurerm_key_vault" "existing_vault" {
  name                = "subhashdevops-vault"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

data "azurerm_key_vault_secret" "django_key" {
  name         = "django-secret-key"
  key_vault_id = data.azurerm_key_vault.existing_vault.id
}

data "azurerm_key_vault_secret" "db_pass" {
  name         = "postgres-db-password"
  key_vault_id = data.azurerm_key_vault.existing_vault.id
}

# 2. Deploy your applications
resource "azurerm_container_group" "django_aci" {
  name                = "subhash-django-service"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  image_registry_credential {
    server   = data.azurerm_container_registry.existing_acr.login_server
    username = data.azurerm_container_registry.existing_acr.admin_username
    password = data.azurerm_container_registry.existing_acr.admin_password
  }

  container {
    name   = "django-app"
    image  = "${data.azurerm_container_registry.existing_acr.login_server}/django-app:v1"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    commands = ["/bin/sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]

    # Regular non-sensitive environment items
    environment_variables = {
      DJANGO_DEBUG         = "True"
      DJANGO_ALLOWED_HOSTS = "*"
      DB_NAME              = "postgres"
      DB_USER              = "postgres"
      DB_HOST              = "127.0.0.1" 
      DB_PORT              = "5432"
    }

    # 🔒 SECURE INJECTION PATH: Masked completely on log screens!
    secure_environment_variables = {
      DJANGO_SECRET_KEY = data.azurerm_key_vault_secret.django_key.value
      DB_PASSWORD       = data.azurerm_key_vault_secret.db_pass.value
    }
  }
  
  container {
    name   = "postgres-db"
    image  = "${data.azurerm_container_registry.existing_acr.login_server}/postgres:15-alpine" 
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 5432
      protocol = "TCP"
    }

    environment_variables = {
      POSTGRES_DB   = "postgres"
      POSTGRES_USER = "postgres"
    }

    # 🔒 SECURE INJECTION PATH FOR THE DB SIDECAR
    secure_environment_variables = {
      POSTGRES_PASSWORD = data.azurerm_key_vault_secret.db_pass.value
    }
  }
}

output "django_app_url" {
  value = "http://${azurerm_container_group.django_aci.ip_address}:8000"
}