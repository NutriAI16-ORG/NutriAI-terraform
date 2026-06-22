output "aks_cluster_identity_id" {
  value       = azurerm_user_assigned_identity.aks_cluster.id
  description = "The ID of the user assigned identity for AKS"
}

output "aks_cluster_identity_principal_id" {
  value       = azurerm_user_assigned_identity.aks_cluster.principal_id
  description = "The principal ID of the user assigned identity for AKS"
}

output "aks_cluster_identity_client_id" {
  value       = azurerm_user_assigned_identity.aks_cluster.client_id
  description = "The client ID of the user assigned identity for AKS"
}

output "workload_identity_id" {
  value       = azurerm_user_assigned_identity.aks_workload.id
  description = "The ID of the user assigned identity for application workload identity"
}

output "workload_identity_principal_id" {
  value       = azurerm_user_assigned_identity.aks_workload.principal_id
  description = "The principal ID of the user assigned identity for application workload identity"
}

output "workload_identity_client_id" {
  value       = azurerm_user_assigned_identity.aks_workload.client_id
  description = "The client ID of the user assigned identity for application workload identity"
}
