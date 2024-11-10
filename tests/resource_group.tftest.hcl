provider "azurerm" {
  features {}
}

run "pass_resource_group" {
  command = plan
  variables {
    name          = "testing"
    location      = null
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    resource_group = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/given"
      location = "location"
      name     = "given"
    }
  }

  assert {
    condition     = len(azurerm_resource_group.this) == 0
    error_message = "The resouce group should not have been planned"
  }
}
