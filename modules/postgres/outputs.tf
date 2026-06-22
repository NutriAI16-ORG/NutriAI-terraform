output "postgres_id" {
  value       = azurerm_postgresql_flexible_server.postgres.id
  description = "The ID of the PostgreSQL Flexible Server"
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
  description = "The FQDN of the PostgreSQL Flexible Server"
}

output "postgres_admin_user" {
  value       = azurerm_postgresql_flexible_server.postgres.administrator_login
  description = "The administrator login username"
}

output "postgres_database_name" {
  value       = azurerm_postgresql_flexible_server_database.db.name
  description = "The name of the database created"
}
