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

variable "namespace_name" {
  type        = string
  description = "Name of the Service Bus Namespace"
}

variable "topic_name" {
  type        = string
  description = "Name of the Service Bus Topic"
  default     = "email-notifications"
}

variable "subscription_name" {
  type        = string
  description = "Name of the Service Bus Subscription"
  default     = "email-sender"
}

variable "workload_identity_principal_id" {
  type        = string
  description = "The principal ID of the Workload Managed Identity for RBAC role assignments"
}

variable "enable_role_assignments" {
  type    = bool
  default = true
}
