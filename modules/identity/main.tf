resource "azurerm_user_assigned_identity" "aks_cluster" {
  name                = "nutriai-aks-identity-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

# User assigned identity for application workload workload identity
resource "azurerm_user_assigned_identity" "aks_workload" {
  name                = "nutriai-workload-identity-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
