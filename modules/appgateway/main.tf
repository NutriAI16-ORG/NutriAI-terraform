resource "azurerm_public_ip" "appgw_pip" {
  name                = "nutriai-appgw-pip-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

locals {
  backend_address_pool_name      = "nutriai-apgw-beap"
  frontend_port_name             = "nutriai-apgw-feport"
  frontend_ip_configuration_name = "nutriai-apgw-feip"
  http_setting_name              = "nutriai-apgw-be-htst"
  listener_name                  = "nutriai-apgw-httplstn"
  router_rule_name               = "nutriai-apgw-rtr"
  redirect_setting_name          = "nutriai-apgw-rdst"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "nutriai-appgw-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 300
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.router_rule_name
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  # Ignore changes dynamically managed by AGIC inside Kubernetes
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      frontend_port,
      probe,
      ssl_certificate,
      tags,
      url_path_map,
      redirect_configuration
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "nutriai-waf-policy-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}
