terraform{
    required_version = ">=1.5.0"
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
      }
      time = {
        source = "hashicorp/time"
        version = "~>0.10"
      }
    }
}

provider "azurerm"{
    features {}
}

resource "azurerm_resource_group" "hub" {
  name = "rg-hub-${var.environment}"
  location = var.location
  tags = {
    Environment = var.environment
    Tier = "Connectivity-Hub"
  }
}

resource "azurerm_resource_group" "spoke" {
  name = "rg-spoke-${var.environment}"
  location = var.location
  tags = {
    Environment = var.environment
    Tier = "Workload-Spoke"
  }
}

module "hub_network" {
  source = "../../modules/network"
  vnet_name = "vnet-hub-${var.environment}"
  location = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space = ["10.0.0.0/16"]
  subnets = {
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.1.0/26"]
    }
    "AzureBastionSubnet" = {
      address_prefixes = ["10.0.2.0/26"]
    }
    "shared-services-subnet" = {
      address_prefixes = ["10.0.3.0/24"]
    }
    "management-subnet" = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }

  tags = {
    Environment = var.environment
    Role        = "Hub-Network"
  }
}

module "spoke_network" {
  source = "../../modules/network"

  vnet_name           = "vnet-spoke-app-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "app-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    "db-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
      delegation = {
        name         = "flexible-server-delegation"
        service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
      }
    }
    "pe-subnet" = {
      address_prefixes                  = ["10.1.3.0/24"]
      private_endpoint_network_policies = "Disabled" # Best practice for Private Endpoints
    }
  }

  tags = {
    Environment = var.environment
    Role        = "Spoke-Network"
  }
}

# 4. Bidirectional VNet Peering
# Peering 1: Hub -> Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = module.hub_network.vnet_name
  remote_virtual_network_id    = module.spoke_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# Peering 2: Spoke -> Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = azurerm_resource_group.spoke.name
  virtual_network_name         = module.spoke_network.vnet_name
  remote_virtual_network_id    = module.hub_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false # Set to true if GatewaySubnet has an active VPN/ExpressRoute gateway

  depends_on = [
    azurerm_virtual_network_peering.hub_to_spoke
  ]
}