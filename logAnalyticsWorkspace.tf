# Deploy a LAW if we've not been assigned one to use
module "law" {
  count   = var.law_workspace_resource == null ? 1 : 0
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.1.3"

  # Mandatory resource attributes
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  name                = local.resource_names.log_analytics_workspace
  # Optional resource attributes
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}
