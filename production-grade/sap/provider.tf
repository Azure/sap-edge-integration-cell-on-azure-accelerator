terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~>1.1.0"
    }
  }
}
 
# Configure the BTP Provider
provider "btp" {
  globalaccount = var.globalaccount
}