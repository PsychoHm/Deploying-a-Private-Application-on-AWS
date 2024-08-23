output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "The endpoint of the ElastiCache Redis cluster"
}

output "cluster_id" {
  value       = aws_elasticache_cluster.redis.id
  description = "The ID of the ElastiCache cluster"
}