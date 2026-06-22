output "workload_identity_client_id" {
  value       = module.identity.workload_identity_client_id
  description = "The Client ID of the User Assigned Managed Identity for Workload Identity"
}

output "workload_identity_tenant_id" {
  value       = var.entra_tenant_id
  sensitive   = true
  description = "The Tenant ID of the Entra Directory"
}

output "service_bus_namespace" {
  value       = module.servicebus.namespace_name
  description = "The name of the Service Bus namespace"
}

output "service_bus_fqdn" {
  value       = module.servicebus.namespace_fqdn
  description = "The FQDN of the Service Bus namespace"
}

output "service_bus_topic" {
  value       = module.servicebus.topic_name
  description = "The name of the Service Bus topic"
}

output "service_bus_subscription" {
  value       = module.servicebus.subscription_name
  description = "The name of the Service Bus subscription"
}

output "postgres_fqdn" {
  value       = module.postgres.postgres_fqdn
  description = "The FQDN of the PostgreSQL database server"
}

output "keyvault_name" {
  value       = var.keyvault_name
  description = "The name of the Key Vault"
}

output "appgw_public_ip" {
  value       = module.appgateway.public_ip_address
  description = "The Public IP of the Application Gateway"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "The login server for the Azure Container Registry"
}
