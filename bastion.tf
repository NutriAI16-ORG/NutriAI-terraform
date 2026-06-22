# ==============================================================================
# Bastion — Public IP + Azure Verified Module (direct)
# ==============================================================================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "nutriai-bastion-pip-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.3"

  name               = "nutriai-bastion-${var.environment}"
  parent_id          = azurerm_resource_group.rg.id
  location           = azurerm_resource_group.rg.location
  copy_paste_enabled = true
  sku                = "Standard"

  ip_configuration = {
    name                 = "bastion-ip-config"
    subnet_id            = module.vnet.subnets["bastion"].resource_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
