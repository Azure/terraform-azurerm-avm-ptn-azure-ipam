variable "engine_app_id" {
  type        = string
  description = "IPAM-Engine App Registration Client/App ID"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.engine_app_id))
    error_message = "engine_app_id must be a well formatted uuid value, for example 00000000-0000-0000-0000-000000000000"
  }
}

variable "engine_secret" {
  type        = string
  description = "IPAM-Engine App Registration Client Secret"
  nullable    = false
  sensitive   = true

  validation {
    condition     = "" != var.engine_secret
    error_message = "engine_secret cannot be an empty string"
  }
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
Azure region where the resource should be deployed.
If the resource_group variable is given, the resource group location will take precedence 
and location should be set to null
DESCRIPTION

  validation {
    condition     = "" != var.location || null == var.location
    error_message = "location cannot be an empty string"
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "law_workspace_resource" {
  type = object({
    id = string
  })
  default     = null
  description = "The Resource Id of the LAW workspace to use in place of one deployed as part of the pattern"

  validation {
    condition = (null == var.law_workspace_resource ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.OperationalInsights\\/workspaces\\/\\S+$", var.law_workspace_resource.id))
    )
    error_message = "law_workspace_resource.id is not a valid Microsoft.OperationalInsights workspace Resource Id"
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "name" {
  type        = string
  default     = "ipam"
  description = <<DESCRIPTION
The default name to use when constructing the resource names.
If a resource name is given in the variable resource_names, that name takes precedence.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "name must be between 5 and 50 characters long and can only contain lowercase letters and numbers."
  }
}

variable "private_endpoint_cosmos" {
  type = object({
    subnet_id = string
    name      = optional(string)
    nsg = optional(object({
      name                  = string
      resource_group_name   = string
      starting_priority     = number
      source_address_prefix = optional(string, "VirtualNetwork")
    }))
    private_dns_zone_id    = optional(string)
    private_dns_zone_group = optional(string, "default")
    private_ip_addresses   = optional(list(string))
  })
  default     = null
  description = <<-DESCRIPTION
  Creates a private endpoint for the deployed cosmos db and optionally, integrates it with a private DNS zone and/or NSG
  ```
  {
    subnet_id              = Resource Id of the subnet in which to create the private endpoint for the cosmosdb. This subnet requires 1 free IP
    name                   = (Optional) The Name to give to the private endpoint
    nsg                    = (Optional) If given, the required security policies to allow connection to the private endpoint will be created
      {
        name                  = The name of the nsg
        resource_group_name   = The name of the resource group holding the nsg
        starting_priority     = The number to start the priority for the required security polices from. 1 policy is required
        source_address_prefix = (Optional) A source range to allow to the private endpoint. Default is "VirtualNetwork"

      }
    private_dns_zone_id    = (Optional) Resource Id of the private dns zone used to resolve privatelink.documents.azure.com records
    private_dns_zone_group = (Optional) Name of the Zone Group used by the private dns zone. Default is "default"
    private_ip_addresses   = (Optional) Two IPs from the subnet to use for the private endpoint ip_configuration
  }
  ```  
  DESCRIPTION

  validation {
    condition = (
      var.private_endpoint_cosmos == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", var.private_endpoint_cosmos.subnet_id))
    )
    error_message = "This does not appear to be a valid Microsoft.Network virtualNetwork subnet Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.name, null) == null ||
      try(var.private_endpoint_cosmos.name, null) != ""
    )
    error_message = "Name cannot be an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.nsg, null) == null ||
      try(var.private_endpoint_cosmos.nsg.name, null) != null && try(var.private_endpoint_cosmos.nsg.name, null) != ""
    )
    error_message = "NSG name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.nsg, null) == null ||
      try(var.private_endpoint_cosmos.nsg.resource_group_name, null) != null && try(var.private_endpoint_cosmos.nsg.resource_group_name, null) != ""
    )
    error_message = "NSG resource_group_name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.nsg.starting_priority, 1000) >= 1000 && try(var.private_endpoint_cosmos.nsg.starting_priority, 1000) <= 4096
    )
    error_message = "NSG starting_priority must be between 1000 and 4096."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.nsg, null) == null ||
      contains(["VirtualNetwork", "AzureLoadBalancer", "Internet"], try(var.private_endpoint_cosmos.nsg.source_address_prefix, "VirtualNetwork")) ||
      can(cidrnetmask(var.private_endpoint_cosmos.nsg.source_address_prefix))
    )
    error_message = "NSG source_address_prefix is not a valid CIDR or Service Tag."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.private_dns_zone_id, null) == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft.Network\\/privateDnsZones\\/privatelink.documents.azure.com$", var.private_endpoint_cosmos.private_dns_zone_id))
    )
    error_message = "This does not appear to be a valid cosmos documents Microsoft.Network privateDnsZones Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.private_dns_zone_group, "unset") != ""
    )
    error_message = "private_dns_zone_group cannot be an empty string"
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.private_ip_addresses, null) == null ||
      alltrue([
        for cidr in try(concat(var.private_endpoint_cosmos.private_ip_addresses, []), []) : can(cidrnetmask("${cidr}/32"))
      ])
    )
    error_message = "One or more IP Address appear to be invalid."
  }
  validation {
    condition = (
      try(var.private_endpoint_cosmos.private_ip_addresses, null) == null ||
      try(length(var.private_endpoint_cosmos.private_ip_addresses), 0) == 2
    )
    error_message = "Two IP Addresses are required"
  }
}

