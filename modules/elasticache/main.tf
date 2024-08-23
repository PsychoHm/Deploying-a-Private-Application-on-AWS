terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_parameter_group" "redis7" {
  family = "redis7"
  name   = "redis7-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "myapp-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis7.name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.security_group_id]
}