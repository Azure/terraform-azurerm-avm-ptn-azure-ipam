provider "azurerm" {
  features {}
}

run "public_by_default" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = module.keyvault.resource.public_network_access_enabled == true
    error_message = "keyvault should have public network access enabled"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].default_action == "Allow"
    error_message = "keyvault should default to network_acls to Allow"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].ip_rules == null
    error_message = "keyvault should not have any ip rules"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].virtual_network_subnet_ids == null
    error_message = "keyvault should not have any virtual network rules"
  }

  assert {
    condition     = azurerm_linux_web_app.this.public_network_access_enabled == true
    error_message = "webapp should have public network access enabled"
  }

  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].ip_restriction_default_action == "Allow"
    error_message = "webapp should have ip_restriction_default_action set to Allow"
  }

  assert {
    condition     = length(azurerm_linux_web_app.this.site_config[0].ip_restriction) == 0
    error_message = "webapp should not have any ip restrictions"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.public_network_access_enabled == true
    error_message = "cosmos should have public network access enabled"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.is_virtual_network_filter_enabled == false
    error_message = "cosmos should not have virtual network filter enabled"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.ip_range_filter == null
    error_message = "cosmos should not have any ip range filter"
  }

  assert {
    condition     = length(azurerm_cosmosdb_account.this.virtual_network_rule) == 0
    error_message = "cosmos should not have any virtual network rules"
  }
}

run "public_with_restrictions" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    public_access_keyvault = {
      ip_rules                   = ["192.168.0.1"]
      virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"]
    }
    public_access_cosmos = {
      ip_rules                   = ["192.168.0.1", "192.168.0.2"]
      virtual_network_subnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"]
    }
    public_access_webapp = {
      rules = {
        ip_address_deny = {
          ip_address = "192.168.0.1"
          priority   = 100
          action     = "Deny"
        }
        ip_address_allow = {
          ip_address = "192.168.0.2"
          priority   = 101
        }
        service_tag = {
          service_tag = "AzureFrontDoor.Backend"
          priority    = 102
        }
        virtual_network_subnet_id = {
          virtual_network_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
          priority                  = 103
        }
      }
    }
  }

  assert {
    condition     = module.keyvault.resource.public_network_access_enabled == true
    error_message = "keyvault should have public network access enabled"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].default_action == "Deny"
    error_message = "keyvault should default to network_acls to Deny"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].ip_rules == toset(["192.168.0.1"])
    error_message = "keyvault should have ip rules"
  }

  assert {
    condition     = module.keyvault.resource.network_acls[0].virtual_network_subnet_ids == toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"])
    error_message = "keyvault should have virtual network rules"
  }
  assert {
    condition     = azurerm_cosmosdb_account.this.public_network_access_enabled == true
    error_message = "cosmos should have public network access enabled"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.is_virtual_network_filter_enabled == true
    error_message = "cosmos should have virtual network filter enabled"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.ip_range_filter == "192.168.0.1,192.168.0.2"
    error_message = "cosmos should have csv ip range filter"
  }

  assert {
    condition = alltrue([
      for rule in azurerm_cosmosdb_account.this.virtual_network_rule :
      rule.ignore_missing_vnet_service_endpoint == false &&
      rule.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
    ])
    error_message = "cosmos should have test virtual network rule"
  }

  assert {
    condition     = azurerm_linux_web_app.this.public_network_access_enabled == true
    error_message = "webapp should have public network access enabled"
  }

  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].ip_restriction_default_action == "Deny"
    error_message = "webapp should have ip_restriction_default_action set to Deny"
  }

  assert {
    condition = anytrue([
      for rule in azurerm_linux_web_app.this.site_config[0].ip_restriction :
      alltrue([
        rule.action == "Deny",
        rule.ip_address == "192.168.0.1",
        rule.priority == 100
      ])
      if rule.name == "ip_address_deny"
    ])
    error_message = "webapp deny ip restriction does not match expected values"
  }

  assert {
    condition = anytrue([
      for rule in azurerm_linux_web_app.this.site_config[0].ip_restriction :
      alltrue([
        rule.action == "Allow",
        rule.ip_address == "192.168.0.2",
        rule.priority == 101
      ])
      if rule.name == "ip_address_allow"
    ])
    error_message = "webapp allow ip restriction does not match expected values"
  }

  assert {
    condition = anytrue([
      for rule in azurerm_linux_web_app.this.site_config[0].ip_restriction :
      alltrue([
        rule.action == "Allow",
        rule.service_tag == "AzureFrontDoor.Backend",
        rule.priority == 102
      ])
      if rule.name == "service_tag"
    ])
    error_message = "webapp service_tag restriction does not match expected values"
  }

  assert {
    condition = anytrue([
      for rule in azurerm_linux_web_app.this.site_config[0].ip_restriction :
      alltrue([
        rule.action == "Allow",
        rule.virtual_network_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test",
        rule.priority == 103
      ])
      if rule.name == "virtual_network_subnet_id"
    ])
    error_message = "webapp virtual_network_subnet_id restriction does not match expected values"
  }
}

run "private" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    public_access_keyvault = {
      enabled = false
    }
    public_access_cosmos = {
      enabled = false
    }
    public_access_webapp = {
      enabled = false
    }
  }

  assert {
    condition     = module.keyvault.resource.public_network_access_enabled == false
    error_message = "keyvault should not have public network access enabled"
  }

  assert {
    condition     = azurerm_linux_web_app.this.public_network_access_enabled == false
    error_message = "webapp should not have public network access enabled"
  }
  assert {
    condition     = azurerm_cosmosdb_account.this.public_network_access_enabled == false
    error_message = "cosmos should not have public network access enabled"
  }
}

