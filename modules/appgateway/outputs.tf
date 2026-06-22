output "app_gateway_id" {
  value       = azurerm_application_gateway.appgw.id
  description = "The ID of the Application Gateway"
}

output "app_gateway_name" {
  value       = azurerm_application_gateway.appgw.name
  description = "The name of the Application Gateway"
}

output "public_ip_address_id" {
  value       = azurerm_public_ip.appgw_pip.id
  description = "The resource ID of the Application Gateway Public IP"
}

output "public_ip_address" {
  value       = azurerm_public_ip.appgw_pip.ip_address
  description = "The Public IP address of the Application Gateway"
}
