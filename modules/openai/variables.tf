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
  description = "Name of the Azure OpenAI Account"
}

variable "endpoints_subnet_id" {
  type        = string
  description = "ID of the subnet hosting private endpoints"
}

variable "cognitive_dns_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone for Cognitive Services"
}

variable "openai_model_name" {
  type        = string
  description = "The name of the OpenAI model to deploy (e.g. gpt-5.1)"
  default     = "gpt-5.1"
}

variable "openai_model_version" {
  type        = string
  description = "The version of the OpenAI model to deploy (e.g. 2025-11-13)"
  default     = "2025-11-13"
}

variable "openai_sku_capacity" {
  type        = number
  description = "TPM capacity units for the OpenAI deployment (1 unit = 1000 tokens/min). Min 1, recommended 50+."
  default     = 50
}

variable "openai_direct_dns_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone for direct openai.azure.com"
}
