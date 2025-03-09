# AWS provider for the secondary region
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Local values for common tags and other shared configurations
locals {
  common_tags = {
    Project     = "AmiraWellness"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "Storage"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Primary S3 bucket for audio storage
resource "aws_s3_bucket" "audio_bucket" {
  bucket        = var.audio_bucket_name != null ? var.audio_bucket_name : "amira-wellness-audio-${var.environment}"
  force_destroy = false
  tags          = merge(local.common_tags, var.tags)
}

# Enable versioning for the audio bucket
resource "aws_s3_bucket_versioning" "audio_bucket_versioning" {
  bucket = aws_s3_bucket.audio_bucket.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Configure server-side encryption for the audio bucket using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "audio_bucket_encryption" {
  bucket = aws_s3_bucket.audio_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block all public access to the audio bucket
resource "aws_s3_bucket_public_access_block" "audio_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.audio_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "audio_bucket_lifecycle" {
  bucket = aws_s3_bucket.audio_bucket.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }
  }

  rule {
    id     = var.versioning_enabled ? "Enabled" : "Disabled"
    status = var.versioning_enabled ? "Enabled" : "Disabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    filter {
      prefix = ""
    }
  }
}

# Create replica S3 bucket in secondary region for disaster recovery
resource "aws_s3_bucket" "replica_audio_bucket" {
  count    = var.replication_enabled ? 1 : 0
  provider = aws.secondary
  bucket   = var.audio_bucket_name != null ? "${var.audio_bucket_name}-replica" : "amira-wellness-audio-${var.environment}-replica"

  force_destroy = false
  tags          = merge(local.common_tags, var.tags)
}

# Enable versioning for the replica bucket (required for replication)
resource "aws_s3_bucket_versioning" "replica_audio_bucket_versioning" {
  count    = var.replication_enabled ? 1 : 0
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica_audio_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for the replica bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "replica_audio_bucket_encryption" {
  count    = var.replication_enabled ? 1 : 0
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica_audio_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access to the replica bucket
resource "aws_s3_bucket_public_access_block" "replica_audio_bucket_public_access_block" {
  count                   = var.replication_enabled ? 1 : 0
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.replica_audio_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for S3 replication
resource "aws_iam_role" "replication_role" {
  count = var.replication_enabled ? 1 : 0
  name  = "amira-s3-replication-role-${var.environment}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}

# IAM policy for S3 replication
resource "aws_iam_policy" "replication_policy" {
  count = var.replication_enabled ? 1 : 0
  name  = "amira-s3-replication-policy-${var.environment}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${aws_s3_bucket.audio_bucket.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        "Resource" : [
          "${aws_s3_bucket.audio_bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        "Resource" : "${aws_s3_bucket.replica_audio_bucket[0].arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/${var.kms_key_id}",
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : "s3.${var.region}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" : "${aws_s3_bucket.audio_bucket.arn}/*"
          }
        }
      }
    ]
  })
}

# Attach the replication policy to the replication role
resource "aws_iam_role_policy_attachment" "replication_policy_attachment" {
  count      = var.replication_enabled ? 1 : 0
  role       = aws_iam_role.replication_role[0].name
  policy_arn = aws_iam_policy.replication_policy[0].arn
}

# Configure replication from primary to replica bucket
resource "aws_s3_bucket_replication_configuration" "audio_bucket_replication" {
  count  = var.replication_enabled ? 1 : 0
  bucket = aws_s3_bucket.audio_bucket.id
  role   = aws_iam_role.replication_role[0].arn

  rule {
    id     = "audio-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica_audio_bucket[0].arn
      storage_class = "STANDARD"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    filter {
      prefix = ""
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.audio_bucket_versioning,
    aws_s3_bucket_versioning.replica_audio_bucket_versioning
  ]
}

# Configure CORS for the audio bucket
resource "aws_s3_bucket_cors_configuration" "audio_bucket_cors" {
  bucket = aws_s3_bucket.audio_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["https://api.amirawellness.com", "https://amirawellness.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Configure metrics for the audio bucket
resource "aws_s3_bucket_metric" "audio_bucket_metrics" {
  bucket = aws_s3_bucket.audio_bucket.id
  name   = "EntireBucket"
}

# SNS topic for storage alerts
resource "aws_sns_topic" "storage_alerts" {
  name              = "amira-storage-alerts-${var.environment}"
  kms_master_key_id = var.kms_key_id
  tags              = merge(local.common_tags, var.tags)
}

# CloudWatch alarm for monitoring audio bucket size
resource "aws_cloudwatch_metric_alarm" "audio_bucket_size_alarm" {
  alarm_name          = "amira-audio-bucket-size-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 5000000000 # 5GB
  alarm_description   = "This alarm monitors the size of the audio bucket"

  dimensions = {
    BucketName  = aws_s3_bucket.audio_bucket.id
    StorageType = "StandardStorage"
  }

  alarm_actions             = [aws_sns_topic.storage_alerts.arn]
  insufficient_data_actions = []
  tags                      = merge(local.common_tags, var.tags)
}

# Output values
output "audio_bucket_name" {
  description = "Name of the S3 bucket for audio storage"
  value       = aws_s3_bucket.audio_bucket.id
}

output "audio_bucket_arn" {
  description = "ARN of the S3 bucket for audio storage"
  value       = aws_s3_bucket.audio_bucket.arn
}

output "audio_bucket_domain_name" {
  description = "Domain name of the S3 bucket for audio storage"
  value       = aws_s3_bucket.audio_bucket.bucket_regional_domain_name
}

output "replica_audio_bucket_name" {
  description = "Name of the replica S3 bucket for audio storage"
  value       = var.replication_enabled ? aws_s3_bucket.replica_audio_bucket[0].id : null
}

output "replica_audio_bucket_arn" {
  description = "ARN of the replica S3 bucket for audio storage"
  value       = var.replication_enabled ? aws_s3_bucket.replica_audio_bucket[0].arn : null
}