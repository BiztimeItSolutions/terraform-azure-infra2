terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment for remote state management
  # backend "azurerm" {
  #   resource_group_name  = "rg-hawapay-test"
  #   storage_account_name = "tfstatehawapaytest"
  #   container_name       = "terraform-state"
  #   key                  = "prod.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}
