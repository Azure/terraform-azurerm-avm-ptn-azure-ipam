output "azurerm_cosmosdb_account" {
  description = "Cosmos account resource created by the module"
  sensitive   = true
  value       = azurerm_cosmosdb_account.this
}

output "azurerm_cosmosdb_sql_container" {
  description = "Cosmos sql container resource created by the module"
  value       = azurerm_cosmosdb_sql_container.this
}

output "azurerm_cosmosdb_sql_database" {
  description = "Cosmos sql database resource created by the module"
  value       = azurerm_cosmosdb_sql_database.this
}

output "azurerm_key_vault" {
  description = "Key vault resource created by the Azure Key Vault module"
  value       = module.keyvault.resource
}

output "azurerm_key_vault_secret" {
  description = "A map of secret resources created by the Azure Key Vault Secret module"
  sensitive   = true
  value       = module.keyvault.resource_secrets
}

output "azurerm_linux_web_app" {
  description = "Linux Web App resource created by the module"
  sensitive   = true
  value       = azurerm_linux_web_app.this
}

output "azurerm_log_analytics_workspace" {
  description = "LAW resource created by the Azure Operationalinsights Workspace module"
  sensitive   = true
  value       = length(module.law) != 0 ? module.law[0].resource : null
}

output "azurerm_network_security_rule" {
  description = "A map of maps for the security rules created by the module"
  value = {
    webapp   = azurerm_network_security_rule.webapp != {} ? azurerm_network_security_rule.webapp : null
    keyvault = azurerm_network_security_rule.keyvault != {} ? azurerm_network_security_rule.keyvault : null
    cosmos   = azurerm_network_security_rule.cosmos != {} ? azurerm_network_security_rule.cosmos : null
  }
}

output "azurerm_private_endpoint" {
  description = "A map of private endpoints resources created by the module"
  value = {
    keyvault = module.keyvault.private_endpoints != {} ? module.keyvault.private_endpoints.private_endpoint : null
    webapp   = length(azurerm_private_endpoint.webapp) != 0 ? azurerm_private_endpoint.webapp[0] : null
    cosmos   = length(azurerm_private_endpoint.cosmos) != 0 ? azurerm_private_endpoint.cosmos[0] : null
  }
}

output "azurerm_resource_group" {
  description = "Resource group used by the module"
  value       = local.resource_group
}

output "azurerm_service_plan" {
  description = "Service plan resource created by the module"
  sensitive   = true
  value       = length(azurerm_service_plan.this) != 0 ? azurerm_service_plan.this : null
}

output "azurerm_user_assigned_identity" {
  description = "Manged Identity resource created by the module"
  value       = azurerm_user_assigned_identity.this
}

output "url" {
  description = "URL of the deployed Azure IPAM Service"
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}
