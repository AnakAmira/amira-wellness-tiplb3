#!/bin/bash
#
# RDS PostgreSQL Setup Script for Amira Wellness
#
# This script provisions and configures an AWS RDS PostgreSQL database instance
# with appropriate security, performance, and high availability settings.
#
# Version: 1.0.0
# PostgreSQL 13.7

set -e  # Exit immediately if a command exits with a non-zero status

# Default configuration values
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-development}"
DB_INSTANCE_NAME="amira-wellness-${ENVIRONMENT}"
DB_ENGINE="postgres"
DB_ENGINE_VERSION="${DB_ENGINE_VERSION:-13.7}"
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.medium}"
DB_ALLOCATED_STORAGE="${DB_ALLOCATED_STORAGE:-100}"
DB_MAX_ALLOCATED_STORAGE="${DB_MAX_ALLOCATED_STORAGE:-500}"
DB_STORAGE_TYPE="${DB_STORAGE_TYPE:-gp3}"
DB_IOPS="${DB_IOPS:-3000}"
DB_NAME="${DB_NAME:-amira_wellness}"
DB_USERNAME="${DB_USERNAME:-amira_admin}"
DB_PASSWORD="${DB_PASSWORD}"
DB_PORT="${DB_PORT:-5432}"
DB_PARAMETER_GROUP_NAME="amira-wellness-${ENVIRONMENT}-pg-params"
DB_SUBNET_GROUP_NAME="amira-wellness-${ENVIRONMENT}-db-subnet-group"
DB_SECURITY_GROUP_NAME="amira-wellness-${ENVIRONMENT}-db-sg"
DB_MULTI_AZ="${DB_MULTI_AZ:-true}"
DB_BACKUP_RETENTION_PERIOD="${DB_BACKUP_RETENTION_PERIOD:-7}"
DB_BACKUP_WINDOW="${DB_BACKUP_WINDOW:-03:00-06:00}"
DB_MAINTENANCE_WINDOW="${DB_MAINTENANCE_WINDOW:-sun:00:00-sun:03:00}"
DB_DELETION_PROTECTION="${DB_DELETION_PROTECTION:-true}"
DB_SKIP_FINAL_SNAPSHOT="${DB_SKIP_FINAL_SNAPSHOT:-false}"
DB_APPLY_IMMEDIATELY="${DB_APPLY_IMMEDIATELY:-false}"
DB_MONITORING_INTERVAL="${DB_MONITORING_INTERVAL:-60}"
DB_PERFORMANCE_INSIGHTS_ENABLED="${DB_PERFORMANCE_INSIGHTS_ENABLED:-true}"
DB_PERFORMANCE_INSIGHTS_RETENTION_PERIOD="${DB_PERFORMANCE_INSIGHTS_RETENTION_PERIOD:-7}"

# Required environment variables
# VPC_ID - The VPC ID where the RDS instance will be deployed
# SUBNET_IDS - Comma-separated list of subnet IDs for the DB subnet group
# APP_SECURITY_GROUP_ID - Security group ID of the application that will connect to the database

# Check if all prerequisites are installed and environment variables are set
check_prerequisites() {
  echo "Checking prerequisites..."

  # Check if AWS CLI is installed
  if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    return 1
  fi

  # Verify AWS credentials are configured
  if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials are not configured. Please run 'aws configure' first."
    return 1
  fi

  # Check if DB_PASSWORD is set
  if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is not set."
    return 1
  fi

  # Validate required environment variables
  if [ -z "$VPC_ID" ]; then
    echo "Error: VPC_ID environment variable is not set."
    return 1
  fi

  if [ -z "$SUBNET_IDS" ]; then
    echo "Error: SUBNET_IDS environment variable is not set. Please provide comma-separated subnet IDs."
    return 1
  fi

  if [ -z "$APP_SECURITY_GROUP_ID" ]; then
    echo "Error: APP_SECURITY_GROUP_ID environment variable is not set."
    return 1
  fi

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it for JSON parsing."
    return 1
  fi

  # Verify VPC exists
  if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$AWS_REGION" &> /dev/null; then
    echo "Error: VPC with ID $VPC_ID does not exist in region $AWS_REGION."
    return 1
  fi

  # Verify subnets exist
  IFS=',' read -ra SUBNET_ARRAY <<< "$SUBNET_IDS"
  for subnet in "${SUBNET_ARRAY[@]}"; do
    if ! aws ec2 describe-subnets --subnet-ids "$subnet" --region "$AWS_REGION" &> /dev/null; then
      echo "Error: Subnet with ID $subnet does not exist in region $AWS_REGION."
      return 1
    fi
  done

  # Verify security group exists
  if ! aws ec2 describe-security-groups --group-ids "$APP_SECURITY_GROUP_ID" --region "$AWS_REGION" &> /dev/null; then
    echo "Error: Security group with ID $APP_SECURITY_GROUP_ID does not exist in region $AWS_REGION."
    return 1
  fi

  echo "All prerequisites met."
  return 0
}

