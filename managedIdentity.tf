resource "azurerm_user_assigned_identity" "this" {
  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = local.resource_names.user_assigned_identity
  resource_group_name = local.resource_group.name
  # Optional resource attributes
  tags = var.tags
}

# TODO: Not entirely sure this is required
# resource "azurerm_role_assignment" "contributor" {
#   scope                = data.azurerm_subscription.this.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.this.principal_id
# }

resource "azurerm_role_assignment" "managedoperator" {
  # Mandatory resource attributes
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  scope                = data.azurerm_subscription.this.id
  role_definition_name = "Managed Identity Operator"
}
