output "redis_primary_connection_string" {
  value       = "rediss://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port}/0"
  sensitive   = true
  description = "The primary connection string of the Redis cache"
}

output "redis_hostname" {
  value       = azurerm_redis_cache.redis.hostname
  description = "The hostname of the Redis cache"
}

output "redis_primary_access_key" {
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
  description = "The primary access key of the Redis cache"
}
