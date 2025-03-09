# Main Terraform configuration file for Amira Wellness infrastructure

# Configure Terraform and required providers
terraform {
  required_version = "~> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration would be environment-specific
  # backend "s3" {
  #   bucket         = "amira-wellness-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# Primary region provider
provider "aws" {
  region = var.primary_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Secondary region provider for cross-region resources (EU users)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Tertiary region provider for Latin American users
provider "aws" {
  alias  = "tertiary"
  region = var.tertiary_region
  
  default_tags {
    tags = local.common_tags
  }
}

# US-East-1 provider for CloudFront certificates (required region for CloudFront ACM)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  
  default_tags {
    tags = local.common_tags
  }
}

# Common tags to apply to all resources
locals {
  common_tags = {
    Project     = "AmiraWellness"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Get available availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Networking module - Creates the VPC, subnets, security groups, and network infrastructure
module "networking" {
  source = "./modules/networking"
  
  environment        = var.environment
  region             = var.primary_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  app_port           = var.app_port
  tags               = var.tags
}

# Security module - Creates KMS keys, Cognito user pools, IAM roles, and security configurations
module "security" {
  source = "./modules/security"
  
  environment               = var.environment
  region                    = var.primary_region
  vpc_id                    = module.networking.vpc_id
  cognito_user_pool_name    = var.cognito_user_pool_name
  cognito_auto_verify_email = var.cognito_auto_verify_email
  cognito_mfa_configuration = var.cognito_mfa_configuration
  waf_enabled               = var.waf_enabled
  shield_enabled            = var.shield_enabled
  tags                      = var.tags
}

# Storage module - Creates S3 buckets for audio storage with encryption and replication
module "storage" {
  source = "./modules/storage"
  
  environment         = var.environment
  region              = var.primary_region
  secondary_region    = var.secondary_region
  kms_key_id          = module.security.kms_key_id
  audio_bucket_name   = var.s3_audio_bucket_name
  versioning_enabled  = var.s3_versioning_enabled
  replication_enabled = var.s3_replication_enabled
  tags                = var.tags
  
  providers = {
    aws.secondary = aws.secondary
  }
}

# Database module - Creates RDS PostgreSQL, DocumentDB, and ElastiCache Redis instances
module "database" {
  source = "./modules/database"
  
  environment                = var.environment
  region                     = var.primary_region
  vpc_id                     = module.networking.vpc_id
  data_subnet_ids            = module.networking.data_subnet_ids
  db_security_group_id       = module.networking.db_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_multi_az                = var.db_multi_az
  db_backup_retention_period = var.backup_retention_period
  redis_node_type            = var.redis_node_type
  redis_num_cache_nodes      = var.redis_num_cache_nodes
  tags                       = var.tags
}

# Compute module - Creates ECS clusters, services, and load balancers for application deployment
module "compute" {
  source = "./modules/compute"
  
  environment                = var.environment
  region                     = var.primary_region
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  public_subnet_ids          = module.networking.public_subnet_ids
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  app_name                   = var.app_name
  app_image                  = var.app_image
  app_count                  = var.app_count
  app_port                   = var.app_port
  fargate_cpu                = var.fargate_cpu
  fargate_memory             = var.fargate_memory
  alb_security_group_id      = module.networking.alb_security_group_id
  app_security_group_id      = module.networking.app_security_group_id
  enable_autoscaling         = true
  min_capacity               = 2
  max_capacity               = 10
  cpu_scale_out_threshold    = var.alarm_cpu_threshold
  memory_scale_out_threshold = var.alarm_memory_threshold
  alarm_evaluation_periods   = var.alarm_evaluation_periods
  enable_monitoring          = var.enable_monitoring
  tags                       = var.tags
}

# CloudFront origin access identity for S3 access
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for Amira Wellness content"
}

# ACM certificate for CloudFront distribution
resource "aws_acm_certificate" "cdn_cert" {
  provider          = aws.us-east-1
  domain_name       = "cdn.${var.domain_name}"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(local.common_tags, var.tags)
}

# CloudFront distribution for content delivery
resource "aws_cloudfront_distribution" "content_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Content distribution for Amira Wellness"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = ["cdn.${var.domain_name}"]
  
  origin {
    domain_name = module.storage.audio_bucket_domain_name
    origin_id   = "S3-${module.storage.audio_bucket_name}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${module.storage.audio_bucket_name}"
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  web_acl_id = var.waf_enabled ? module.security.waf_web_acl_arn : null
  
  tags = merge(local.common_tags, var.tags)
}

# Policy for S3 content bucket to allow CloudFront access
resource "aws_s3_bucket_policy" "content_bucket_policy" {
  bucket = module.storage.audio_bucket_name
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal",
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action    = "s3:GetObject",
        Resource  = "${module.storage.audio_bucket_arn}/*"
      }
    ]
  })
}

# Route53 record for API endpoint
resource "aws_route53_record" "api_dns" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = module.compute.alb_dns_name
    zone_id                = module.compute.alb_zone_id
    evaluate_target_health = true
  }
}

# Route53 record for CDN endpoint
resource "aws_route53_record" "cdn_dns" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "cdn.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.content_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.content_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudWatch dashboard for monitoring the application
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Amira-Wellness-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${module.compute.ecs_service_name}", "ClusterName", "${module.compute.ecs_cluster_name}"]
          ],
          period = 300,
          stat   = "Average",
          region = "${var.primary_region}",
          title  = "ECS CPU Utilization"
        }
      },
      {
        type = "metric",
        x    = 12,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${module.compute.ecs_service_name}", "ClusterName", "${module.compute.ecs_cluster_name}"]
          ],
          period = 300,
          stat   = "Average",
          region = "${var.primary_region}",
          title  = "ECS Memory Utilization"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${module.compute.alb_arn}"]
          ],
          period = 300,
          stat   = "Sum",
          region = "${var.primary_region}",
          title  = "ALB Request Count"
        }
      },
      {
        type = "metric",
        x    = 12,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${module.compute.alb_arn}"],
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", "${module.compute.alb_arn}"]
          ],
          period = 300,
          stat   = "Sum",
          region = "${var.primary_region}",
          title  = "ALB Error Codes"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.environment}-postgresql"]
          ],
          period = 300,
          stat   = "Average",
          region = "${var.primary_region}",
          title  = "RDS CPU Utilization"
        }
      },
      {
        type = "metric",
        x    = 12,
        y    = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", "${var.environment}-redis-001"]
          ],
          period = 300,
          stat   = "Average",
          region = "${var.primary_region}",
          title  = "ElastiCache CPU Utilization"
        }
      }
    ]
  })
}