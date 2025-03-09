# Environment Configuration
environment         = "staging"
primary_region      = "us-east-1"
secondary_region    = "eu-west-1"
tertiary_region     = "sa-east-1"
domain_name         = "staging.amirawellness.com"
route53_zone_id     = "Z0123456789ABCDEFGHIJ"

# Networking
vpc_cidr                = "10.0.0.0/16"
availability_zones_count = 2

# Application Configuration
app_name        = "amira-wellness"
app_image       = "amira-wellness/backend:staging"
app_port        = 8000
app_count       = 2
fargate_cpu     = 1024  # 1 vCPU
fargate_memory  = 2048  # 2GB
health_check_path = "/api/health"

# Database Configuration
db_username         = "amira_admin"
db_password         = "StagingSecurePassword456!"  # Should be replaced with secure value in actual deployment
db_name             = "amira_wellness_staging"
db_instance_class   = "db.t3.medium"
db_allocated_storage = 50
db_multi_az         = true

# Redis ElastiCache Configuration
redis_node_type       = "cache.t3.small"
redis_num_cache_nodes = 2

# S3 Storage Configuration
s3_audio_bucket_name  = "amira-wellness-audio-staging"
s3_versioning_enabled = true
s3_replication_enabled = true

# CloudFront Configuration
cloudfront_price_class = "PriceClass_100"  # North America and Europe only

# Cognito Configuration
cognito_user_pool_name  = "amira-wellness-users-staging"
cognito_auto_verify_email = true
cognito_mfa_configuration = "OPTIONAL"

# Security Configuration
waf_enabled    = true
shield_enabled = true

# Backup and Recovery
backup_retention_period = 7  # days

# Monitoring and Alerting
enable_monitoring      = true
alarm_cpu_threshold    = 70
alarm_memory_threshold = 75
alarm_evaluation_periods = 3

# Resource Tags
tags = {
  Project     = "AmiraWellness"
  Environment = "staging"
  ManagedBy   = "Terraform"
  CostCenter  = "PreProduction"
}