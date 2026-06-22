# ==============================================================================
# Import blocks — prod-only orphaned diagnostic settings
# These two resources were created in a previous partial apply run but were
# never saved to state before the pipeline errored. On the next apply Terraform
# will import them automatically (Terraform 1.5+) and then no-op on them.
#
# IMPORTANT: Remove these import blocks after the first successful apply that
# shows 0 to add / 0 to destroy for these two resources, otherwise they will
# error on subsequent runs once the resource is already in state.
# ==============================================================================

import {
  id = "/subscriptions/34c41824-bb7a-4316-af37-2597f35b730e/resourceGroups/nutriai-rg-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/nutriai-postgres-prod|postgres-diagnostics"
  to = azurerm_monitor_diagnostic_setting.postgres
}

import {
  id = "/subscriptions/34c41824-bb7a-4316-af37-2597f35b730e/resourceGroups/nutriai-rg-prod/providers/Microsoft.Storage/storageAccounts/nutriaistgprod/blobServices/default|storage-diagnostics"
  to = azurerm_monitor_diagnostic_setting.storage
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "nutriai-law-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_application_insights" "appinsights" {
  name                = "nutriai-appinsights-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "nutriai-prom-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                          = "nutriai-grafana-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  grafana_major_version         = "12"
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

# Role assignments for Grafana System Identity
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = var.resource_group_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

resource "azurerm_role_assignment" "grafana_metrics_reader" {
  count                = var.enable_role_assignments ? 1 : 0
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

# Prometheus Data Collection Rule (DCR)
resource "azurerm_monitor_data_collection_rule" "prometheus_dcr" {
  name                = "nutriai-prom-dcr-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = "PrometheusWorkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["PrometheusWorkspace"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = "NutriAI"
  }
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus_dcra" {
  name                    = "nutriai-prom-dcra-${var.environment}"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus_dcr.id
}

# --- Diagnostic Settings Fan-Out ---

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-diagnostics"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "kube-apiserver"
  }
  enabled_log {
    category = "kube-audit"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "kv-diagnostics"
  target_resource_id         = var.keyvault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "postgres-diagnostics"
  target_resource_id         = var.postgres_server_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "sb-diagnostics"
  target_resource_id         = var.servicebus_namespace_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diagnostics"
  target_resource_id         = "${var.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "appgw-diagnostics"
  target_resource_id         = var.appgw_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
