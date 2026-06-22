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

variable "database_subnet_id" {
  type        = string
  description = "The ID of the delegated database subnet"
}

variable "vnet_id" {
  type        = string
  description = "The ID of the virtual network for DNS linking"
}

variable "admin_user" {
  type        = string
  description = "PostgreSQL administrator login user"
  default     = "nutriai_admin"
}

variable "admin_password" {
  type        = string
  description = "PostgreSQL administrator login password"
  sensitive   = true
}

variable "backup_retention_days" {
  type        = number
  description = "The backup retention days for the database server"
  default     = 7
}
