terraform {
  required_version = "~> 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.98"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_string" "name" {
  length  = 6
  numeric = false
  special = false
  upper   = false
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

data "http" "terraform_runner_public_ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}


resource "azurerm_resource_group" "network" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = "rg-${random_string.name.result}-02"
}

resource "azurerm_network_security_group" "webapp" {
  location            = azurerm_resource_group.network.location
  name                = "nsg-${random_string.name.result}-01"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_network_security_group" "endpoints" {
  location            = azurerm_resource_group.network.location
  name                = "nsg-${random_string.name.result}-02"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_virtual_network" "network" {
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.network.location
  name                = "vnet-${random_string.name.result}"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "webapp" {
  address_prefixes     = ["192.168.0.0/25"]
  name                 = "webapp"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name

  delegation {
    name = "webapps"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "endpoints" {
  address_prefixes     = ["192.168.0.128/25"]
  name                 = "endpoints"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
}

resource "azurerm_subnet_network_security_group_association" "webapp" {
  network_security_group_id = azurerm_network_security_group.webapp.id
  subnet_id                 = azurerm_subnet.webapp.id
}

resource "azurerm_subnet_network_security_group_association" "endpoints" {
  network_security_group_id = azurerm_network_security_group.endpoints.id
  subnet_id                 = azurerm_subnet.endpoints.id
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_private_dns_zone" "webapp" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = azurerm_virtual_network.network.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  resource_group_name   = azurerm_resource_group.network.name
  virtual_network_id    = azurerm_virtual_network.network.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = azurerm_virtual_network.network.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  resource_group_name   = azurerm_resource_group.network.name
  virtual_network_id    = azurerm_virtual_network.network.id
}

locals {
  runner_ip = "${jsondecode(data.http.terraform_runner_public_ip.response_body).ip}/32"
}

module "private" {
  source = "../../"
  # Mandatory resource attributes
  engine_app_id = "00000000-0000-0000-0000-000000000000"
  engine_secret = "super-secret-secret"
  location      = module.regions.regions[random_integer.region_index.result].name
  name          = random_string.name.result

  # Optional resource attributes
  virtual_network_integration = {
    subnet_id = azurerm_subnet.webapp.id
    nsg = {
      name                  = azurerm_network_security_group.webapp.name
      resource_group_name   = azurerm_network_security_group.webapp.resource_group_name
      starting_priority     = 1001
      subnet_address_prefix = azurerm_subnet.webapp.address_prefixes[0]
    }
  }
  private_endpoint_keyvault = {
    subnet_id = azurerm_subnet.endpoints.id
    nsg = {
      name                  = azurerm_network_security_group.endpoints.name
      resource_group_name   = azurerm_network_security_group.endpoints.resource_group_name
      starting_priority     = 1001
      source_address_prefix = azurerm_subnet.webapp.address_prefixes[0]
    }
    private_dns_zone_id = azurerm_private_dns_zone.keyvault.id
  }
  private_endpoint_cosmos = {
    subnet_id = azurerm_subnet.endpoints.id
    nsg = {
      name                  = azurerm_network_security_group.endpoints.name
      resource_group_name   = azurerm_network_security_group.endpoints.resource_group_name
      starting_priority     = 1002
      source_address_prefix = azurerm_subnet.webapp.address_prefixes[0]
    }
    private_dns_zone_id = azurerm_private_dns_zone.cosmos.id
    private_ip_address  = ["192.168.0.156", "192.168.0.157"]
  }
  private_endpoint_webapp = {
    subnet_id = azurerm_subnet.endpoints.id
    nsg = {
      name                = azurerm_network_security_group.endpoints.name
      resource_group_name = azurerm_network_security_group.endpoints.resource_group_name
      starting_priority   = 1003
    }
    private_dns_zone_id = azurerm_private_dns_zone.webapp.id
  }
  public_access_keyvault = {
    # enabled = false # Uncomment in production
    ip_rules = [local.runner_ip] # Remove in production, needed only for example
  }
  public_access_cosmos = {
    enabled = false
  }
  public_access_webapp = {
    enabled = false
  }
}
