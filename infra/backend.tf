terraform {
  backend "azurerm" {
    resource_group_name  = "tf-rg"
    storage_account_name = "tfstateprod123"
    container_name       = "tfstate"
    key                  = "aks-prod.tfstate"
  }
}
