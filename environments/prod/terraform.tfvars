# =============================================================
# NutriAI — Production Environment Variables
# =============================================================
# SAFE TO COMMIT — no sensitive values in this file.
# Sensitive values (postgres_admin_password, vm_admin_password,
# smtp_password, etc.) are injected at pipeline runtime from
# GitHub Secrets.
# =============================================================

environment             = "prod"
resource_group_name     = "nutriai-rg-prod"
location                = "East US 2"
enable_role_assignments = true

# Networking
vnet_cidr = "10.1.0.0/16"
subnet_prefixes = {
  appgw     = "10.1.1.0/24"
  aks       = "10.1.2.0/24"
  database  = "10.1.3.0/24"
  endpoints = "10.1.4.0/24"
  vm        = "10.1.5.0/24"
  bastion   = "10.1.6.0/26"
}

# PostgreSQL
postgres_admin_user = "nutriai_admin"
# postgres_admin_password → injected from GitHub Secrets at pipeline runtime

# Jump VM
vm_size = "Standard_D2alds_v6"
# vm_admin_password → injected from GitHub Secrets at pipeline runtime

# Resource naming
keyvault_name    = "nutriai-kv-prod-v3"
acr_name         = "nutriaiacrprod"
aks_cluster_name = "nutriai-aks-prod"

# SMTP & Entra ID configuration values (smtp_username, smtp_password, entra_tenant_id, entra_client_id, entra_client_secret, entra_redirect_uri) are sensitive and injected from GitHub Secrets at pipeline runtime.

# AI models
openai_model_name    = "gpt-5.1"
openai_model_version = "2025-11-13"


# Storage Account (for app blob data)
storage_account_name   = "nutriaistgprodv3"
storage_container_name = "nutriai-app-data"