# Creates a database subnet group for the RDS instance using provided subnet IDs
create_db_subnet_group() {
  echo "Creating DB subnet group..."

  # Check if subnet group already exists
  if aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "DB subnet group $DB_SUBNET_GROUP_NAME already exists."
    return 0
  fi

  # Create subnet group
  IFS=',' read -ra SUBNET_ARRAY <<< "$SUBNET_IDS"
  SUBNET_LIST_JSON=$(printf '"%s" ' "${SUBNET_ARRAY[@]}" | sed 's/ $//')
  
  aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --db-subnet-group-description "Subnet group for Amira Wellness RDS - $ENVIRONMENT" \
    --subnet-ids $(echo $SUBNET_LIST_JSON | sed 's/"//g') \
    --region "$AWS_REGION" \
    --tags \
      Key=Environment,Value="$ENVIRONMENT" \
      Key=Project,Value="AmiraWellness" \
      Key=ManagedBy,Value="Terraform"

  if [ $? -eq 0 ]; then
    echo "DB subnet group $DB_SUBNET_GROUP_NAME created successfully."
    return 0
  else
    echo "Failed to create DB subnet group."
    return 1
  fi
}

# Creates a custom parameter group for PostgreSQL with optimized settings
create_db_parameter_group() {
  echo "Creating DB parameter group..."

  # PostgreSQL family depends on the engine version
  local major_version=$(echo $DB_ENGINE_VERSION | cut -d'.' -f1)
  local PG_FAMILY="postgres${major_version}"
  
  # Check if parameter group already exists
  if aws rds describe-db-parameter-groups \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "DB parameter group $DB_PARAMETER_GROUP_NAME already exists."
  else
    # Create parameter group
    aws rds create-db-parameter-group \
      --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
      --db-parameter-group-family "$PG_FAMILY" \
      --description "Custom parameters for Amira Wellness PostgreSQL - $ENVIRONMENT" \
      --region "$AWS_REGION" \
      --tags \
        Key=Environment,Value="$ENVIRONMENT" \
        Key=Project,Value="AmiraWellness" \
        Key=ManagedBy,Value="Terraform"
    
    if [ $? -ne 0 ]; then
      echo "Failed to create DB parameter group."
      return 1
    fi
  fi

  # Configure parameters for performance optimization
  echo "Configuring optimized parameters..."
  
  # Memory parameters
  aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --parameters \
      "ParameterName=shared_buffers,ParameterValue={DBInstanceClassMemory/4},ApplyMethod=pending-reboot" \
      "ParameterName=work_mem,ParameterValue=16384,ApplyMethod=pending-reboot" \
      "ParameterName=maintenance_work_mem,ParameterValue=2097152,ApplyMethod=pending-reboot" \
      "ParameterName=effective_cache_size,ParameterValue={DBInstanceClassMemory*3/4},ApplyMethod=pending-reboot" \
    --region "$AWS_REGION"

  # Connection parameters
  aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --parameters \
      "ParameterName=max_connections,ParameterValue=LEAST({DBInstanceClassMemory/9531392},5000),ApplyMethod=pending-reboot" \
      "ParameterName=max_prepared_transactions,ParameterValue=0,ApplyMethod=pending-reboot" \
    --region "$AWS_REGION"

  # Logging parameters
  aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --parameters \
      "ParameterName=log_min_duration_statement,ParameterValue=1000,ApplyMethod=immediate" \
      "ParameterName=log_statement,ParameterValue=ddl,ApplyMethod=immediate" \
      "ParameterName=log_connections,ParameterValue=1,ApplyMethod=immediate" \
      "ParameterName=log_disconnections,ParameterValue=1,ApplyMethod=immediate" \
    --region "$AWS_REGION"

  # Autovacuum parameters
  aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --parameters \
      "ParameterName=autovacuum,ParameterValue=1,ApplyMethod=immediate" \
      "ParameterName=autovacuum_naptime,ParameterValue=60,ApplyMethod=immediate" \
      "ParameterName=autovacuum_vacuum_threshold,ParameterValue=50,ApplyMethod=immediate" \
      "ParameterName=autovacuum_analyze_threshold,ParameterValue=50,ApplyMethod=immediate" \
      "ParameterName=autovacuum_vacuum_scale_factor,ParameterValue=0.2,ApplyMethod=immediate" \
      "ParameterName=autovacuum_analyze_scale_factor,ParameterValue=0.1,ApplyMethod=immediate" \
    --region "$AWS_REGION"

  # Query optimization parameters
  aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    --parameters \
      "ParameterName=random_page_cost,ParameterValue=1.1,ApplyMethod=immediate" \
      "ParameterName=effective_io_concurrency,ParameterValue=200,ApplyMethod=immediate" \
      "ParameterName=default_statistics_target,ParameterValue=100,ApplyMethod=immediate" \
    --region "$AWS_REGION"

  echo "DB parameter group configured successfully."
  return 0
}

