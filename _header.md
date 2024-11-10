# terraform-azurerm-avm-template

This pattern module deploys the Azure IPAM (https://azure.github.io/ipam/#/) Solution as a container backed App Service using terraform.

## Prerequisites

The module does not deploy any of the "Azure Identities" mentioned in the Azure IPAM Solution (https://azure.github.io/ipam/#/deployment/README).

It is recommended that you initiate "Part 1" of the "Two-part" deployment detailed in the above link. This will create the App IDs and secret required to satisfy the required variables for this module.
