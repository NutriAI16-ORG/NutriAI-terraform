output "openai_endpoint" {
  value       = azurerm_cognitive_account.openai.endpoint
  description = "The endpoint of the OpenAI resource"
}

output "openai_primary_key" {
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
  description = "The primary key of the OpenAI resource"
}