# Creates a security group for the RDS instance with appropriate ingress rules
create_db_security_group() {
  echo "Creating DB security group..."

  # Check if security group already exists
  EXISTING_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$DB_SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --region "$AWS_REGION")

  if [[ "$EXISTING_SG" != "None" && "$EXISTING_SG" != "" ]]; then
    echo "Security group $DB_SECURITY_GROUP_NAME already exists with ID: $EXISTING_SG"
    echo "$EXISTING_SG"
    return 0
  else
    # Create security group
    DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
      --group-name "$DB_SECURITY_GROUP_NAME" \
      --description "Security group for Amira Wellness RDS - $ENVIRONMENT" \
      --vpc-id "$VPC_ID" \
      --region "$AWS_REGION" \
      --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$DB_SECURITY_GROUP_NAME},{Key=Environment,Value=$ENVIRONMENT},{Key=Project,Value=AmiraWellness},{Key=ManagedBy,Value=Terraform}]" \
      --query "GroupId" \
      --output text)
    
    if [ $? -ne 0 ]; then
      echo "Failed to create security group."
      return 1
    fi
    
    echo "Created security group with ID: $DB_SECURITY_GROUP_ID"
  fi

  # Add ingress rule for PostgreSQL traffic from the application security group
  aws ec2 authorize-security-group-ingress \
    --group-id "$DB_SECURITY_GROUP_ID" \
    --protocol tcp \
    --port "$DB_PORT" \
    --source-group "$APP_SECURITY_GROUP_ID" \
    --region "$AWS_REGION" || true  # Ignore error if rule already exists

  echo "Security group configured successfully."
  echo "$DB_SECURITY_GROUP_ID"
  return 0
}

