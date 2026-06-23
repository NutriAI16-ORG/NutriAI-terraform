data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

# --- Module 1: Identity ---
module "identity" {
  source              = "./modules/identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
}

# --- Module 2: Monitoring ---
module "monitoring" {
  source                  = "./modules/monitoring"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  environment             = var.environment
  resource_group_id       = azurerm_resource_group.rg.id
  aks_cluster_id          = module.aks.resource_id
  keyvault_id             = module.keyvault.resource_id
  postgres_server_id      = module.postgres.postgres_id
  servicebus_namespace_id = module.servicebus.namespace_id
  storage_account_id      = azurerm_storage_account.storage.id
  appgw_id                = module.appgateway.app_gateway_id
  enable_role_assignments = var.enable_role_assignments
}

# --- Module 3: Application Gateway ---
module "appgateway" {
  source              = "./modules/appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
  appgw_subnet_id     = module.vnet.subnets["appgw"].resource_id
}

# --- Module 4: Container Registry ---
module "acr" {
  source                         = "./modules/acr"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = azurerm_resource_group.rg.location
  environment                    = var.environment
  acr_name                       = var.acr_name
  aks_kubelet_identity_object_id = module.aks.kubelet_identity.objectId
  enable_role_assignments        = var.enable_role_assignments
}

# --- Module 5: PostgreSQL Server ---
module "postgres" {
  source              = "./modules/postgres"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
  database_subnet_id  = module.vnet.subnets["database"].resource_id
  vnet_id             = module.vnet.resource_id
  admin_user          = var.postgres_admin_user
  admin_password      = var.postgres_admin_password
}

# --- Module 6: Service Bus ---
module "servicebus" {
  source                         = "./modules/servicebus"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = azurerm_resource_group.rg.location
  environment                    = var.environment
  namespace_name                 = "nutriai-sb-${var.environment}"
  workload_identity_principal_id = module.identity.workload_identity_principal_id
  enable_role_assignments        = var.enable_role_assignments
}

# --- Shared Cognitive Services Private DNS Zone ---
resource "azurerm_private_dns_zone" "cog_dns" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "cog_dns_link" {
  name                  = "cog-dns-link-${var.environment}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cog_dns.name
  virtual_network_id    = module.vnet.resource_id
}

# --- Module 7: Azure OpenAI ---
module "openai" {
  source                = "./modules/openai"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  environment           = var.environment
  account_name          = "nutriai-openai-${var.environment}-v3"
  endpoints_subnet_id   = module.vnet.subnets["endpoints"].resource_id
  cognitive_dns_zone_id = azurerm_private_dns_zone.cog_dns.id
  openai_model_name     = var.openai_model_name
  openai_model_version  = var.openai_model_version

  depends_on = [azurerm_private_dns_zone_virtual_network_link.cog_dns_link]
}

# --- Module 8: Document Intelligence ---
module "document_intelligence" {
  source                = "./modules/document-intelligence"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  environment           = var.environment
  account_name          = "nutriai-docintel-${var.environment}-v3"
  endpoints_subnet_id   = module.vnet.subnets["endpoints"].resource_id
  cognitive_dns_zone_id = azurerm_private_dns_zone.cog_dns.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.cog_dns_link]
}

# --- Module 9: Jump VM ---
module "vm" {
  source              = "./modules/vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
  vm_subnet_id        = module.vnet.subnets["vm"].resource_id
  admin_password      = var.vm_admin_password
  vm_size             = var.vm_size
}

# --- Federated Workload Identity Credential ---
resource "azurerm_federated_identity_credential" "aks_workload_fed" {
  name                = "nutriai-k8s-federation-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_profile_issuer_url
  parent_id           = module.identity.workload_identity_id
  subject             = "system:serviceaccount:nutriai-${var.environment}:nutriai-service-account"
}

# --- Provisioning Application Storage Account and Container ---
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# --- Key Vault Secrets Provisioning ---

resource "random_string" "jwt_secret" {
  length  = 32
  special = false
}

resource "azurerm_key_vault_secret" "openai_endpoint" {
  name         = "openai-endpoint"
  value        = module.openai.openai_endpoint
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-key"
  value        = module.openai.openai_primary_key
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "doc_intel_endpoint" {
  name         = "document-intelligence-endpoint"
  value        = module.document_intelligence.doc_intel_endpoint
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "doc_intel_key" {
  name         = "document-intelligence-key"
  value        = module.document_intelligence.doc_intel_primary_key
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "postgres_host" {
  name         = "postgres-host"
  value        = module.postgres.postgres_fqdn
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "postgres_user" {
  name         = "postgres-user"
  value        = var.postgres_admin_user
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = var.postgres_admin_password
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "database_url" {
  name         = "database-url"
  value        = "postgresql://${var.postgres_admin_user}:${var.postgres_admin_password}@${module.postgres.postgres_fqdn}:5432/${module.postgres.postgres_database_name}"
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "jwt_secret_key" {
  name         = "jwt-secret-key"
  value        = random_string.jwt_secret.result
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "entra_client_id" {
  name         = "entra-client-id"
  value        = var.entra_client_id
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "entra_tenant_id" {
  name         = "entra-tenant-id"
  value        = var.entra_tenant_id
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "entra_client_secret" {
  name         = "entra-client-secret"
  value        = var.entra_client_secret
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "entra_redirect_uri" {
  name         = "entra-redirect-uri"
  value        = var.entra_redirect_uri
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "azure_storage_connection_string" {
  name         = "azure-storage-connection-string"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "azure_doc_intel_endpoint" {
  name         = "azure-document-intelligence-endpoint"
  value        = module.document_intelligence.doc_intel_endpoint
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "azure_doc_intel_key" {
  name         = "azure-document-intelligence-key"
  value        = module.document_intelligence.doc_intel_primary_key
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "azure_openai_endpoint" {
  name         = "azure-openai-endpoint"
  value        = module.openai.openai_endpoint
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "azure_openai_key" {
  name         = "azure-openai-key"
  value        = module.openai.openai_primary_key
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}


# NOTE: azure-service-bus-connection-string is intentionally NOT stored in Key Vault.
# Production uses AKS Workload Identity → DefaultAzureCredential → Azure RBAC on Service Bus.
# For local dev only: set AZURE_SERVICE_BUS_CONNECTION_STRING in your local .env file.



resource "azurerm_key_vault_secret" "smtp_username" {
  name         = "smtp-username"
  value        = var.smtp_username
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "smtp_password" {
  name         = "smtp-password"
  value        = var.smtp_password
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "applicationinsights-connection-string"
  value        = module.monitoring.application_insights_connection_string
  key_vault_id = module.keyvault.resource_id
  depends_on   = [module.keyvault]
}
