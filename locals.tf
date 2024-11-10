# Resource name defaults
locals {
  resource_group = var.resource_group == null ? azurerm_resource_group.this[0] : coalesce(var.resource_group.id, {})
  resource_names = {
    resource_group          = coalesce(var.resource_names.resource_group, "rg-${var.name}-${var.location}-01")
    management_lock         = coalesce(var.resource_names.management_lock, try(var.lock.name, ""), "lock-${var.name}-${var.location}-01")
    user_assigned_identity  = coalesce(var.resource_names.user_assigned_identity, "id-${var.name}-${var.location}-01")
    log_analytics_workspace = coalesce(var.resource_names.log_analytics_workspace, "law-${var.name}-${var.location}-01")
    key_vault               = coalesce(var.resource_names.key_vault, "kv-${var.name}-${var.location}-01")
    cosmosdb_account        = coalesce(var.resource_names.cosmosdb_account, "cosmos-${var.name}-${var.location}-01")
    service_plan            = coalesce(var.resource_names.service_plan, "asp-${var.name}-${var.location}-01")
    web_app                 = coalesce(var.resource_names.web_app, "app-${var.name}-${var.location}-01")
    private_endpoint        = "pep"
  }
}

