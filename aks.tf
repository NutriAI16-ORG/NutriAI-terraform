# ==============================================================================
# AKS Cluster — Azure Verified Module (direct)
# ==============================================================================

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.6.0"

  name      = var.aks_cluster_name
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location

  sku = {
    name = "Base"
    tier = "Standard"
  }

  kubernetes_version = "1.30"

  api_server_access_profile = {
    enable_private_cluster = true
    private_dns_zone       = "system"
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }

  default_agent_pool = {
    name                = "systempool"
    vm_size             = var.vm_size
    count_of            = 1
    vnet_subnet_id      = module.vnet.subnets["aks"].resource_id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 2
    os_disk_size_gb     = 30
    availability_zones  = ["1", "3"]
  }

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [module.identity.aks_cluster_identity_id]
  }

  addon_profile_key_vault_secrets_provider = {
    enabled = true
    config = {
      enable_secret_rotation = true
    }
  }

  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = module.monitoring.log_analytics_workspace_id
    }
  }

  addon_profile_ingress_application_gateway = {
    enabled = true
    config = {
      application_gateway_id = module.appgateway.app_gateway_id
    }
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