variable "private_endpoint_keyvault" {
  type = object({
    subnet_id = string
    name      = optional(string)
    nsg = optional(object({
      name                  = string
      resource_group_name   = string
      starting_priority     = number
      source_address_prefix = optional(string, "VirtualNetwork")
    }))
    private_dns_zone_id    = optional(string)
    private_dns_zone_group = optional(string, "default")
    private_ip_address     = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
  Creates a private endpoint for the deployed keyvault and optionally, integrates it with a private DNS zone and/or NSG
  ```
  {
    subnet_id              = Resource Id of the subnet in which to create the private endpoint for the keyvault. This subnet requires 1 free IP
    name                   = (Optional) The Name to give to the private endpoint
    nsg                    = (Optional) If given, the required security policies to allow connection to the private endpoint will be created
      {
        name                  = The name of the nsg
        resource_group_name   = The name of the resource group holding the nsg
        starting_priority     = The number to start the priority for the required security polices from. 1 policy is required
        source_address_prefix = (Optional) A source range to allow to the private endpoint. Default is "VirtualNetwork"

      }
    private_dns_zone_id    = (Optional) Resource Id of the private dns zone used to resolve privatelink.vaultcore.azure.net records
    private_dns_zone_group = (Optional) Name of the Zone Group used by the private dns zone. Default is "default"
    private_ip_address     = (Optional) The IP from the subnet to use for the private endpoint ip_configuration
  }
  ```  
  DESCRIPTION

  validation {
    condition = (
      var.private_endpoint_keyvault == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", var.private_endpoint_keyvault.subnet_id))
    )
    error_message = "This does not appear to be a valid Microsoft.Network virtualNetwork subnet Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.name, null) == null ||
      try(var.private_endpoint_keyvault.name, null) != ""
    )
    error_message = "Name cannot be an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.nsg, null) == null ||
      try(var.private_endpoint_keyvault.nsg.name, null) != null && try(var.private_endpoint_keyvault.nsg.name, null) != ""
    )
    error_message = "NSG name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.nsg, null) == null ||
      try(var.private_endpoint_keyvault.nsg.resource_group_name, null) != null && try(var.private_endpoint_keyvault.nsg.resource_group_name, null) != ""
    )
    error_message = "NSG resource_group_name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.nsg.starting_priority, 1000) >= 1000 && try(var.private_endpoint_keyvault.nsg.starting_priority, 1000) <= 4096
    )
    error_message = "NSG starting_priority must be between 1000 and 4096."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.nsg, null) == null ||
      contains(["VirtualNetwork", "AzureLoadBalancer", "Internet"], try(var.private_endpoint_keyvault.nsg.source_address_prefix, "VirtualNetwork")) ||
      can(cidrnetmask(var.private_endpoint_keyvault.nsg.source_address_prefix))
    )
    error_message = "NSG source_address_prefix is not a valid CIDR or Service Tag."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.private_dns_zone_id, null) == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft.Network\\/privateDnsZones\\/privatelink.vaultcore.azure.net$", var.private_endpoint_keyvault.private_dns_zone_id))
    )
    error_message = "This does not appear to be a valid key vault Microsoft.Network privateDnsZones Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.private_dns_zone_group, "unset") != ""
    )
    error_message = "private_dns_zone_group cannot be an empty string"
  }
  validation {
    condition = (
      try(var.private_endpoint_keyvault.private_ip_address, null) == null ||
      can(cidrnetmask("${var.private_endpoint_keyvault.private_ip_address}/32"))
    )
    error_message = "This does not appear to be a valid IP Address."
  }
}

