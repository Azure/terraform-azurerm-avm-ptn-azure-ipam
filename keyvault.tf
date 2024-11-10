module "keyvault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.5.3"

  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = local.resource_names.key_vault
  resource_group_name = local.resource_group.name
  tenant_id           = data.azurerm_client_config.this.tenant_id
  # Optional resource attributes
  enable_telemetry              = var.enable_telemetry
  public_network_access_enabled = var.public_access_keyvault.enabled
  sku_name                      = var.settings_keyvault.sku_name
  tags                          = try(var.settings_keyvault.tags, null) != null ? var.settings_keyvault.tags : var.tags

  diagnostic_settings = {
    law = {
      workspace_resource_id = coalesce(try(var.law_workspace_resource.id, ""), try(module.law[0].workspace_id.id, ""))
    }
  }

  network_acls = var.public_access_keyvault.enabled == false ? null : {
    bypass                     = var.public_access_keyvault.bypass
    default_action             = var.public_access_keyvault.ip_rules == null && var.public_access_keyvault.virtual_network_subnet_ids == null ? "Allow" : "Deny"
    ip_rules                   = var.public_access_keyvault.ip_rules
    virtual_network_subnet_ids = var.public_access_keyvault.virtual_network_subnet_ids
  }

  # Cannot use as hard coded member_name value of "vault" is incorrect - should be "default".
  # Prevents private_ip_address assignment.
  # private_endpoints = var.private_endpoint_keyvault == null ? {} : {
  #   private_endpoint = {
  #     ip_configurations = var.private_endpoint_keyvault.private_ip_address == null ? {} : {
  #       reserved_ip = {
  #         name               = "reserved-ip"
  #         private_ip_address = var.private_endpoint_keyvault.private_ip_address
  #       }
  #     }
  #     location                      = local.resource_group.location
  #     name                          = coalesce(var.resource_names.private_endpoint_keyvault, "${local.resource_names.private_endpoint}-${module.keyvault.resource.name}")
  #     private_dns_zone_group_name   = var.private_endpoint_keyvault.private_dns_zone_group
  #     private_dns_zone_resource_ids = var.private_endpoint_keyvault.private_dns_zone_id != null ? [var.private_endpoint_keyvault.private_dns_zone_id] : null
  #     resource_group_name           = local.resource_group.name
  #     subnet_resource_id            = var.private_endpoint_keyvault.subnet_id
  #     tags                          = var.tags
  #   }
  # }  

  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = var.settings_keyvault.deployment_user_kv_admin_role
      principal_id               = data.azurerm_client_config.this.object_id
    }
    managed_identity_kv_user = {
      role_definition_id_or_name = var.settings_keyvault.managed_identity_kv_user_role
      principal_id               = azurerm_user_assigned_identity.this.principal_id
    }
  }

  secrets = {
    IDENTITY-ID = {
      name = "IDENTITY-ID"
    }
    UI-ID = {
      name = "UI-ID"
    }
    ENGINE-ID = {
      name = "ENGINE-ID"
    }
    ENGINE-SECRET = {
      name = "ENGINE-SECRET"
    }
    TENANT-ID = {
      name = "TENANT-ID"
    }
    COSMOS-KEY = {
      name = "COSMOS-KEY"
    }
  }

  secrets_value = {
    IDENTITY-ID   = azurerm_user_assigned_identity.this.client_id
    UI-ID         = var.ui_app_id
    ENGINE-ID     = var.engine_app_id
    ENGINE-SECRET = var.engine_secret
    TENANT-ID     = data.azurerm_client_config.this.tenant_id
    COSMOS-KEY    = azurerm_cosmosdb_account.this.primary_key
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  count = var.private_endpoint_keyvault != null ? 1 : 0

  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = coalesce(var.resource_names.private_endpoint_keyvault, "${local.resource_names.private_endpoint}-${module.keyvault.resource.name}")
  resource_group_name = local.resource_group.name
  subnet_id           = var.private_endpoint_keyvault.subnet_id
  # Optional resource attributes
  tags = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = module.keyvault.resource.name
    private_connection_resource_id = module.keyvault.resource.id
    subresource_names              = ["vault"]
  }
  dynamic "ip_configuration" {
    for_each = var.private_endpoint_keyvault.private_ip_address != null ? toset([var.private_endpoint_keyvault.private_ip_address]) : toset([])

    content {
      name               = "reserved-ip"
      private_ip_address = ip_configuration.key
      member_name        = "default"
      subresource_name   = "vault"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_keyvault.private_dns_zone_id != null ? toset([var.private_endpoint_keyvault.private_dns_zone_id]) : toset([])

    content {
      name = var.private_endpoint_keyvault.private_dns_zone_group
      private_dns_zone_ids = [
        private_dns_zone_group.value
      ]
    }
  }
}

locals {
  kv_inbound = [
    try(var.private_endpoint_keyvault.nsg.starting_priority, null, null) != null ? {
      nsg = var.private_endpoint_keyvault.nsg
      rule = {
        name                       = "kv-pep-inbound"
        description                = "Inbound HTTPS to Key Vault Private Endpoint"
        priority                   = var.private_endpoint_keyvault.nsg.starting_priority
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = var.private_endpoint_keyvault.nsg.source_address_prefix
        source_port_range          = "*"
        destination_address_prefix = azurerm_private_endpoint.keyvault[0].private_service_connection[0].private_ip_address
        destination_port_range     = "443"
      }
    } : null
  ]
  kv_outbound = []
}

resource "azurerm_network_security_rule" "keyvault" {
  for_each = { for rule in concat(local.kv_inbound, local.kv_outbound) : "${rule.rule.direction}-${rule.rule.priority}" => rule if rule != null }

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
