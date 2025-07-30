terraform {
     required_version = ">= 1.3.0"
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = ">=3.50.0"
       }
     }
   }

   provider "azurerm" {
     features {}
   }

   data "azurerm_resource_group" "aks_rg" {
     name = "rg-aks-github"
   }

   resource "azurerm_kubernetes_cluster" "aks" {
     name                = "aks-github"
     location            = data.azurerm_resource_group.aks_rg.location
     resource_group_name = data.azurerm_resource_group.aks_rg.name
     dns_prefix          = "githubaks"

     default_node_pool {
       name                = "default"
       node_count          = 2
       vm_size             = "Standard_D2_v3"
       os_disk_size_gb     = 128
       max_pods            = 250
       tags                = {}

       upgrade_settings {
         max_surge = "10%"
       }
     }

     identity {
       type = "SystemAssigned"
     }

     tags = {
       environment = "production"
     }
   }