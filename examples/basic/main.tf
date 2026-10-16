terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

module "zoorik_coral" {
  source = "../.."

  cluster_id      = data.azurerm_kubernetes_cluster.this.id
  location        = data.azurerm_kubernetes_cluster.this.location
  oidc_issuer_url = data.azurerm_kubernetes_cluster.this.oidc_issuer_url
}
