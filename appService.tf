resource "azurerm_service_plan" "this" {
  count = var.service_plan_resource == null ? 1 : 0

  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = local.resource_names.service_plan
  os_type             = var.settings_webapp.os_type
  resource_group_name = local.resource_group.name
  sku_name            = var.settings_webapp.sku_name
  # Optional resource attributes
  tags                   = var.tags
  zone_balancing_enabled = var.settings_webapp.zone_balancing_enabled
}

resource "azurerm_linux_web_app" "this" {
  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = local.resource_names.web_app
  resource_group_name = local.resource_group.name
  service_plan_id     = coalesce(try(var.service_plan_resource.id, ""), try(azurerm_service_plan.this[0].id, ""))
  # Optional resource attributes
  app_settings = {
    AZURE_ENV                       = "AZURE_PUBLIC"
    COSMOS_URL                      = azurerm_cosmosdb_account.this.endpoint
    DATABASE_NAME                   = azurerm_cosmosdb_sql_database.this.name
    CONTAINER_NAME                  = azurerm_cosmosdb_sql_container.this.name
    MANAGED_IDENTITY_ID             = format("@Microsoft.KeyVault(SecretUri=%s)", module.keyvault.resource_secrets["IDENTITY-ID"].versionless_id)
    UI_APP_ID                       = format("@Microsoft.KeyVault(SecretUri=%s)", module.keyvault.resource_secrets["UI-ID"].versionless_id)
    ENGINE_APP_ID                   = format("@Microsoft.KeyVault(SecretUri=%s)", module.keyvault.resource_secrets["ENGINE-ID"].versionless_id)
    ENGINE_APP_SECRET               = format("@Microsoft.KeyVault(SecretUri=%s)", module.keyvault.resource_secrets["ENGINE-SECRET"].versionless_id)
    TENANT_ID                       = format("@Microsoft.KeyVault(SecretUri=%s)", module.keyvault.resource_secrets["TENANT-ID"].versionless_id)
    KEYVAULT_URL                    = module.keyvault.resource.vault_uri
    WEBSITE_ENABLE_SYNC_UPDATE_SITE = true
  }
  https_only                      = true
  key_vault_reference_identity_id = azurerm_user_assigned_identity.this.id
  public_network_access_enabled   = var.public_access_webapp.enabled
  tags                            = try(var.settings_webapp.tags, null) != null ? var.settings_webapp.tags : var.tags
  virtual_network_subnet_id       = try(var.virtual_network_integration.subnet_id, null)

  # Mandatory blocks
  site_config {
    always_on                         = true
    health_check_eviction_time_in_min = 2
    health_check_path                 = "/api/status"
    ip_restriction_default_action     = length(var.public_access_webapp.rules) == 0 ? "Allow" : "Deny"

    application_stack {
      docker_image_name        = var.settings_webapp.docker_image_name
      docker_registry_password = var.settings_webapp.docker_registry_password
      docker_registry_url      = var.settings_webapp.docker_registry_url
      docker_registry_username = var.settings_webapp.docker_registry_username
    }
    dynamic "ip_restriction" {
      for_each = var.public_access_webapp.rules

      content {
        action                    = ip_restriction.value["action"]
        ip_address                = ip_restriction.value["ip_address"]
        name                      = ip_restriction.key
        priority                  = ip_restriction.value["priority"]
        service_tag               = ip_restriction.value["service_tag"]
        virtual_network_subnet_id = ip_restriction.value["virtual_network_subnet_id"]
      }
    }
    dynamic "ip_restriction" {
      for_each = length(var.public_access_webapp.rules) > 0 ? toset(["health-check"]) : toset([])

      content {
        action     = "Allow"
        ip_address = "168.63.129.16/32"
        name       = ip_restriction.key
        priority   = 10
      }
    }
  }
  # Optional blocks
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = var.settings_webapp.log_retention_in_days
        retention_in_mb   = var.settings_webapp.log_retention_in_mb
      }
    }
  }

  depends_on = [
    azurerm_private_endpoint.keyvault,
    azurerm_network_security_rule.keyvault,
    azurerm_private_endpoint.cosmos,
    azurerm_network_security_rule.cosmos
  ]
}

resource "azurerm_monitor_diagnostic_setting" "appservice" {
  count = var.service_plan_resource == null ? 1 : 0

  # Mandatory resource attributes
  name                       = azurerm_service_plan.this[0].name
  target_resource_id         = azurerm_service_plan.this[0].id
  log_analytics_workspace_id = coalesce(try(var.law_workspace_resource.id, ""), try(module.law[0].workspace_id.id, ""))

  # Optional blocks
  metric {
    category = "AllMetrics"
  }
}


