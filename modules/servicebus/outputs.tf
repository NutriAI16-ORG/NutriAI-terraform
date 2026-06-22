output "namespace_id" {
  value       = azurerm_servicebus_namespace.sb.id
  description = "The ID of the Service Bus Namespace"
}

output "namespace_name" {
  value       = azurerm_servicebus_namespace.sb.name
  description = "The name of the Service Bus Namespace"
}

output "namespace_fqdn" {
  value       = "${azurerm_servicebus_namespace.sb.name}.servicebus.windows.net"
  description = "The FQDN of the Service Bus Namespace"
}

output "topic_name" {
  value       = azurerm_servicebus_topic.topic.name
  description = "The name of the Service Bus Topic"
}

output "subscription_name" {
  value       = azurerm_servicebus_subscription.sub.name
  description = "The name of the Service Bus Subscription"
}
