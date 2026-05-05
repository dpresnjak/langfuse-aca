terraform {
  required_version = ">= 1.5"

  required_providers {
    # Azure/avm-res-app-managedenvironment/azurerm requires azurerm ~> 4.0 (i.e. >= 4.0, < 5.0). Do not widen to 5.x until that module supports it.
    # Run `terraform init -upgrade` periodically for newest 4.x; it does not reliably fix Application Gateway nested probe/BES plan bugs (see application_gateway lifecycle).
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.66.0, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}