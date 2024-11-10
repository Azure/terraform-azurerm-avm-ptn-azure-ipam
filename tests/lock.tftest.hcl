provider "azurerm" {
  features {}
}

run "lock_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
    lock = {
      kind = "ReadOnly"
    }
  }

  assert {
    condition     = can(azurerm_management_lock.this[0].name)
    error_message = "resource lock was not planned"
  }
}

run "lock_not_planned" {
  command = plan
  variables {
    name          = "testing"
    location      = "uksouth"
    engine_app_id = "00000000-0000-0000-0000-000000000000"
    engine_secret = "none"
  }

  assert {
    condition     = !can(azurerm_management_lock.this[0].name)
    error_message = "resource lock was planned"
  }
}