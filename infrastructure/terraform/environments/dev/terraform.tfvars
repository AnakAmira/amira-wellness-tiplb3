# =============================================================================
# Environment and Region Configuration
# =============================================================================
environment         = "dev"
app_name            = "amira-wellness"
domain_name         = "dev.amirawellness.com"
route53_zone_id     = "Z0123456789ABCDEFGHIJ"

# AWS Regions Configuration
primary_region      = "us-east-1"      # US East (N. Virginia)
secondary_region    = "eu-west-1"      # EU West (Ireland)
tertiary_region     = "sa-east-1"      # South America (São Paulo)

# =============================================================================
# Networking Configuration
# =============================================================================
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2

# =============================================================================
# Application Configuration
# =============================================================================
app_image        = "amira-wellness/backend:dev"
app_port         = 8000
app_count        = 1                  # Reduced for development
fargate_cpu      = 512                # 0.5 vCPU
fargate_memory   = 1024               # 1GB RAM
health_check_path = "/api/health"

# =============================================================================
# Database Configuration
# =============================================================================
db_username           = "amira_admin"
db_password           = "DevPassword123!"  # Should be replaced with secure value in actual deployment
db_name               = "amira_wellness_dev"
db_instance_class     = "db.t3.small"      # Smaller instance for development
db_allocated_storage  = 20                 # GB
db_multi_az           = false              # Disabled for development to reduce costs
backup_retention_period = 3                # Days, reduced for development

# =============================================================================
# Cache Configuration
# =============================================================================
redis_node_type       = "cache.t3.micro"   # Smallest instance for development
redis_num_cache_nodes = 1                  # Single node for development

# =============================================================================
# Storage Configuration
# =============================================================================
s3_audio_bucket_name   = "amira-wellness-audio-dev"
s3_versioning_enabled  = true
s3_replication_enabled = false             # Disabled for development

# =============================================================================
# CDN and Delivery Configuration
# =============================================================================
cloudfront_price_class = "PriceClass_100"  # North America and Europe only

# =============================================================================
# Authentication Configuration
# =============================================================================
cognito_user_pool_name   = "amira-wellness-users-dev"
cognito_auto_verify_email = true
cognito_mfa_configuration = "OPTIONAL"     # Multi-factor authentication optional for development

# =============================================================================
# Security Configuration
# =============================================================================
waf_enabled   = true                       # Web Application Firewall enabled
shield_enabled = false                     # AWS Shield disabled for development

# =============================================================================
# Monitoring Configuration
# =============================================================================
enable_monitoring     = true
alarm_cpu_threshold   = 80                 # Higher threshold for development
alarm_memory_threshold = 80                # Higher threshold for development
alarm_evaluation_periods = 2

# =============================================================================
# Resource Tags
# =============================================================================
tags = {
  Project     = "AmiraWellness"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CostCenter  = "Development"
}