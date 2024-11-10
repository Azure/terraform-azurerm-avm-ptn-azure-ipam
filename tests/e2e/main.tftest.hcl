provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

run "setup" {
  module {
    source = "../setup"
  }
}

run "e2e_public" {
  variables {
    name                   = run.setup.name
    location               = "uksouth"
    engine_app_id          = "00000000-0000-0000-0000-000000000000"
    engine_secret          = "none"
    public_access_keyvault = {}
    public_access_webapp   = {}
    public_access_cosmos   = {}
  }
}

run "network" {
  variables {
    name     = "${run.setup.name}-02"
    location = "uksouth"
  }
  module {
    source = "../network"
  }
}

run "e2e_keyvault_pep" {
  variables {
    name                   = run.setup.name
    location               = "uksouth"
    engine_app_id          = "00000000-0000-0000-0000-000000000000"
    engine_secret          = "none"
    public_access_keyvault = {}
    public_access_webapp   = {}
    public_access_cosmos   = {}
    private_endpoint_keyvault = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1001
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_keyvault.id
      private_ip_address  = "192.168.0.55"
    }
  }
  module {
    source = "../../"
  }
}

run "e2e_cosmos_pep" {
  variables {
    name                   = run.setup.name
    location               = "uksouth"
    engine_app_id          = "00000000-0000-0000-0000-000000000000"
    engine_secret          = "none"
    public_access_keyvault = {}
    public_access_webapp   = {}
    private_endpoint_keyvault = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1001
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_keyvault.id
      private_ip_address  = "192.168.0.55"
    }
    private_endpoint_cosmos = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1002
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_cosmos.id
      private_ip_address  = ["192.168.0.56", "192.168.0.57"]
    }
  }
  module {
    source = "../../"
  }
}

run "e2e_webapp_pep" {
  variables {
    name                   = run.setup.name
    location               = "uksouth"
    engine_app_id          = "00000000-0000-0000-0000-000000000000"
    engine_secret          = "none"
    public_access_keyvault = {}

    private_endpoint_keyvault = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1001
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_keyvault.id
      private_ip_address  = "192.168.0.55"
    }
    private_endpoint_cosmos = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1002
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_cosmos.id
      private_ip_address  = ["192.168.0.56", "192.168.0.57"]
    }
    private_endpoint_webapp = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1003
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_webapp.id
      private_ip_address  = "192.168.0.58"
    }
  }
  module {
    source = "../../"
  }
}

run "e2e_integrated" {
  variables {
    name                   = run.setup.name
    location               = "uksouth"
    engine_app_id          = "00000000-0000-0000-0000-000000000000"
    engine_secret          = "none"
    public_access_keyvault = {}
    public_access_webapp   = {}
    public_access_cosmos   = {}
    private_endpoint_keyvault = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1001
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_keyvault.id
      private_ip_address  = "192.168.0.55"
    }
    private_endpoint_cosmos = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1002
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_cosmos.id
      private_ip_address  = ["192.168.0.56", "192.168.0.57"]
    }
    private_endpoint_webapp = {
      subnet_id = run.network.snet1.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1003
        source_address_prefix = run.network.snet2.address_prefixes[0]
      }
      private_dns_zone_id = run.network.pdns_webapp.id
      private_ip_address  = "192.168.0.58"
    }
    virtual_network_integration = {
      subnet_id = run.network.snet2.id
      nsg = {
        name                  = run.network.nsg.name
        resource_group_name   = run.network.nsg.resource_group_name
        starting_priority     = 1100
        subnet_address_prefix = run.network.snet2.address_prefixes[0]
      }
    }
  }
  module {
    source = "../../"
  }
}
