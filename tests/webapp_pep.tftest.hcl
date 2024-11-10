provider "azurerm" {
  features {}
}

run "app_not_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.webapp[0].name)
    error_message = "app pep was planned"
  }
}

run "app_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_webapp = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
  }

  assert {
    condition     = can(azurerm_private_endpoint.webapp[0].name)
    error_message = "app pep was not planned"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.webapp[0].private_dns_zone_group[0].name)
    error_message = "app pep should not have dns"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.webapp[0].ip_configuration[0].private_ip_address)
    error_message = "app pep should not have reserved ip"
  }

  assert {
    condition     = length(azurerm_network_security_rule.webapp) == 0
    error_message = "app pep should not have nsg rules"
  }
}

run "app_planned_with_dns" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_webapp = {
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"
    }
  }

  assert {
    condition     = azurerm_private_endpoint.webapp[0].private_dns_zone_group[0].name == "default"
    error_message = "app pep dns zone group name was incorrect"
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.webapp[0].private_dns_zone_group[0].private_dns_zone_ids) == 1 &&
      contains(azurerm_private_endpoint.webapp[0].private_dns_zone_group[0].private_dns_zone_ids, "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net")
    )
    error_message = "app pep dns zone group id was incorrect"
  }
}

run "app_planned_with_reserved_ip" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_webapp = {
      subnet_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      private_ip_address = "192.168.0.1"
    }
  }

  assert {
    condition     = azurerm_private_endpoint.webapp[0].ip_configuration[0].private_ip_address == "192.168.0.1"
    error_message = "app pep reserved ip was incorrect"
  }
}

run "app_planned_with_nsg" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_webapp = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      nsg = {
        name                = "nsg1"
        resource_group_name = "rg-nsg1"
        starting_priority   = 1001
      }
    }
  }

  assert {
    condition     = length(azurerm_network_security_rule.webapp) == 1
    error_message = "app pep should not have nsg rules"
  }
}