variable "private_endpoint_webapp" {
  type = object({
    subnet_id = string
    name      = optional(string)
    nsg = optional(object({
      name                  = string
      resource_group_name   = string
      starting_priority     = number
      source_address_prefix = optional(string, "VirtualNetwork")
    }))
    private_dns_zone_id    = optional(string)
    private_dns_zone_group = optional(string, "default")
    private_ip_address     = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
  Creates a private endpoint for the deployed web app and optionally, integrates it with a private DNS zone and/or NSG
  ```
  {
    subnet_id              = Resource Id of the subnet in which to create the private endpoint for the web app. This subnet requires 1 free IP
    name                   = (Optional) The Name to give to the private endpoint
    nsg                    = (Optional) If given, the required security policies to allow connection to the private endpoint will be created
      {
        name                  = The name of the nsg
        resource_group_name   = The name of the resource group holding the nsg
        starting_priority     = The number to start the priority for the required security polices from. 1 policy is required
        source_address_prefix = (Optional) A source range to allow to the private endpoint. Default is "VirtualNetwork"
      }
    private_dns_zone_id    = (Optional) Resource Id of the private dns zone used to resolve privatelink.azurewebsites.net records
    private_dns_zone_group = (Optional) Name of the Zone Group used by the private dns zone. Default is "default"
    private_ip_address     = (Optional) The IP from the subnet to use for the private endpoint ip_configuration
  }
  ```  
  DESCRIPTION

  validation {
    condition = (
      var.private_endpoint_webapp == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", var.private_endpoint_webapp.subnet_id))
    )
    error_message = "This does not appear to be a valid Microsoft.Network virtualNetwork subnet Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.name, null) == null ||
      try(var.private_endpoint_webapp.name, null) != ""
    )
    error_message = "Name cannot be an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.nsg, null) == null ||
      try(var.private_endpoint_webapp.nsg.name, null) != null && try(var.private_endpoint_webapp.nsg.name, null) != ""
    )
    error_message = "NSG name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.nsg, null) == null ||
      try(var.private_endpoint_webapp.nsg.resource_group_name, null) != null && try(var.private_endpoint_webapp.nsg.resource_group_name, null) != ""
    )
    error_message = "NSG resource_group_name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.nsg.starting_priority, 1000) >= 1000 && try(var.private_endpoint_webapp.nsg.starting_priority, 1000) <= 4096
    )
    error_message = "NSG starting_priority must be between 1000 and 4096."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.nsg, null) == null ||
      contains(["VirtualNetwork", "AzureLoadBalancer", "Internet"], try(var.private_endpoint_webapp.nsg.source_address_prefix, "VirtualNetwork")) ||
      can(cidrnetmask(var.private_endpoint_webapp.nsg.source_address_prefix))
    )
    error_message = "NSG source_address_prefix is not a valid CIDR ot Service Tag."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.private_dns_zone_id, null) == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft.Network\\/privateDnsZones\\/privatelink.azurewebsites.net$", var.private_endpoint_webapp.private_dns_zone_id))
    )
    error_message = "This does not appear to be a valid web sites Microsoft.Network privateDnsZones Resource Id."
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.private_dns_zone_group, "unset") != ""
    )
    error_message = "private_dns_zone_group cannot be an empty string"
  }
  validation {
    condition = (
      try(var.private_endpoint_webapp.private_ip_address, null) == null ||
      can(cidrnetmask("${var.private_endpoint_webapp.private_ip_address}/32"))
    )
    error_message = "This does not appear to be a valid IP Address."
  }
}

