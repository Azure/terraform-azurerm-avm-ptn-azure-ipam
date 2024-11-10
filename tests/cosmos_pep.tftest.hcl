provider "azurerm" {
  features {}
}

run "cosmos_not_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.cosmos[0].name)
    error_message = "cosmos pep was planned"
  }
}

run "cosmos_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_cosmos = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
  }

  assert {
    condition     = can(azurerm_private_endpoint.cosmos[0].name)
    error_message = "cosmos pep was not planned"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.cosmos[0].private_dns_zone_group[0].name)
    error_message = "cosmos pep should not have dns"
  }

  assert {
    condition     = !can(azurerm_private_endpoint.cosmos[0].ip_configuration[0].private_ip_address)
    error_message = "cosmos pep should not have reserved ip"
  }

  assert {
    condition     = length(azurerm_network_security_rule.cosmos) == 0
    error_message = "cosmos pep should not have nsg rules"
  }
}

run "cosmos_planned_with_dns" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_cosmos = {
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com"
    }
  }

  assert {
    condition     = azurerm_private_endpoint.cosmos[0].private_dns_zone_group[0].name == "default"
    error_message = "cosmos pep dns zone group name was incorrect"
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.cosmos[0].private_dns_zone_group[0].private_dns_zone_ids) == 1 &&
      contains(azurerm_private_endpoint.cosmos[0].private_dns_zone_group[0].private_dns_zone_ids, "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com")
    )
    error_message = "cosmos pep dns zone group id was incorrect"
  }
}

run "cosmos_planned_with_reserved_ip" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    private_endpoint_cosmos = {
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      private_ip_addresses = ["192.168.0.1", "192.168.0.2"]
    }
  }

  assert {
    condition     = length(setsubtract(azurerm_private_endpoint.cosmos[0].ip_configuration[*].private_ip_address, ["192.168.0.1", "192.168.0.2"])) == 0
    error_message = "cosmos pep reserved ips were incorrect"
  }
}

// run "cosmos_planned_with_nsg" {
//   command = plan
//   variables {
//     name          = "testing"
//     location      = "uksouth"
//     engine_app_id = "00000000-0000-0000-0000-000000000000"
//     engine_secret = "none"
//     private_endpoint_cosmos = {
//       subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
//       nsg = {
//         name                = "nsg1"
//         resource_group_name = "rg-nsg1"
//         starting_priority   = 1001
//       }
//     }
//   }

//   assert {
//     condition     = length(azurerm_network_security_rule.cosmos) == 1
//     error_message = "cosmos pep does not have nsg rules"
//   }
// }