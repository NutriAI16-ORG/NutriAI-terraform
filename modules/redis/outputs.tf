output "redis_primary_connection_string" {
  value       = "rediss://:${azurerm_managed_redis.redis.default_database[0].primary_access_key}@${azurerm_managed_redis.redis.hostname}:6380/0"
  sensitive   = true
  description = "The primary connection string of the Redis cache"
}

output "redis_hostname" {
  value       = azurerm_managed_redis.redis.hostname
  description = "The hostname of the Redis cache"
}

output "redis_primary_access_key" {
  value       = azurerm_managed_redis.redis.default_database[0].primary_access_key
  sensitive   = true
  description = "The primary access key of the Redis cache"
}