variable "public_access_cosmos" {
  type = object({
    enabled                    = optional(bool, true)
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
  default     = {}
  description = <<-DESCRIPTION
  Configure Public Access to the cosmos account , by default the cosmos account is public.
  ```
  {
    enabled                    = (Optional) Enable or disable public access to the cosmos account. Default is true
    ip_rules                   = (Optional) The list of IP addresses that are allowed to access the key vault.
    virtual_network_subnet_ids = (Optional) The list of virtual network subnet ids that are allowed to access the key vault.
  }
  ```
  DESCRIPTION
  nullable    = false

  validation {
    condition = (
      alltrue([
        for ip in(var.public_access_cosmos.ip_rules != null ? var.public_access_cosmos.ip_rules : []) :
        can(cidrnetmask(ip)) || can(cidrnetmask("${ip}/32"))
      ])
    )
    error_message = "One or more IP Address appear to be invalid."
  }
  validation {
    condition = (
      alltrue([
        for subnet in var.public_access_cosmos.virtual_network_subnet_ids != null ? var.public_access_cosmos.virtual_network_subnet_ids : [] :
        can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", subnet))
      ])
    )
    error_message = "One or more Subnet Ids appear to be invalid."
  }
}

variable "public_access_keyvault" {
  type = object({
    enabled                    = optional(bool, true)
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
  default     = {}
  description = <<-DESCRIPTION
  Configure Public Access to the keyvault, by default the keyvault is made public.
  ```
  {
    enabled                    = (Optional) Enable or disable public access to the key vault. Default is true
    bypass                     = (Optional) The bypass property specifies whether to allow requests to the key vault from the Azure services. Default is "AzureServices"
    ip_rules                   = (Optional) The list of IP addresses that are allowed to access the key vault.
    virtual_network_subnet_ids = (Optional) The list of virtual network subnet ids that are allowed to access the key vault.
  }
  ```
  DESCRIPTION
  nullable    = false

  validation {
    condition = (
      try(var.public_access_keyvault.bypass, "AzureServices") == "AzureServices" ||
      try(var.public_access_keyvault.bypass, "AzureServices") == "None"
    )
    error_message = "bypass must be either \"AzureServices\" or \"None\"."
  }
  validation {
    condition = (
      alltrue([
        for ip in var.public_access_keyvault.ip_rules != null ? var.public_access_keyvault.ip_rules : [] :
        can(cidrnetmask(ip)) || can(cidrnetmask("${ip}/32"))
      ])
    )
    error_message = "One or more IP Address appear to be invalid."
  }
  validation {
    condition = (
      alltrue([
        for subnet in var.public_access_keyvault.virtual_network_subnet_ids != null ? var.public_access_keyvault.virtual_network_subnet_ids : [] :
        can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", subnet))
      ])
    )
    error_message = "One or more Subnet Ids appear to be invalid."
  }
}

variable "public_access_webapp" {
  type = object({
    enabled = optional(bool, true)
    rules = optional(map(object({
      action                    = optional(string, "Allow")
      ip_address                = optional(string)
      priority                  = number
      service_tag               = optional(string)
      virtual_network_subnet_id = optional(string)
    })), {})
  })
  default     = {}
  description = <<-DESCRIPTION
  Configure Public Access to the WebApp, by default the WebApp is made public.
  One and only one of ip_address, service_tag or virtual_network_subnet_id can be specified for each rule.
  ```
  enabled = (Optional) Enable or disable public access to the WebApp. Default is true
  rules   = (Optional) The map of rules that are allowed or denied to access the WebApp.
    {
      action                    = (Optional) The action to take on the rule. Default is "Allow"
      ip_address                = (Optional) The IP address to allow or deny.
      priority                  = The priority of the rule. Starts at 100, the lower the number, the higher the priority.
      service_tag               = (Optional) The service tag to allow or deny.
      virtual_network_subnet_id = (Optional) The virtual network subnet id to allow or deny.
    }
  ```
  DESCRIPTION
  nullable    = false

  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules : contains(["Allow", "Deny"], rule.action)
      ])
    )
    error_message = "One or more rules contain an invalid action."
  }
  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules : rule.priority >= 100
      ])
    )
    error_message = "One or more rules a priority lower then 100."
  }
  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules : can(cidrnetmask(rule.ip_address)) || can(cidrnetmask("${rule.ip_address}/32")) if rule.ip_address != null
      ])
    )
    error_message = "One or more rules contain an invalid ip_address."
  }
  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules : rule.service_tag != "" if rule.service_tag != null
      ])
    )
    error_message = "One or more rules contain an invalid service_tag."
  }
  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules :
        can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+$", rule.virtual_network_subnet_id))
        if rule.virtual_network_subnet_id != null
      ])
    )
    error_message = "One or more rules contain an invalid virtual_network_subnet_id."
  }
  validation {
    condition = (
      alltrue([
        for key, rule in var.public_access_webapp.rules :
        length([
          for value in [
            rule.ip_address,
            rule.service_tag,
            rule.virtual_network_subnet_id
          ] : value if value != null
        ]) == 1
      ])
    )
    error_message = "One or more rules more then one of ip_address, service_tag or virtual_network_subnet_id."
  }
}

