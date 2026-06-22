output "doc_intel_endpoint" {
  value       = azurerm_cognitive_account.doc_intel.endpoint
  description = "The endpoint of the Document Intelligence resource"
}

output "doc_intel_primary_key" {
  value       = azurerm_cognitive_account.doc_intel.primary_access_key
  sensitive   = true
  description = "The primary key of the Document Intelligence resource"
}
