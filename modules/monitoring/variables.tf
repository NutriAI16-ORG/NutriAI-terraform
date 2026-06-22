variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group for Grafana role assignment scope"
}

variable "aks_cluster_id" {
  type        = string
  description = "ID of the AKS cluster"
  default     = null
}

variable "keyvault_id" {
  type        = string
  description = "ID of the Key Vault"
  default     = null
}

variable "postgres_server_id" {
  type        = string
  description = "ID of the PostgreSQL Flexible Server"
  default     = null
}

variable "servicebus_namespace_id" {
  type        = string
  description = "ID of the Service Bus namespace"
  default     = null
}

variable "storage_account_id" {
  type        = string
  description = "ID of the manually created Storage Account"
  default     = null
}

variable "appgw_id" {
  type        = string
  description = "ID of the Application Gateway"
  default     = null
}

variable "enable_role_assignments" {
  type    = bool
  default = true
}