variable "resource_group" {
  type = object({
    id       = string
    location = string
    name     = string
  })
  default     = null
  description = "A valid azurerm_resource_group object to use in place of one deployed as part of the pattern."

  validation {
    condition = (
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+$", try(var.resource_group.id, ""))) ||
      var.resource_group == null
    )
    error_message = "resource_group.id is not a valid Microsoft.Resources resourceGroup Resource Id"
  }
  validation {
    condition     = "" != try(var.resource_group.location, "") || var.resource_group == null
    error_message = "location cannot be an empty string"
  }
  validation {
    condition     = "" != try(var.resource_group.name, "") || var.resource_group == null
    error_message = "name cannot be an empty string"
  }
}

variable "resource_names" {
  type = object({
    cosmosdb_account          = optional(string)
    key_vault                 = optional(string)
    log_analytics_workspace   = optional(string)
    management_lock           = optional(string)
    private_endpoint          = optional(string)
    resource_group            = optional(string)
    service_plan              = optional(string)
    user_assigned_identity    = optional(string)
    web_app                   = optional(string)
    private_endpoint_keyvault = optional(string)
    private_endpoint_cosmos   = optional(string)
    private_endpoint_webapp   = optional(string)
  })
  default     = {}
  description = "Alternative names to use for resources deployed by this pattern."
  nullable    = false
}

variable "service_plan_resource" {
  type = object({
    id   = string
    name = string
  })
  default     = null
  description = "The Resource Id of the Service Plan to use in place of one deployed as part of the pattern"

  validation {
    condition = (null == var.service_plan_resource ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Web\\/serverFarms\\/\\S+$", var.service_plan_resource.id))
    )
    error_message = "service_plan_resource.id is not a valid Microsoft.Web serverFarms Resource Id"
  }
  validation {
    condition = (null == var.service_plan_resource ||
      (
        try(var.service_plan_resource.name, null) != null &&
        try(var.service_plan_resource.name, null) != ""
      )
    )
    error_message = "service_plan_resource.name cannot be empty or null"
  }
}

