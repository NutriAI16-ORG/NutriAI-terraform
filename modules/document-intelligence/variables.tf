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

variable "account_name" {
  type        = string
  description = "Name of the Document Intelligence Account"
}

variable "endpoints_subnet_id" {
  type        = string
  description = "ID of the subnet hosting private endpoints"
}

variable "cognitive_dns_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone for Cognitive Services"
}
