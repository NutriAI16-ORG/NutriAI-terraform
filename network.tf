# ==============================================================================
# Network — VNet (Azure Verified Module, direct) + Custom Resources
# ==============================================================================

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name          = "nutriai-vnet-${var.environment}"
  parent_id     = azurerm_resource_group.rg.id
  location      = azurerm_resource_group.rg.location
  address_space = [var.vnet_cidr]

  subnets = {
    appgw = {
      name             = "appgw-subnet"
      address_prefixes = [var.subnet_prefixes["appgw"]]
    }
    aks = {
      name             = "aks-subnet"
      address_prefixes = [var.subnet_prefixes["aks"]]
    }
    database = {
      name             = "db-subnet"
      address_prefixes = [var.subnet_prefixes["database"]]
      delegations = [{
        name = "postgres-delegation"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
    endpoints = {
      name             = "ep-subnet"
      address_prefixes = [var.subnet_prefixes["endpoints"]]
    }
    vm = {
      name             = "vm-subnet"
      address_prefixes = [var.subnet_prefixes["vm"]]
      nat_gateway = {
        id = azurerm_nat_gateway.nat.id
      }
    }
    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.subnet_prefixes["bastion"]]
    }
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

# ------------------------------------------------------------------------------
# NAT Gateway (for VM outbound access)
# ------------------------------------------------------------------------------

resource "azurerm_public_ip" "nat_pip" {
  name                = "nutriai-nat-pip-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nutriai-nat-gw-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}


# ------------------------------------------------------------------------------
# Network Security Groups
# ------------------------------------------------------------------------------

resource "azurerm_network_security_group" "appgw" {
  name                = "nutriai-appgw-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  #tfsec:ignore:azure-network-no-public-ingress
  security_rule {
    name                       = "Allow_HTTP_HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nutriai-aks-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_AppGW_Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_prefixes["appgw"]
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_network_security_group" "db" {
  name                = "nutriai-db-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_AKS_Postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.subnet_prefixes["aks"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny_All_Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_network_security_group" "endpoints" {
  name                = "nutriai-ep-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_AKS_Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_prefixes["aks"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_VM_Internal"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_prefixes["vm"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny_Public_Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_network_security_group" "vm" {
  name                = "nutriai-vm-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Bastion_SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_prefixes["bastion"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny_All_Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

# ------------------------------------------------------------------------------
# NSG Associations
# ------------------------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = module.vnet.subnets["appgw"].resource_id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg" {
  subnet_id                 = module.vnet.subnets["aks"].resource_id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = module.vnet.subnets["database"].resource_id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_subnet_network_security_group_association" "endpoints" {
  subnet_id                 = module.vnet.subnets["endpoints"].resource_id
  network_security_group_id = azurerm_network_security_group.endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = module.vnet.subnets["vm"].resource_id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------

resource "azurerm_route_table" "aks_rt" {
  name                = "nutriai-aks-rt-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_subnet_route_table_association" "aks_rt" {
  subnet_id      = module.vnet.subnets["aks"].resource_id
  route_table_id = azurerm_route_table.aks_rt.id
}

resource "azurerm_subnet_route_table_association" "appgw_rt" {
  subnet_id      = module.vnet.subnets["appgw"].resource_id
  route_table_id = azurerm_route_table.aks_rt.id
}
