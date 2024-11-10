resource "azurerm_cosmosdb_account" "this" {
  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = local.resource_names.cosmosdb_account
  offer_type          = "Standard"
  resource_group_name = local.resource_group.name
  # Optional resource attributes
  automatic_failover_enabled        = true
  free_tier_enabled                 = var.settings_cosmos.free_tier_enabled
  ip_range_filter                   = var.public_access_cosmos.ip_rules != null ? join(",", var.public_access_cosmos.ip_rules) : null
  is_virtual_network_filter_enabled = var.public_access_cosmos.virtual_network_subnet_ids == null ? false : true
  kind                              = "GlobalDocumentDB"
  public_network_access_enabled     = var.public_access_cosmos.enabled
  tags                              = try(var.settings_cosmos.tags, null) != null ? var.settings_cosmos.tags : var.tags

  # Mandatory blocks 
  consistency_policy {
    consistency_level = var.settings_cosmos.consistency_level
  }
  geo_location {
    failover_priority = 0
    location          = local.resource_group.location
    zone_redundant    = var.settings_cosmos.zone_redundant
  }
  # Optional blocks 
  dynamic "capabilities" {
    for_each = toset(var.settings_cosmos.capabilities)

    content {
      name = capabilities.key
    }
  }
  dynamic "virtual_network_rule" {
    for_each = var.public_access_cosmos.virtual_network_subnet_ids != null ? toset(var.public_access_cosmos.virtual_network_subnet_ids) : toset([])

    content {
      id                                   = virtual_network_rule.key
      ignore_missing_vnet_service_endpoint = false
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  # Mandatory resource attributes
  account_name        = azurerm_cosmosdb_account.this.name
  name                = "ipam-db"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  # Mandatory resource attributes
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  name                = "ipam-ctr"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  partition_key_paths = ["/tenant_id"]

  # Optional blocks
  dynamic "autoscale_settings" {
    for_each = toset(contains(var.settings_cosmos.capabilities, "EnableServerless") ? [] : ["1"])

    content {
      max_throughput = var.settings_cosmos.max_throughput
    }
  }
  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name               = azurerm_cosmosdb_account.this.name
  target_resource_id = azurerm_cosmosdb_account.this.id
  # Mandatory resource attributes
  log_analytics_workspace_id = coalesce(try(var.law_workspace_resource.id, ""), try(module.law[0].workspace_id.id, ""))

  # Optional blocks
  dynamic "enabled_log" {
    for_each = toset([
      "DataPlaneRequests",
      "QueryRuntimeStatistics",
      "PartitionKeyStatistics",
      "PartitionKeyRUConsumption",
      "ControlPlaneRequests"
    ])

    content {
      category = enabled_log.key
    }
  }
  metric {
    category = "Requests"
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "this" {
  # Mandatory resource attributes
  account_name        = azurerm_cosmosdb_account.this.name
  principal_id        = azurerm_user_assigned_identity.this.principal_id
  resource_group_name = local.resource_group.name
  role_definition_id  = "${azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  scope               = azurerm_cosmosdb_account.this.id
}

resource "azurerm_private_endpoint" "cosmos" {
  count = var.private_endpoint_cosmos != null ? 1 : 0

  # Mandatory resource attributes
  location            = local.resource_group.location
  name                = coalesce(var.resource_names.private_endpoint_cosmos, "${local.resource_names.private_endpoint}-${azurerm_cosmosdb_account.this.name}")
  resource_group_name = local.resource_group.name
  subnet_id           = var.private_endpoint_cosmos.subnet_id
  # Optional resource attributes
  tags = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = azurerm_cosmosdb_account.this.name
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["Sql"]
  }
  dynamic "ip_configuration" {
    for_each = var.private_endpoint_cosmos.private_ip_addresses != null ? toset([var.private_endpoint_cosmos.private_ip_addresses[0]]) : toset([])

    content {
      name               = azurerm_cosmosdb_account.this.name
      private_ip_address = ip_configuration.key
      member_name        = azurerm_cosmosdb_account.this.name
      subresource_name   = "Sql"
    }
  }
  dynamic "ip_configuration" {
    for_each = var.private_endpoint_cosmos.private_ip_addresses != null ? toset([var.private_endpoint_cosmos.private_ip_addresses[1]]) : toset([])

    content {
      name               = "${azurerm_cosmosdb_account.this.name}-${local.resource_group.location}"
      private_ip_address = ip_configuration.key
      member_name        = "${azurerm_cosmosdb_account.this.name}-${local.resource_group.location}"
      subresource_name   = "Sql"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_cosmos.private_dns_zone_id != null ? toset([var.private_endpoint_cosmos.private_dns_zone_id]) : toset([])

    content {
      name = var.private_endpoint_cosmos.private_dns_zone_group
      private_dns_zone_ids = [
        private_dns_zone_group.value
      ]
    }
  }
}

locals {
  db_inbound = [
    try(var.private_endpoint_cosmos.nsg.starting_priority, null, null) != null ? {
      nsg = var.private_endpoint_cosmos.nsg
      rule = {
        name                  = "cosmos-pep-inbound"
        description           = "Inbound HTTPS to Cosmos Private Endpoint"
        priority              = var.private_endpoint_cosmos.nsg.starting_priority
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = var.private_endpoint_cosmos.nsg.source_address_prefix
        source_port_range     = "*"
        destination_address_prefixes = distinct(flatten([
          try(azurerm_private_endpoint.cosmos[0].custom_dns_configs[*].ip_addresses, []),
          try(azurerm_private_endpoint.cosmos[0].private_dns_zone_configs[0].record_sets[*].ip_addresses, [])
        ]))
        destination_port_range = "443"
      }
    } : null
  ]
  db_outbound = []
}

resource "azurerm_network_security_rule" "cosmos" {
  for_each = { for rule in concat(local.db_inbound, local.db_outbound) : "${rule.rule.direction}-${rule.rule.priority}" => rule if rule != null }

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
