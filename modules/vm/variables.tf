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

variable "vm_subnet_id" {
  type        = string
  description = "ID of the subnet hosting the VM"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM authentication"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D2s_v3"
}
