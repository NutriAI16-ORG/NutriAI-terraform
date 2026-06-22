terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.13.0"
    }
  }

  backend "azurerm" {
    # Dynamically configured via backend configuration files or CLI options:
    resource_group_name  = "Yaswanth-RG"
    storage_account_name = "yashtfstateaccount"
    container_name       = "tfstate"
    key                  = "nutriai.tfstate"
  }
}


provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

provider "random" {}

provider "azapi" {}
