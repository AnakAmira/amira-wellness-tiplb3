# Terraform Block - Define the required Terraform version and providers
terraform {
  # Core Terraform version constraint
  required_version = "~> 1.5.0"
  
  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # S3 backend for storing Terraform state with DynamoDB locking
  backend "s3" {
    bucket         = "amira-wellness-terraform-state-${var.environment}"
    key            = "terraform.tfstate"
    region         = "${var.primary_region}"
    encrypt        = true
    dynamodb_table = "amira-wellness-terraform-locks"
    acl            = "private"
  }
}

# Primary AWS provider for the main deployment region
provider "aws" {
  region = var.primary_region
  
  default_tags {
    tags = {
      Project     = "AmiraWellness"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Secondary AWS provider for European region for data residency and disaster recovery
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = {
      Project     = "AmiraWellness"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Tertiary AWS provider for Latin American region for low-latency access
provider "aws" {
  alias  = "tertiary"
  region = var.tertiary_region
  
  default_tags {
    tags = {
      Project     = "AmiraWellness"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Specific US-East-1 provider for global resources like ACM certificates for CloudFront
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "AmiraWellness"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}