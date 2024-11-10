<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This pattern module deploys the Azure IPAM (https://azure.github.io/ipam/#/) Solution as a container backed App Service using terraform.

## Prerequisites

The module does not deploy any of the "Azure Identities" mentioned in the Azure IPAM Solution (https://azure.github.io/ipam/#/deployment/README).

It is recommended that you initiate "Part 1" of the "Two-part" deployment detailed in the above link. This will create the App IDs and secret required to satisfy the required variables for this module.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_cosmosdb_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) (resource)
- [azurerm_cosmosdb_sql_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) (resource)
- [azurerm_cosmosdb_sql_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database) (resource)
- [azurerm_cosmosdb_sql_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_role_assignment) (resource)
- [azurerm_linux_web_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.appservice](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_monitor_diagnostic_setting.cosmos](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_monitor_diagnostic_setting.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_network_security_rule.cosmos](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_network_security_rule.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_private_endpoint.cosmos](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.managedoperator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_engine_app_id"></a> [engine\_app\_id](#input\_engine\_app\_id)

Description: IPAM-Engine App Registration Client/App ID

Type: `string`

### <a name="input_engine_secret"></a> [engine\_secret](#input\_engine\_secret)

Description: IPAM-Engine App Registration Client Secret

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.  
If the resource\_group variable is given, the resource group location will take precedence   
and location should be set to null

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_law_workspace_resource"></a> [law\_workspace\_resource](#input\_law\_workspace\_resource)

Description: The Resource Id of the LAW workspace to use in place of one deployed as part of the pattern

Type:

```hcl
object({
    id = string
  })
```

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_name"></a> [name](#input\_name)

Description: The default name to use when constructing the resource names.  
If a resource name is given in the variable resource\_names, that name takes precedence.

Type: `string`

Default: `"ipam"`

### <a name="input_private_endpoint_cosmos"></a> [private\_endpoint\_cosmos](#input\_private\_endpoint\_cosmos)

Description: Creates a private endpoint for the deployed cosmos db and optionally, integrates it with a private DNS zone and/or NSG
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

Type:

```hcl
object({
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
```

Default: `null`

### <a name="input_private_endpoint_keyvault"></a> [private\_endpoint\_keyvault](#input\_private\_endpoint\_keyvault)

Description: Creates a private endpoint for the deployed keyvault and optionally, integrates it with a private DNS zone and/or NSG
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

Type:

```hcl
object({
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
```

Default: `null`

### <a name="input_private_endpoint_webapp"></a> [private\_endpoint\_webapp](#input\_private\_endpoint\_webapp)

Description: Creates a private endpoint for the deployed web app and optionally, integrates it with a private DNS zone and/or NSG
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

Type:

```hcl
object({
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
```

Default: `null`

### <a name="input_public_access_cosmos"></a> [public\_access\_cosmos](#input\_public\_access\_cosmos)

Description: Configure Public Access to the cosmos account , by default the cosmos account is public.
```
{
  enabled                    = (Optional) Enable or disable public access to the cosmos account. Default is true
  ip_rules                   = (Optional) The list of IP addresses that are allowed to access the key vault.
  virtual_network_subnet_ids = (Optional) The list of virtual network subnet ids that are allowed to access the key vault.
}
```

Type:

```hcl
object({
    enabled                    = optional(bool, true)
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
```

Default: `{}`

### <a name="input_public_access_keyvault"></a> [public\_access\_keyvault](#input\_public\_access\_keyvault)

Description: Configure Public Access to the keyvault, by default the keyvault is made public.
```
{
  enabled                    = (Optional) Enable or disable public access to the key vault. Default is true
  bypass                     = (Optional) The bypass property specifies whether to allow requests to the key vault from the Azure services. Default is "AzureServices"
  ip_rules                   = (Optional) The list of IP addresses that are allowed to access the key vault.
  virtual_network_subnet_ids = (Optional) The list of virtual network subnet ids that are allowed to access the key vault.
}
```

Type:

```hcl
object({
    enabled                    = optional(bool, true)
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
```

Default: `{}`

### <a name="input_public_access_webapp"></a> [public\_access\_webapp](#input\_public\_access\_webapp)

Description: Configure Public Access to the WebApp, by default the WebApp is made public.  
One and only one of ip\_address, service\_tag or virtual\_network\_subnet\_id can be specified for each rule.
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

Type:

```hcl
object({
    enabled = optional(bool, true)
    rules = optional(map(object({
      action                    = optional(string, "Allow")
      ip_address                = optional(string)
      priority                  = number
      service_tag               = optional(string)
      virtual_network_subnet_id = optional(string)
    })), {})
  })
```

Default: `{}`

### <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group)

Description: A valid azurerm\_resource\_group object to use in place of one deployed as part of the pattern.

Type:

```hcl
object({
    id       = string
    location = string
    name     = string
  })
```

Default: `null`

### <a name="input_resource_names"></a> [resource\_names](#input\_resource\_names)

Description: Alternative names to use for resources deployed by this pattern.

Type:

```hcl
object({
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
```

Default: `{}`

### <a name="input_service_plan_resource"></a> [service\_plan\_resource](#input\_service\_plan\_resource)

Description: The Resource Id of the Service Plan to use in place of one deployed as part of the pattern

Type:

```hcl
object({
    id   = string
    name = string
  })
```

Default: `null`

### <a name="input_settings_cosmos"></a> [settings\_cosmos](#input\_settings\_cosmos)

Description:   Overrides the default settings for the cosmos resource. The following properties can be specified:
  - `capabilities` - (Optional) The list of capabilities to enable for the cosmos account.
  - `consistency_level` - (Optional) The consistency level for the cosmos account.
  - `free_tier_enabled` - (Optional) Whether the cosmos account should use the free tier.
  - `max_throughput` - (Optional) The maximum throughput for the cosmos account.
  - `tags` - (Optional) A mapping of tags to assign to the cosmos module.
  - `zone_redundant` - (Optional) Whether the cosmos account should be zone redundant.

Type:

```hcl
object({
    capabilities      = optional(list(string), [])
    consistency_level = optional(string, "Session")
    free_tier_enabled = optional(bool)
    max_throughput    = optional(number, 1000)
    tags              = optional(map(string))
    zone_redundant    = optional(bool, true)
  })
```

Default: `{}`

### <a name="input_settings_keyvault"></a> [settings\_keyvault](#input\_settings\_keyvault)

Description:   Overrides the default settings for the keyvault resource. The following properties can be specified:
  - `deployment_user_kv_admin_role` - (Optional) The role definition id or name to assign to the deployment user for the keyvault module.
  - `managed_identity_kv_user_role` - (Optional) The role definition id or name to assign to the managed identity for the keyvault module.  
  - `sku_name` - (Optional) The SKU name to use for the keyvault module.
  - `tags` - (Optional) A mapping of tags to assign to the keyvault module.

Type:

```hcl
object({
    deployment_user_kv_admin_role = optional(string, "Key Vault Administrator")
    managed_identity_kv_user_role = optional(string, "Key Vault Secrets User")
    sku_name                      = optional(string, "standard")
    tags                          = optional(map(string))
  })
```

Default: `{}`

### <a name="input_settings_webapp"></a> [settings\_webapp](#input\_settings\_webapp)

Description:   Overrides the default settings for the cosmos resource. The following properties can be specified:
  - `docker_image_name` - (Optional) The docker image, including tag, to be used.
  - `docker_registry_url` - (Optional) The URL of the container registry where the docker\_image\_name is located.
  - `docker_registry_username` - (Optional) The User Name to use for authentication against the registry to pull the image.
  - `docker_registry_password` - (Optional) The Password to use for authentication against the registry to pull the image.
  - `log_retention_in_days` - (Optional) The retention period in days. A value of 0 means no retention.
  - `log_retention_in_mb` - (Optional) The maximum size in megabytes that log files can use.
  - `os_type` - (Optional) The OS type for the Service Plan.
  - `sku_name` - (Optional) The SKU name for the Service Plan.
  - `tags` - (Optional) A mapping of tags to assign to the cosmos module.
  - `zone_balancing_enabled` - (Optional) Whether the app service should be zone balanced.

Type:

```hcl
object({
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
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_ui_app_id"></a> [ui\_app\_id](#input\_ui\_app\_id)

Description: IPAM-UI App Registration Client/App ID

Type: `string`

Default: `"00000000-0000-0000-0000-000000000000"`

### <a name="input_virtual_network_integration"></a> [virtual\_network\_integration](#input\_virtual\_network\_integration)

Description: Integrate the Web App with an existing virtual network and optionally, integrates it with an NSG to populate the rules it requires to operate.
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

Type:

```hcl
object({
    subnet_id = string
    nsg = optional(object({
      name                  = string
      resource_group_name   = string
      starting_priority     = number
      subnet_address_prefix = string
    }))
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_azurerm_cosmosdb_account"></a> [azurerm\_cosmosdb\_account](#output\_azurerm\_cosmosdb\_account)

Description: Cosmos account resource created by the module

### <a name="output_azurerm_cosmosdb_sql_container"></a> [azurerm\_cosmosdb\_sql\_container](#output\_azurerm\_cosmosdb\_sql\_container)

Description: Cosmos sql container resource created by the module

### <a name="output_azurerm_cosmosdb_sql_database"></a> [azurerm\_cosmosdb\_sql\_database](#output\_azurerm\_cosmosdb\_sql\_database)

Description: Cosmos sql database resource created by the module

### <a name="output_azurerm_key_vault"></a> [azurerm\_key\_vault](#output\_azurerm\_key\_vault)

Description: Key vault resource created by the Azure Key Vault module

### <a name="output_azurerm_key_vault_secret"></a> [azurerm\_key\_vault\_secret](#output\_azurerm\_key\_vault\_secret)

Description: A map of secret resources created by the Azure Key Vault Secret module

### <a name="output_azurerm_linux_web_app"></a> [azurerm\_linux\_web\_app](#output\_azurerm\_linux\_web\_app)

Description: Linux Web App resource created by the module

### <a name="output_azurerm_log_analytics_workspace"></a> [azurerm\_log\_analytics\_workspace](#output\_azurerm\_log\_analytics\_workspace)

Description: LAW resource created by the Azure Operationalinsights Workspace module

### <a name="output_azurerm_network_security_rule"></a> [azurerm\_network\_security\_rule](#output\_azurerm\_network\_security\_rule)

Description: A map of maps for the security rules created by the module

### <a name="output_azurerm_private_endpoint"></a> [azurerm\_private\_endpoint](#output\_azurerm\_private\_endpoint)

Description: A map of private endpoints resources created by the module

### <a name="output_azurerm_resource_group"></a> [azurerm\_resource\_group](#output\_azurerm\_resource\_group)

Description: Resource group used by the module

### <a name="output_azurerm_service_plan"></a> [azurerm\_service\_plan](#output\_azurerm\_service\_plan)

Description: Service plan resource created by the module

### <a name="output_azurerm_user_assigned_identity"></a> [azurerm\_user\_assigned\_identity](#output\_azurerm\_user\_assigned\_identity)

Description: Manged Identity resource created by the module

### <a name="output_url"></a> [url](#output\_url)

Description: URL of the deployed Azure IPAM Service

## Modules

The following Modules are called:

### <a name="module_keyvault"></a> [keyvault](#module\_keyvault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.5.3

### <a name="module_law"></a> [law](#module\_law)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.1.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->