# Creates a KMS key for RDS encryption
create_kms_key() {
  echo "Creating KMS key for RDS encryption..."

  # Check if KMS key with the alias already exists
  KMS_KEY_ID=$(aws kms list-aliases \
    --query "Aliases[?AliasName=='alias/amira-$ENVIRONMENT-rds-key'].TargetKeyId" \
    --output text \
    --region "$AWS_REGION")

  if [[ "$KMS_KEY_ID" != "None" && "$KMS_KEY_ID" != "" ]]; then
    echo "KMS key with alias 'alias/amira-$ENVIRONMENT-rds-key' already exists with ID: $KMS_KEY_ID"
    
    # Get the key ARN
    KMS_KEY_ARN=$(aws kms describe-key \
      --key-id "$KMS_KEY_ID" \
      --query "KeyMetadata.Arn" \
      --output text \
      --region "$AWS_REGION")
    
    echo "$KMS_KEY_ARN"
    return 0
  else
    # Create a new KMS key
    KMS_KEY_ID=$(aws kms create-key \
      --description "KMS key for Amira Wellness RDS - $ENVIRONMENT" \
      --tags TagKey=Environment,TagValue="$ENVIRONMENT" TagKey=Project,TagValue="AmiraWellness" TagKey=ManagedBy,TagValue="Terraform" \
      --query "KeyMetadata.KeyId" \
      --output text \
      --region "$AWS_REGION")
    
    if [ $? -ne 0 ]; then
      echo "Failed to create KMS key."
      return 1
    fi
    
    # Create an alias for the key
    aws kms create-alias \
      --alias-name "alias/amira-$ENVIRONMENT-rds-key" \
      --target-key-id "$KMS_KEY_ID" \
      --region "$AWS_REGION"
    
    # Enable key rotation
    aws kms enable-key-rotation \
      --key-id "$KMS_KEY_ID" \
      --region "$AWS_REGION"
    
    # Get the key ARN
    KMS_KEY_ARN=$(aws kms describe-key \
      --key-id "$KMS_KEY_ID" \
      --query "KeyMetadata.Arn" \
      --output text \
      --region "$AWS_REGION")
    
    echo "Created KMS key with ID: $KMS_KEY_ID and ARN: $KMS_KEY_ARN"
    echo "$KMS_KEY_ARN"
    return 0
  fi
}

# Creates an IAM role for RDS enhanced monitoring
create_monitoring_role() {
  echo "Creating IAM role for RDS enhanced monitoring..."

  # Check if role already exists
  if aws iam get-role --role-name "amira-rds-monitoring-role" &> /dev/null; then
    echo "IAM role 'amira-rds-monitoring-role' already exists."
    
    # Get the role ARN
    MONITORING_ROLE_ARN=$(aws iam get-role \
      --role-name "amira-rds-monitoring-role" \
      --query "Role.Arn" \
      --output text)
    
    echo "$MONITORING_ROLE_ARN"
    return 0
  else
    # Create a trust policy document for the role
    cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role
    MONITORING_ROLE_ARN=$(aws iam create-role \
      --role-name "amira-rds-monitoring-role" \
      --assume-role-policy-document file:///tmp/trust-policy.json \
      --description "IAM role for RDS enhanced monitoring" \
      --query "Role.Arn" \
      --output text)
    
    if [ $? -ne 0 ]; then
      echo "Failed to create IAM role."
      return 1
    fi
    
    # Attach the AmazonRDSEnhancedMonitoringRole policy
    aws iam attach-role-policy \
      --role-name "amira-rds-monitoring-role" \
      --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    
    # Clean up temporary file
    rm /tmp/trust-policy.json
    
    echo "Created IAM role for RDS monitoring with ARN: $MONITORING_ROLE_ARN"
    echo "$MONITORING_ROLE_ARN"
    return 0
  fi
}

# Waits for the RDS instance to become available
wait_for_db_available() {
  echo "Waiting for RDS instance to become available..."
  
  # Maximum wait time in seconds (30 minutes)
  local MAX_WAIT=1800
  local WAIT_INTERVAL=30
  local ELAPSED=0
  
  while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws rds describe-db-instances \
      --db-instance-identifier "$DB_INSTANCE_NAME" \
      --query "DBInstances[0].DBInstanceStatus" \
      --output text \
      --region "$AWS_REGION" 2>/dev/null)
    
    if [[ "$STATUS" == "available" ]]; then
      echo "RDS instance is now available."
      return 0
    fi
    
    echo "Current status: $STATUS. Waiting $WAIT_INTERVAL seconds..."
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
  done
  
  echo "Timeout waiting for RDS instance to become available."
  return 1
}

