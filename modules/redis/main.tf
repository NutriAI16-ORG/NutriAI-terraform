resource "azurerm_managed_redis" "redis" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Balanced_B1"

  default_database {
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
