terraform {
  required_version = ">= 1.6.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.104.0"
    }
  }
}