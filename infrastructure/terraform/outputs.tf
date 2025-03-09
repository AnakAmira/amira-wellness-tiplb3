# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "data_subnet_ids" {
  description = "IDs of the data subnets"
  value       = module.networking.data_subnet_ids
}

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group"
  value       = module.networking.alb_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.networking.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.networking.db_security_group_id
}

# Security outputs
output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = module.security.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = module.security.kms_key_arn
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.security.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito user pool client"
  value       = module.security.cognito_user_pool_client_id
}

output "cognito_user_pool_domain" {
  description = "Domain of the Cognito user pool"
  value       = module.security.cognito_user_pool_domain
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.security.ecs_task_execution_role_arn
}

output "app_role_arn" {
  description = "ARN of the application role"
  value       = module.security.app_role_arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.waf_enabled ? module.security.waf_web_acl_arn : null
}

# Storage outputs
output "audio_bucket_name" {
  description = "Name of the S3 bucket for audio storage"
  value       = module.storage.audio_bucket_name
}

output "audio_bucket_arn" {
  description = "ARN of the S3 bucket for audio storage"
  value       = module.storage.audio_bucket_arn
}

output "audio_bucket_domain_name" {
  description = "Domain name of the S3 bucket for audio storage"
  value       = module.storage.audio_bucket_domain_name
}

output "replica_audio_bucket_name" {
  description = "Name of the replica S3 bucket for audio storage"
  value       = var.s3_replication_enabled ? module.storage.replica_audio_bucket_name : null
}

output "replica_audio_bucket_arn" {
  description = "ARN of the replica S3 bucket for audio storage"
  value       = var.s3_replication_enabled ? module.storage.replica_audio_bucket_arn : null
}

# Compute outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.compute.ecs_cluster_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.compute.ecs_service_name
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the application load balancer"
  value       = module.compute.alb_zone_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.content_distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.content_distribution.hosted_zone_id
}

# Database outputs
output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance"
  value       = module.database.rds_endpoint
}

output "rds_port" {
  description = "Port of the PostgreSQL RDS instance"
  value       = module.database.rds_port
}

output "rds_database_name" {
  description = "Name of the PostgreSQL database"
  value       = module.database.rds_database_name
}

output "documentdb_endpoint" {
  description = "Endpoint of the MongoDB DocumentDB cluster"
  value       = module.database.documentdb_endpoint
}

output "documentdb_reader_endpoint" {
  description = "Reader endpoint of the MongoDB DocumentDB cluster"
  value       = module.database.documentdb_reader_endpoint
}

output "elasticache_endpoint" {
  description = "Primary endpoint of the ElastiCache Redis cluster"
  value       = module.database.elasticache_endpoint
}

output "elasticache_reader_endpoint" {
  description = "Reader endpoint of the ElastiCache Redis cluster"
  value       = module.database.elasticache_reader_endpoint
}

output "elasticache_port" {
  description = "Port of the ElastiCache Redis cluster"
  value       = module.database.elasticache_port
}

# Application endpoints
output "api_url" {
  description = "URL for the API endpoint"
  value       = var.route53_zone_id != "" ? "https://api.${var.domain_name}" : "https://${module.compute.alb_dns_name}"
}

output "cdn_url" {
  description = "URL for the CDN endpoint"
  value       = var.route53_zone_id != "" ? "https://cdn.${var.domain_name}" : "https://${aws_cloudfront_distribution.content_distribution.domain_name}"
}

# Environment information
output "environment" {
  description = "Deployment environment (dev, staging, prod)"
  value       = var.environment
}

output "primary_region" {
  description = "Primary AWS region for deployment"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Secondary AWS region for disaster recovery and European users"
  value       = var.secondary_region
}

output "tertiary_region" {
  description = "Tertiary AWS region for Latin American users"
  value       = var.tertiary_region
}