resource "azurerm_monitor_diagnostic_setting" "webapp" {
  # Mandatory resource attributes
  name                       = azurerm_linux_web_app.this.name
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = coalesce(try(var.law_workspace_resource.id, ""), try(module.law[0].workspace_id.id, ""))

  # Optional blocks
  dynamic "enabled_log" {
    for_each = toset([
      "AppServiceHTTPLogs",
      "AppServiceConsoleLogs",
      "AppServiceAppLogs",
      "AppServiceAuditLogs",
      "AppServiceIPSecAuditLogs",
      "AppServicePlatformLogs"
    ])

    content {
      category = enabled_log.key
    }
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_endpoint" "webapp" {
  count = var.private_endpoint_webapp != null ? 1 : 0

  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = coalesce(var.resource_names.private_endpoint_webapp, "${local.resource_names.private_endpoint}-${azurerm_linux_web_app.this.name}")
  resource_group_name = local.resource_group.name
  subnet_id           = var.private_endpoint_webapp.subnet_id
  # Optional resource attributes
  tags = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = azurerm_linux_web_app.this.name
    private_connection_resource_id = azurerm_linux_web_app.this.id
    subresource_names              = ["sites"]
  }
  dynamic "ip_configuration" {
    for_each = var.private_endpoint_webapp.private_ip_address != null ? toset([var.private_endpoint_webapp.private_ip_address]) : toset([])

    content {
      name               = "reserved-ip"
      private_ip_address = ip_configuration.key
      member_name        = "sites"
      subresource_name   = "sites"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_webapp.private_dns_zone_id != null ? toset([var.private_endpoint_webapp.private_dns_zone_id]) : toset([])

    content {
      name = var.private_endpoint_webapp.private_dns_zone_group
      private_dns_zone_ids = [
        private_dns_zone_group.value
      ]
    }
  }
}

locals {
  app_inbound = [
    try(var.private_endpoint_webapp.nsg.starting_priority, null, null) != null ? {
      nsg = var.private_endpoint_webapp.nsg
      rule = {
        name                       = "app-pep-inbound"
        description                = "Inbound HTTPS to Web App Private Endpoint"
        priority                   = var.private_endpoint_webapp.nsg.starting_priority
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = var.private_endpoint_webapp.nsg.source_address_prefix
        source_port_range          = "*"
        destination_address_prefix = azurerm_private_endpoint.webapp[0].private_service_connection[0].private_ip_address
        destination_port_range     = "443"
      }
    } : null
  ]
  app_outbound = [
    try(var.virtual_network_integration.nsg.starting_priority, null, null) != null ? {
      nsg = var.virtual_network_integration.nsg
      rule = {
        name                       = "app-https-outbound"
        description                = "Outbound HTTPS from Web App"
        priority                   = var.virtual_network_integration.nsg.starting_priority
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = var.virtual_network_integration.nsg.subnet_address_prefix
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "443"
      }
    } : null
  ]
}

resource "azurerm_network_security_rule" "webapp" {
  for_each = { for rule in concat(local.app_inbound, local.app_outbound) : "${rule.rule.direction}-${rule.rule.priority}" => rule if rule != null }

  # Mandatory resource attributes
  access                      = each.value.rule.access
  direction                   = each.value.rule.direction
  name                        = each.value.rule.name
  network_security_group_name = each.value.nsg.name
  priority                    = each.value.rule.priority
  protocol                    = each.value.rule.protocol
  resource_group_name         = each.value.nsg.resource_group_name
  # Optional resource attributes
  description                                = each.value.rule.description
  destination_address_prefix                 = try(each.value.rule.destination_address_prefix, null)
  destination_address_prefixes               = try(each.value.rule.destination_address_prefixes, null)
  destination_application_security_group_ids = try(each.value.rule.destination_application_security_group_ids, null)
  destination_port_range                     = try(each.value.rule.destination_port_range, null)
  destination_port_ranges                    = try(each.value.rule.destination_port_ranges, null)
  source_address_prefix                      = try(each.value.rule.source_address_prefix, null)
  source_address_prefixes                    = try(each.value.rule.source_address_prefixes, null)
  source_application_security_group_ids      = try(each.value.rule.source_application_security_group_ids, null)
  source_port_range                          = each.value.rule.source_port_range
}

# TODO  - Can't use AVM module - not fit for purpose yet.
# module "webapp" {
#   source = "Azure/avm-res-web-site/azurerm"

#   kind                = "webapp"
#   location            = local.resource_group.location
#   name                = coalesce(var.webapp_name, local.webapp_name)
#   os_type             = "Linux"
#   resource_group_name = local.resource_group.name


#   create_service_plan             = true
#   https_only                      = true
#   key_vault_reference_identity_id = azurerm_user_assigned_identity.this.id

#   managed_identities = {
#     system_assigned            = false
#     user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
#   }

#   new_service_plan = {
#     sku_name = "B2"
#   }

#   site_config = {
#     always_on         = true
#     health_check_path = "/api/status"

#     application_stack = tomap({
#       # docker_container_name = "azureipam.azurecr.io/ipam"
#       # docker_container_tag = "latest"

#       ipam = {
#       #   docker_image_name = "azureipam.azurecr.io/ipam"
#       #   # docker_container_tag  = "latest"
#       #   go_version            = "asd"
#       #   java_server           = "asd"
#       #   java_server_version   = "asd"
#       #   php_version           = "asd"
#       #   ruby_version          = "asd"
#       #   # docker = {
#       #   #   image_name = "azureipam.azurecr.io/ipam"
#       #   #   image_tag  = "latest"
#       #   # }
#       }
#       # go_version          = ""
#       # java_server         = ""
#       # java_server_version = ""
#       # php_version         = ""
#       # ruby_version        = ""
#     })
#   }


# }
