resource "azurerm_servicebus_namespace" "sb" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_servicebus_topic" "topic" {
  name         = var.topic_name
  namespace_id = azurerm_servicebus_namespace.sb.id
}

resource "azurerm_servicebus_subscription" "sub" {
  name               = var.subscription_name
  topic_id           = azurerm_servicebus_topic.topic.id
  max_delivery_count = 10
}

# Role Assignments for Workload Identity
resource "azurerm_role_assignment" "sb_sender" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = var.workload_identity_principal_id
}

resource "azurerm_role_assignment" "sb_receiver" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.workload_identity_principal_id
}
