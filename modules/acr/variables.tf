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

variable "acr_name" {
  type        = string
  description = "Name of the Azure Container Registry"
}

variable "aks_kubelet_identity_object_id" {
  type        = string
  description = "The principal ID of the AKS kubelet identity for AcrPull assignment"
}