variable "settings_cosmos" {
  type = object({
    capabilities      = optional(list(string), [])
    consistency_level = optional(string, "Session")
    free_tier_enabled = optional(bool)
    max_throughput    = optional(number, 1000)
    tags              = optional(map(string))
    zone_redundant    = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
  Overrides the default settings for the cosmos resource. The following properties can be specified:
  - `capabilities` - (Optional) The list of capabilities to enable for the cosmos account.
  - `consistency_level` - (Optional) The consistency level for the cosmos account.
  - `free_tier_enabled` - (Optional) Whether the cosmos account should use the free tier.
  - `max_throughput` - (Optional) The maximum throughput for the cosmos account.
  - `tags` - (Optional) A mapping of tags to assign to the cosmos module.
  - `zone_redundant` - (Optional) Whether the cosmos account should be zone redundant.
  DESCRIPTION
  nullable    = false
}

variable "settings_keyvault" {
  type = object({
    deployment_user_kv_admin_role = optional(string, "Key Vault Administrator")
    managed_identity_kv_user_role = optional(string, "Key Vault Secrets User")
    sku_name                      = optional(string, "standard")
    tags                          = optional(map(string))
  })
  default     = {}
  description = <<DESCRIPTION
  Overrides the default settings for the keyvault resource. The following properties can be specified:
  - `deployment_user_kv_admin_role` - (Optional) The role definition id or name to assign to the deployment user for the keyvault module.
  - `managed_identity_kv_user_role` - (Optional) The role definition id or name to assign to the managed identity for the keyvault module.  
  - `sku_name` - (Optional) The SKU name to use for the keyvault module.
  - `tags` - (Optional) A mapping of tags to assign to the keyvault module.
  DESCRIPTION
  nullable    = false
}

variable "settings_webapp" {
  type = object({
    docker_image_name        = optional(string, "ipam:latest")
    docker_registry_url      = optional(string, "https://azureipam.azurecr.io")
    docker_registry_username = optional(string)
    docker_registry_password = optional(string)
    log_retention_in_days    = optional(number, 7)
    log_retention_in_mb      = optional(number, 50)
    os_type                  = optional(string, "Linux")
    sku_name                 = optional(string, "P1v3")
    tags                     = optional(map(string))
    zone_balancing_enabled   = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
  Overrides the default settings for the cosmos resource. The following properties can be specified:
  - `docker_image_name` - (Optional) The docker image, including tag, to be used.
  - `docker_registry_url` - (Optional) The URL of the container registry where the docker_image_name is located.
  - `docker_registry_username` - (Optional) The User Name to use for authentication against the registry to pull the image.
  - `docker_registry_password` - (Optional) The Password to use for authentication against the registry to pull the image.
  - `log_retention_in_days` - (Optional) The retention period in days. A value of 0 means no retention.
  - `log_retention_in_mb` - (Optional) The maximum size in megabytes that log files can use.
  - `os_type` - (Optional) The OS type for the Service Plan.
  - `sku_name` - (Optional) The SKU name for the Service Plan.
  - `tags` - (Optional) A mapping of tags to assign to the cosmos module.
  - `zone_balancing_enabled` - (Optional) Whether the app service should be zone balanced.
  DESCRIPTION
  nullable    = false
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "ui_app_id" {
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
  description = "IPAM-UI App Registration Client/App ID"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ui_app_id))
    error_message = "ui_app_id must be a well formatted uuid value, for example 00000000-0000-0000-0000-000000000000"
  }
}

variable "virtual_network_integration" {
  type = object({
    subnet_id = string
    nsg = optional(object({
      name                  = string
      resource_group_name   = string
      starting_priority     = number
      subnet_address_prefix = string
    }))
  })
  default     = null
  description = <<-DESCRIPTION
  Integrate the Web App with an existing virtual network and optionally, integrates it with an NSG to populate the rules it requires to operate.
  ```
  {
    subnet_id = The subnet id which will be used by the Web App for regional virtual network integration. This subnet must have a delegation to Microsoft.Web/serverFarms
    nsg       = (Optional) If given, the required security policies to allow the Web App to operate will be created
      {
        name                  = The name of the nsg
        resource_group_name   = The name of the resource group holding the nsg
        starting_priority     = The number to start the priority for the required security polices from. 1 policy is required
        subnet_address_prefix = The address space for the subnet used for the integration
      }
  }
  ```  
  DESCRIPTION

  validation {
    condition = (
      var.virtual_network_integration == null ||
      can(regex("^\\/subscriptions\\/[\\w-]+\\/resourceGroups\\/\\S+\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/\\S+\\/subnets\\/\\S+$", var.virtual_network_integration.subnet_id))
    )
    error_message = "This does not appear to be a valid Microsoft.Network virtualnetwork subnet Resource Id."
  }
  validation {
    condition = (
      try(var.virtual_network_integration.nsg, null) == null ||
      try(var.virtual_network_integration.nsg.name, null) != null && try(var.virtual_network_integration.nsg.name, null) != ""
    )
    error_message = "NSG name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.virtual_network_integration.nsg, null) == null ||
      try(var.virtual_network_integration.nsg.resource_group_name, null) != null && try(var.virtual_network_integration.nsg.resource_group_name, null) != ""
    )
    error_message = "NSG resource_group_name cannot be null or an empty string."
  }
  validation {
    condition = (
      try(var.virtual_network_integration.nsg.starting_priority, 1000) >= 1000 && try(var.virtual_network_integration.nsg.starting_priority, 1000) <= 4096
    )
    error_message = "NSG starting_priority must be between 1000 and 4096."
  }
  validation {
    condition = (
      try(var.virtual_network_integration.nsg, null) == null ||
      can(cidrnetmask(var.virtual_network_integration.nsg.subnet_address_prefix))
    )
    error_message = "NSG subnet_address_prefix is not a valid CIDR."
  }
}
