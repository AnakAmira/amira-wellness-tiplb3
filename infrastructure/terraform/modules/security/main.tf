# AWS Provider version ~> 5.0
# This module implements security components for the Amira Wellness application

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Local variables
locals {
  common_tags = {
    Project     = "AmiraWellness"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#-------------------------------------------------------
# KMS Key for Encryption
#-------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = "KMS key for encrypting Amira Wellness data"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for encryption",
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.app_role.arn,
            aws_iam_role.ecs_task_execution_role.arn
          ]
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-kms-key" })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.environment}-amira-wellness"
  target_key_id = aws_kms_key.main.key_id
}

#-------------------------------------------------------
# Cognito User Pool
#-------------------------------------------------------
resource "aws_cognito_user_pool" "main" {
  name = "${var.cognito_user_pool_name}-${var.environment}"
  
  username_attributes = ["email"]
  
  auto_verify {
    email = var.cognito_auto_verify_email
  }
  
  mfa_configuration = var.cognito_mfa_configuration
  
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  admin_create_user_config {
    allow_admin_create_user_only = false
    
    invite_message_template {
      email_message = "Bienvenido/a a Amira Wellness. Tu nombre de usuario es {username} y tu contraseña temporal es {####}."
      email_subject = "Tu cuenta temporal de Amira Wellness"
      sms_message   = "Bienvenido/a a Amira Wellness. Tu nombre de usuario es {username} y tu contraseña temporal es {####}."
    }
  }
  
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  password_policy {
    minimum_length                   = 10
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }
  
  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  
  schema {
    name                = "preferred_language"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }
  
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Tu código de verificación para Amira Wellness es {####}."
    email_subject        = "Código de verificación para Amira Wellness"
  }
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-cognito-user-pool" })
}

resource "aws_cognito_user_pool_client" "main" {
  name             = "amira-wellness-client-${var.environment}"
  user_pool_id     = aws_cognito_user_pool.main.id
  generate_secret  = true
  
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1
  
  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
  
  prevent_user_existence_errors = "ENABLED"
  supported_identity_providers  = ["COGNITO"]
  
  callback_urls                = ["https://api.${var.domain_name}/auth/callback"]
  logout_urls                  = ["https://api.${var.domain_name}/auth/logout"]
  allowed_oauth_flows          = ["code"]
  allowed_oauth_scopes         = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "auth-amira-wellness-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

#-------------------------------------------------------
# IAM Roles and Policies
#-------------------------------------------------------
# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-ecs-task-execution-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Application Role
resource "aws_iam_role" "app_role" {
  name = "${var.environment}-app-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-app-role" })
}

# S3 Access Policy with Encryption Requirements
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.environment}-s3-access-policy"
  description = "Policy for accessing S3 buckets with encryption requirements"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowListBuckets",
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowBucketAccess",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ],
        Resource = [
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*"
        ]
      },
      {
        Sid    = "AllowObjectOperations",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ],
        Resource = [
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*/*"
        ],
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "AllowKMSKeyUsage",
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.main.arn
      },
      {
        Sid    = "DenyUnencryptedObjectUploads",
        Effect = "Deny",
        Action = "s3:PutObject",
        Resource = [
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*/*"
        ],
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "DenyIncorrectEncryptionHeader",
        Effect = "Deny",
        Action = "s3:PutObject",
        Resource = [
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*/*"
        ],
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.main.arn
          }
        }
      },
      {
        Sid    = "EnforceSSLOnly",
        Effect = "Deny",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*",
          "arn:aws:s3:::amira-wellness-audio-${var.environment}-*/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_s3_policy_attachment" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Cognito Access Policy
resource "aws_iam_policy" "cognito_access_policy" {
  name        = "${var.environment}-cognito-access-policy"
  description = "Policy for accessing Cognito user pool"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminConfirmSignUp",
          "cognito-idp:AdminUserGlobalSignOut",
          "cognito-idp:AdminForgetDevice",
          "cognito-idp:ConfirmSignUp",
          "cognito-idp:SignUp",
          "cognito-idp:InitiateAuth",
          "cognito-idp:RespondToAuthChallenge",
          "cognito-idp:ConfirmForgotPassword",
          "cognito-idp:ForgotPassword",
          "cognito-idp:GetUser",
          "cognito-idp:UpdateUserAttributes",
          "cognito-idp:ChangePassword"
        ],
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_cognito_policy_attachment" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.cognito_access_policy.arn
}

#-------------------------------------------------------
# WAF Web ACL
#-------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  count = var.waf_enabled ? 1 : 0
  
  name        = "${var.environment}-amira-wellness-waf"
  scope       = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Rules - SQL Injection Rule Set
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Rules - Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # Rate-based rule to prevent brute force attacks
  rule {
    name     = "RateBasedRule"
    priority = 40
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-amira-wellness-waf"
    sampled_requests_enabled   = true
  }
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-waf-web-acl" })
}

#-------------------------------------------------------
# AWS Shield Protection
#-------------------------------------------------------
resource "aws_shield_protection" "alb" {
  count = var.shield_enabled ? 1 : 0
  
  name         = "${var.environment}-alb-shield-protection"
  resource_arn = var.alb_arn
}

#-------------------------------------------------------
# WAF Logging
#-------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf_logs" {
  count = var.waf_enabled ? 1 : 0
  
  name              = "/aws/waf/${var.environment}-amira-wellness-waf"
  retention_in_days = 90
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-waf-logs" })
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.waf_enabled ? 1 : 0
  
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.main[0].arn
}

#-------------------------------------------------------
# Secrets Manager for Cognito Client Secret
#-------------------------------------------------------
resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name        = "${var.environment}/amira-wellness/cognito-client-secret"
  description = "Cognito client secret for Amira Wellness application"
  kms_key_id  = aws_kms_key.main.id
  
  tags = merge(local.common_tags, var.tags, { Name = "${var.environment}-cognito-client-secret" })
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.main.client_secret
}

#-------------------------------------------------------
# Variables
#-------------------------------------------------------
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "Region must be a valid AWS region format"
  }
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------
# Outputs
#-------------------------------------------------------
output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = aws_kms_key.main.arn
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito user pool client"
  value       = aws_cognito_user_pool_client.main.id
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "app_role_arn" {
  description = "ARN of the application role"
  value       = aws_iam_role.app_role.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL"
  value       = var.waf_enabled ? aws_wafv2_web_acl.main[0].arn : ""
}