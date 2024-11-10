provider "azurerm" {
  features {}
}

run "default_resource_names_are_correct" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    lock = {
      kind = "ReadOnly"
    }
    private_endpoint_keyvault = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
    private_endpoint_cosmos = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
    private_endpoint_webapp = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
  }

  assert {
    condition     = local.resource_group.name == "rg-testing-uksouth-01"
    error_message = "resource_group name did not match expected"
  }
  assert {
    condition     = azurerm_management_lock.this[0].name == "lock-testing-uksouth-01"
    error_message = "management_lock name did not match expected"
  }
  assert {
    condition     = azurerm_user_assigned_identity.this.name == "id-testing-uksouth-01"
    error_message = "user_assigned_identity name did not match expected"
  }
  assert {
    condition     = module.law[0].resource.name == "law-testing-uksouth-01"
    error_message = "log_analytics_workspace name did not match expected"
  }
  assert {
    condition     = module.keyvault.resource.name == "kv-testing-uksouth-01"
    error_message = "key_vault name did not match expected"
  }
  assert {
    condition     = azurerm_cosmosdb_account.this.name == "cosmos-testing-uksouth-01"
    error_message = "cosmosdb_account name did not match expected"
  }
  assert {
    condition     = azurerm_service_plan.this[0].name == "asp-testing-uksouth-01"
    error_message = "cosmosdb_account name did not match expected"
  }
  assert {
    condition     = azurerm_linux_web_app.this.name == "app-testing-uksouth-01"
    error_message = "linux_web_app name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.keyvault[0].name == "pep-kv-testing-uksouth-01"
    error_message = "keyvault pep name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.cosmos[0].name == "pep-cosmos-testing-uksouth-01"
    error_message = "keyvault pep name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.webapp[0].name == "pep-app-testing-uksouth-01"
    error_message = "keyvault pep name did not match expected"
  }
}

run "given_resource_names_are_correct" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    lock = {
      kind = "ReadOnly"
    }
    private_endpoint_keyvault = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
    private_endpoint_cosmos = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
    private_endpoint_webapp = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/sub1"
    }
    resource_names = {
      cosmosdb_account          = "given-cosmos-name"
      key_vault                 = "given-kv-name"
      log_analytics_workspace   = "given-law-name"
      management_lock           = "given-lock-name"
      resource_group            = "given-rg-name"
      service_plan              = "given-asp-name"
      user_assigned_identity    = "given-id-name"
      web_app                   = "given-app-name"
      private_endpoint_keyvault = "given-kv-pep-name"
      private_endpoint_cosmos   = "given-cosmos-pep-name"
      private_endpoint_webapp   = "given-webapp-pep-name"
    }
  }

  assert {
    condition     = local.resource_group.name == "given-rg-name"
    error_message = "resource_group name did not match expected"
  }
  assert {
    condition     = azurerm_management_lock.this[0].name == "given-lock-name"
    error_message = "management_lock name did not match expected"
  }
  assert {
    condition     = azurerm_user_assigned_identity.this.name == "given-id-name"
    error_message = "user_assigned_identity name did not match expected"
  }
  assert {
    condition     = module.law[0].resource.name == "given-law-name"
    error_message = "log_analytics_workspace name did not match expected"
  }
  assert {
    condition     = module.keyvault.resource.name == "given-kv-name"
    error_message = "key_vault name did not match expected"
  }
  assert {
    condition     = azurerm_cosmosdb_account.this.name == "given-cosmos-name"
    error_message = "cosmosdb_account name did not match expected"
  }
  assert {
    condition     = azurerm_service_plan.this[0].name == "given-asp-name"
    error_message = "cosmosdb_account name did not match expected"
  }
  assert {
    condition     = azurerm_linux_web_app.this.name == "given-app-name"
    error_message = "linux_web_app name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.keyvault[0].name == "given-kv-pep-name"
    error_message = "keyvault pep name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.cosmos[0].name == "given-cosmos-pep-name"
    error_message = "keyvault pep name did not match expected"
  }
  assert {
    condition     = azurerm_private_endpoint.webapp[0].name == "given-webapp-pep-name"
    error_message = "keyvault pep name did not match expected"
  }
}
