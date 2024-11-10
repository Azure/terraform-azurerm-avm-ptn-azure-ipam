provider "azurerm" {
  features {}
}

run "no_vnet_integration" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = !can(length(azurerm_linux_web_app.this.virtual_network_subnet_id))
    error_message = "virtual_network_subnet_id was set when it should not be"
  }
}

run "vnet_integration" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    virtual_network_integration = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
  }
  assert {
    condition     = azurerm_linux_web_app.this.virtual_network_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    error_message = "virtual_network_subnet_id did not match the given subnet_id"
  }

  assert {
    condition     = length(azurerm_network_security_rule.webapp) == 0
    error_message = "web nsg rules planned when it should not be"
  }
}

run "vnet_integration_with_nsg" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    virtual_network_integration = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
      nsg = {
        name                  = "nsg1"
        resource_group_name   = "test"
        starting_priority     = 1007
        subnet_address_prefix = "10.0.1.0/24"
      }
    }
  }

  assert {
    condition     = azurerm_linux_web_app.this.virtual_network_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    error_message = "virtual_network_subnet_id did not match the given subnet_id"
  }

  assert {
    condition     = azurerm_network_security_rule.webapp["Outbound-1007"].source_address_prefix == "10.0.1.0/24"
    error_message = "nsg does not have the correct source_address_prefix"
  }
}

