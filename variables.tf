variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., dev, prod)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to contain all resources"
  default     = "nutriai-rg"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
  default     = "East US"
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the virtual network"
  default     = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  type        = map(string)
  description = "CIDR blocks for individual subnets"
  default = {
    appgw     = "10.0.1.0/24"
    aks       = "10.0.2.0/24"
    database  = "10.0.3.0/24"
    endpoints = "10.0.4.0/24"
    vm        = "10.0.5.0/24"
    bastion   = "10.0.6.0/26"
  }
}

variable "postgres_admin_user" {
  type        = string
  description = "Administrator login username for PostgreSQL Flexible Server"
  default     = "nutriai_admin"
}

variable "postgres_admin_password" {
  type        = string
  description = "Administrator login password for PostgreSQL Flexible Server"
  sensitive   = true
}

variable "vm_admin_password" {
  type        = string
  description = "Administrator password for VM authentication"
  sensitive   = true
}

variable "vm_size" {
  type        = string
  description = "Virtual machine size for build/docker host"
  default     = "Standard_D2s_v3"
}

variable "keyvault_name" {
  type        = string
  description = "Name of the Azure Key Vault"
}

variable "acr_name" {
  type        = string
  description = "Name of the Azure Container Registry"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS Cluster"
}

variable "smtp_username" {
  type        = string
  description = "SMTP username for sending notifications"
  sensitive   = true
}

variable "smtp_password" {
  type        = string
  description = "SMTP password/token for authentication"
  sensitive   = true
}

variable "openai_model_name" {
  type        = string
  description = "OpenAI model to deploy"
  default     = "gpt-5.1"
}

variable "openai_model_version" {
  type        = string
  description = "OpenAI model version"
  default     = "2025-11-13"
}

variable "entra_tenant_id" {
  type        = string
  description = "Tenant ID of the existing Microsoft Entra App Registration"
  sensitive   = true
}

variable "entra_client_id" {
  type        = string
  description = "Client ID of the existing Microsoft Entra App Registration"
  sensitive   = true
}

variable "entra_client_secret" {
  type        = string
  description = "Client Secret of the existing Microsoft Entra App Registration"
  sensitive   = true
}

variable "entra_redirect_uri" {
  type        = string
  description = "Redirect URI of the existing Microsoft Entra App Registration"
  sensitive   = true
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Storage Account for app data (managed by Terraform)"
}

variable "storage_container_name" {
  type        = string
  description = "Name of the Storage Container for app data (managed by Terraform)"
  default     = "nutriai-app-data"
}

variable "enable_role_assignments" {
  type        = bool
  description = "Whether to create RBAC role assignments (disable if service principal lacks Owner permissions)"
  default     = true
}

variable "aks_vm_size" {
  type        = string
  description = "Virtual machine size for the AKS cluster nodes"
  default     = "Standard_D2ads_v6"
}

variable "redis_password" {
  type        = string
  description = "Password for self-hosted Redis cache"
  sensitive   = true
}