# Creates the RDS PostgreSQL instance with all configured parameters
create_rds_instance() {
  echo "Creating RDS PostgreSQL instance..."

  # Check if RDS instance already exists
  if aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "RDS instance $DB_INSTANCE_NAME already exists."
    
    # Get the instance endpoint
    DB_ENDPOINT=$(aws rds describe-db-instances \
      --db-instance-identifier "$DB_INSTANCE_NAME" \
      --query "DBInstances[0].Endpoint.Address" \
      --output text \
      --region "$AWS_REGION")
    
    echo "$DB_ENDPOINT"
    return 0
  fi

  # Create needed components
  create_db_subnet_group
  create_db_parameter_group
  local SECURITY_GROUP_ID=$(create_db_security_group)
  local KMS_KEY_ARN=$(create_kms_key)
  local MONITORING_ROLE_ARN=$(create_monitoring_role)

  # Prepare storage parameters
  local STORAGE_PARAMS="--allocated-storage $DB_ALLOCATED_STORAGE --max-allocated-storage $DB_MAX_ALLOCATED_STORAGE --storage-type $DB_STORAGE_TYPE"
  
  if [[ "$DB_STORAGE_TYPE" == "io1" || "$DB_STORAGE_TYPE" == "gp3" ]]; then
    STORAGE_PARAMS="$STORAGE_PARAMS --iops $DB_IOPS"
  fi

  # Prepare multi-AZ parameter
  local MULTI_AZ_PARAM=""
  if [[ "$DB_MULTI_AZ" == "true" ]]; then
    MULTI_AZ_PARAM="--multi-az"
  else
    MULTI_AZ_PARAM="--no-multi-az"
  fi

  # Prepare performance insights parameters
  local PI_PARAMS=""
  if [[ "$DB_PERFORMANCE_INSIGHTS_ENABLED" == "true" ]]; then
    PI_PARAMS="--enable-performance-insights --performance-insights-retention-period $DB_PERFORMANCE_INSIGHTS_RETENTION_PERIOD --performance-insights-kms-key-id $KMS_KEY_ARN"
  else
    PI_PARAMS="--no-enable-performance-insights"
  fi

  # Prepare deletion protection parameter
  local DELETION_PROTECTION=""
  if [[ "$DB_DELETION_PROTECTION" == "true" ]]; then
    DELETION_PROTECTION="--deletion-protection"
  else
    DELETION_PROTECTION="--no-deletion-protection"
  fi

  # Prepare final snapshot parameter
  local SKIP_FINAL_SNAPSHOT=""
  if [[ "$DB_SKIP_FINAL_SNAPSHOT" == "true" ]]; then
    SKIP_FINAL_SNAPSHOT="--skip-final-snapshot"
  else
    SKIP_FINAL_SNAPSHOT="--no-skip-final-snapshot --final-db-snapshot-identifier ${DB_INSTANCE_NAME}-final-snapshot"
  fi

  # Create the RDS instance
  aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_NAME" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine "$DB_ENGINE" \
    --engine-version "$DB_ENGINE_VERSION" \
    --db-name "$DB_NAME" \
    --master-username "$DB_USERNAME" \
    --master-user-password "$DB_PASSWORD" \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --vpc-security-group-ids "$SECURITY_GROUP_ID" \
    --db-parameter-group-name "$DB_PARAMETER_GROUP_NAME" \
    $STORAGE_PARAMS \
    --port "$DB_PORT" \
    $MULTI_AZ_PARAM \
    --backup-retention-period "$DB_BACKUP_RETENTION_PERIOD" \
    --preferred-backup-window "$DB_BACKUP_WINDOW" \
    --preferred-maintenance-window "$DB_MAINTENANCE_WINDOW" \
    --storage-encrypted \
    --kms-key-id "$KMS_KEY_ARN" \
    --monitoring-interval "$DB_MONITORING_INTERVAL" \
    --monitoring-role-arn "$MONITORING_ROLE_ARN" \
    $PI_PARAMS \
    $DELETION_PROTECTION \
    $SKIP_FINAL_SNAPSHOT \
    --copy-tags-to-snapshot \
    --auto-minor-version-upgrade \
    --tags \
      Key=Environment,Value="$ENVIRONMENT" \
      Key=Project,Value="AmiraWellness" \
      Key=ManagedBy,Value="Terraform" \
    --region "$AWS_REGION"

  if [ $? -ne 0 ]; then
    echo "Failed to create RDS instance."
    return 1
  fi

  echo "RDS instance creation initiated. Waiting for it to become available..."
  
  # Wait for the instance to be available
  wait_for_db_available
  
  # Get the instance endpoint
  DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_NAME" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --region "$AWS_REGION")
  
  echo "RDS instance created successfully."
  echo "$DB_ENDPOINT"
  return 0
}

