# variables.tf - Contains all input variables for the Amira Wellness infrastructure

# Environment
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# Application
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "amira-wellness"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "amirawellness.com"
}

# Region Configuration
variable "primary_region" {
  description = "Primary AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.primary_region))
    error_message = "Primary region must be a valid AWS region format"
  }
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery and European users"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.secondary_region))
    error_message = "Secondary region must be a valid AWS region format"
  }
}

variable "tertiary_region" {
  description = "Tertiary AWS region for Latin American users"
  type        = string
  default     = "sa-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.tertiary_region))
    error_message = "Tertiary region must be a valid AWS region format"
  }
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Application Configuration
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8000
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "app_count" {
  description = "Number of application instances"
  type        = number
  default     = 2
}

variable "fargate_cpu" {
  description = "CPU units for Fargate tasks (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 1024
}

variable "fargate_memory" {
  description = "Memory for Fargate tasks in MiB"
  type        = number
  default     = 2048
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/api/health"
}

# Database Configuration
variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "amira_wellness"
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
  default     = "amira_admin"
}

variable "db_password" {
  description = "Master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the PostgreSQL RDS instance"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the PostgreSQL database in GB"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ deployment for the PostgreSQL database"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# Redis Configuration
variable "redis_node_type" {
  description = "Node type for the ElastiCache Redis cluster"
  type        = string
  default     = "cache.t3.medium"
}

variable "redis_num_cache_nodes" {
  description = "Number of nodes in the ElastiCache Redis cluster"
  type        = number
  default     = 2
}

# S3 Configuration
variable "s3_audio_bucket_name" {
  description = "Name of the S3 bucket for audio storage"
  type        = string
}

variable "s3_versioning_enabled" {
  description = "Whether to enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_replication_enabled" {
  description = "Whether to enable cross-region replication for S3 buckets"
  type        = bool
  default     = true
}

# Authentication Configuration
variable "cognito_user_pool_name" {
  description = "Name of the Cognito user pool"
  type        = string
  default     = "amira-wellness-users"
}

variable "cognito_auto_verify_email" {
  description = "Whether to auto-verify email addresses in Cognito"
  type        = bool
  default     = true
}

variable "cognito_mfa_configuration" {
  description = "MFA configuration for Cognito user pool"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "OPTIONAL", "REQUIRED"], var.cognito_mfa_configuration)
    error_message = "MFA configuration must be one of: OFF, OPTIONAL, REQUIRED"
  }
}

# Security Configuration
variable "waf_enabled" {
  description = "Whether to enable WAF for API Gateway"
  type        = bool
  default     = true
}

variable "shield_enabled" {
  description = "Whether to enable Shield for DDoS protection"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Whether to enable enhanced monitoring"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 70
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold for alarms"
  type        = number
  default     = 70
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms"
  type        = number
  default     = 3
}

# CDN Configuration
variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All"
  }
}

# DNS Configuration
variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
  default     = ""
}

# Tagging
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}