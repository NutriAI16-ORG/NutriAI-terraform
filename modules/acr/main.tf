resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  admin_enabled                 = true
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_role_assignment" "aks_acrpull" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_object_id
}
