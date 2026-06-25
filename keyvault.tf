# ==============================================================================
# Key Vault — Private DNS Zone + Azure Verified Module (direct)
# ==============================================================================

resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "kv-dns-vnet-link-${var.environment}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = module.vnet.resource_id
}

module "keyvault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10"

  name                          = var.keyvault_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  public_network_access_enabled = true

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["172.200.169.205"]
  }

  private_endpoints = {
    vault = {
      name                          = "kv-private-endpoint-${var.environment}"
      subnet_resource_id            = module.vnet.subnets["endpoints"].resource_id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.kv_dns.id]
      subresource_names             = ["vault"]
    }
  }

  role_assignments = var.enable_role_assignments ? {
    workload_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.identity.workload_identity_principal_id
    }
    workload_reader = {
      role_definition_id_or_name = "Key Vault Reader"
      principal_id               = module.identity.workload_identity_principal_id
    }
    aks_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.aks.kubelet_identity.objectId
    }
    aks_reader = {
      role_definition_id_or_name = "Key Vault Reader"
      principal_id               = module.aks.kubelet_identity.objectId
    }
    deployer_secrets_officer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  } : {}

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.kv_dns_link]
}

# Grant the Jump VM's System-Assigned Managed Identity access to read Key Vault secrets
resource "azurerm_role_assignment" "vm_secrets_user" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = module.keyvault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.vm.vm_identity_principal_id
  principal_type       = "ServicePrincipal"
}

