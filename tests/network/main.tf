variable "name" {
  type = string
}

variable "location" {
  type = string
}

resource "azurerm_resource_group" "network" {
  name     = "rg-${var.name}"
  location = var.location
}

resource "azurerm_network_security_group" "network" {
  name                = "nsg-${var.name}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_virtual_network" "network" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "snet1" {
  name                 = "snet1"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["192.168.0.0/25"]
}

resource "azurerm_subnet" "snet2" {
  name                 = "snet2"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["192.168.0.128/25"]
  delegation {
    name = "webapps"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
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

output "nsg" {
  value = azurerm_network_security_group.network
}

output "vnet" {
  value = azurerm_virtual_network.network
}

output "snet1" {
  value = azurerm_subnet.snet1
}

output "snet2" {
  value = azurerm_subnet.snet2
}

output "pdns_keyvault" {
  value = azurerm_private_dns_zone.keyvault
}

output "pdns_cosmos" {
  value = azurerm_private_dns_zone.cosmos
}

output "pdns_webapp" {
  value = azurerm_private_dns_zone.webapp
}