resource "azurerm_resource_group" "this" {
  count = var.resource_group == null ? 1 : 0

  # Mandatory resource attributes
  location = var.location
  name     = local.resource_names.resource_group
  # Optional resource attributes
  tags = var.tags
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  # Mandatory resource attributes
  lock_level = var.lock.kind
  name       = local.resource_names.management_lock
  scope      = local.resource_group.id
  # Optional resource attributes
  notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

data "azurerm_subscription" "this" {}
data "azurerm_client_config" "this" {}