# Creates output variables for use in other deployment scripts
create_output_variables() {
  echo "Creating output variables..."
  
  # Get the instance endpoint
  DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_NAME" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --region "$AWS_REGION")
  
  # Create output file
  OUTPUT_FILE="rds_output.env"
  
  cat > $OUTPUT_FILE << EOF
# RDS PostgreSQL configuration
# Generated on $(date)
DB_HOST=$DB_ENDPOINT
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USERNAME=$DB_USERNAME
# DB_PASSWORD is sensitive and should be securely stored and retrieved
# DB_PASSWORD=$DB_PASSWORD
EOF

  # Set appropriate permissions - readable only by owner
  chmod 600 $OUTPUT_FILE
  
  echo "Output variables written to $OUTPUT_FILE"
  return 0
}

# Sets up initial database schema and users
setup_initial_database() {
  echo "Setting up initial database schema..."

  # Wait until the database is available
  wait_for_db_available
  
  # Get the instance endpoint
  DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_NAME" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --region "$AWS_REGION")
  
  # Create temporary SQL file
  cat > /tmp/init.sql << EOF
-- Create application database user
CREATE USER amira_app WITH PASSWORD '${DB_PASSWORD}_app';

-- Create initial schema
CREATE SCHEMA IF NOT EXISTS amira;

-- Grant privileges to application user
GRANT USAGE ON SCHEMA amira TO amira_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA amira TO amira_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA amira TO amira_app;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA amira
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO amira_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA amira
    GRANT USAGE ON SEQUENCES TO amira_app;

-- Create essential extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Set up some basic security settings
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM SET log_min_duration_statement = 1000;
EOF

  # Execute SQL using psql
  export PGPASSWORD="$DB_PASSWORD"
  if ! command -v psql &> /dev/null; then
    echo "Warning: psql client not found. Skipping initial schema setup. Please run the SQL manually."
    cat /tmp/init.sql
    rm /tmp/init.sql
    return 0
  fi

  # Run the SQL commands
  psql -h "$DB_ENDPOINT" -U "$DB_USERNAME" -d "$DB_NAME" -f /tmp/init.sql
  RESULT=$?
  
  # Clean up
  rm /tmp/init.sql
  unset PGPASSWORD
  
  if [ $RESULT -eq 0 ]; then
    echo "Initial database setup completed successfully."
    return 0
  else
    echo "Failed to set up initial database schema."
    return 1
  fi
}

# Main function that orchestrates the RDS setup process
main() {
  echo "Starting RDS PostgreSQL setup for Amira Wellness ($ENVIRONMENT environment)..."
  
  # Check prerequisites
  check_prerequisites
  if [ $? -ne 0 ]; then
    echo "Prerequisites check failed. Exiting."
    return 1
  fi
  
  # Create RDS instance and components
  DB_ENDPOINT=$(create_rds_instance)
  if [ $? -ne 0 ]; then
    echo "Failed to create RDS instance. Exiting."
    return 1
  fi
  
  # Setup initial database schema
  setup_initial_database
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to set up initial database schema. You may need to do this manually."
    # Not failing the script for this issue
  fi
  
  # Create output variables
  create_output_variables
  
  echo "======================================================="
  echo "RDS PostgreSQL instance setup completed successfully!"
  echo "Instance Name: $DB_INSTANCE_NAME"
  echo "Endpoint: $DB_ENDPOINT"
  echo "Port: $DB_PORT"
  echo "Database Name: $DB_NAME"
  echo "Master Username: $DB_USERNAME"
  echo "Environment: $ENVIRONMENT"
  echo "======================================================="
  
  return 0
}

# Execute main function
main
exit $?