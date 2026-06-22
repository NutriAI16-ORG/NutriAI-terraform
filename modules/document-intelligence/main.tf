resource "azurerm_cognitive_account" "doc_intel" {
  name                          = var.account_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "FormRecognizer"
  sku_name                      = "S0"
  public_network_access_enabled = false
  custom_subdomain_name         = var.account_name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_private_endpoint" "doc_intel_pe" {
  name                = "doc-intel-private-endpoint-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id

  private_service_connection {
    name                           = "doc-intel-privatelink-conn-${var.environment}"
    private_connection_resource_id = azurerm_cognitive_account.doc_intel.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "doc-intel-dns-zone-group-${var.environment}"
    private_dns_zone_ids = [var.cognitive_dns_zone_id]
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
