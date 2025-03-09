# Environment Configuration
environment = "prod"
primary_region = "us-east-1"
secondary_region = "eu-west-1"
tertiary_region = "sa-east-1"
domain_name = "amirawellness.com"
route53_zone_id = "Z0123456789ABCDEFGHIJ"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones_count = 3

# Application Configuration
app_name = "amira-wellness"
app_image = "amira-wellness/backend:latest"
app_port = 8000
app_count = 4
fargate_cpu = 2048    # 2 vCPU
fargate_memory = 4096 # 4 GB
health_check_path = "/api/health"

# Database Configuration
db_username = "amira_admin"
db_password = "ProdSecurePassword789!" # Note: In production, use AWS Secrets Manager or similar
db_name = "amira_wellness_prod"
db_instance_class = "db.t3.large"
db_allocated_storage = 100
db_multi_az = true

# Caching Configuration
redis_node_type = "cache.t3.medium"
redis_num_cache_nodes = 3

# Storage Configuration
s3_audio_bucket_name = "amira-wellness-audio-prod"
s3_versioning_enabled = true
s3_replication_enabled = true

# CDN Configuration
cloudfront_price_class = "PriceClass_200" # North America, Europe, Asia, Middle East, and Africa

# Authentication Configuration
cognito_user_pool_name = "amira-wellness-users-prod"
cognito_auto_verify_email = true
cognito_mfa_configuration = "OPTIONAL"

# Security Configuration
waf_enabled = true
shield_enabled = true

# Monitoring and Backup Configuration
backup_retention_period = 30
enable_monitoring = true
alarm_cpu_threshold = 70
alarm_memory_threshold = 70
alarm_evaluation_periods = 3

# Resource Tagging
tags = {
  Project     = "AmiraWellness"
  Environment = "prod"
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
}