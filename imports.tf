# ==============================================================================
# imports.tf — Root-level import blocks (prod-only)
#
# Two diagnostic settings were created by a previous partial apply run but
# were never written to Terraform state before the pipeline errored.
# These import blocks bring them under state management automatically
# (requires Terraform >= 1.5).
#
# ⚠️  REMOVE THIS FILE after the first successful pipeline apply that shows
#     0 to add / 0 to destroy for these two resources.
#     Leaving it in place will cause errors on subsequent runs.
# ==============================================================================

import {
  id = "/subscriptions/34c41824-bb7a-4316-af37-2597f35b730e/resourceGroups/nutriai-rg-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/nutriai-postgres-prod|postgres-diagnostics"
  to = module.monitoring.azurerm_monitor_diagnostic_setting.postgres
}

import {
  id = "/subscriptions/34c41824-bb7a-4316-af37-2597f35b730e/resourceGroups/nutriai-rg-prod/providers/Microsoft.Storage/storageAccounts/nutriaistgprod/blobServices/default|storage-diagnostics"
  to = module.monitoring.azurerm_monitor_diagnostic_setting.storage
}
