resource "azurerm_cognitive_account" "openai" {
  name                          = var.account_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "AIServices"
  sku_name                      = "S0"
  public_network_access_enabled = false
  custom_subdomain_name         = var.account_name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_cognitive_deployment" "openai_model" {
  name                 = var.openai_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  sku {
    name = "Standard"
  }
}

resource "azurerm_private_endpoint" "openai_pe" {
  name                = "openai-private-endpoint-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id

  private_service_connection {
    name                           = "openai-privatelink-conn-${var.environment}"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "openai-dns-zone-group-${var.environment}"
    private_dns_zone_ids = [var.cognitive_dns_zone_id]
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }

  depends_on = [
    azurerm_cognitive_deployment.openai_model
  ]
}
