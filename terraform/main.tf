# terraform/main.tf
provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.50.0"
    }
  }
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-aks-github"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-github"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "githubaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "production"
  }
}

