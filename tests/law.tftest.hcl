provider "azurerm" {
  features {}
}

run "law_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = can(module.law[0].resource.name)
    error_message = "law module was not planned"
  }
}

run "law_not_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    law_workspace_resource = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/test"
    }
  }

  assert {
    condition     = !can(module.law[0].resource.name)
    error_message = "law module was planned"
  }
}