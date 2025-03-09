#!/bin/bash
#
# ElastiCache Redis Setup Script for Amira Wellness
#
# This script provisions and configures an AWS ElastiCache Redis cluster
# with appropriate security, performance, and high availability settings.
#
# Version: 1.0.0
# AWS ElastiCache Redis 6.2

set -e  # Exit immediately if a command exits with a non-zero status

# Default configuration values
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-development}"
CACHE_CLUSTER_NAME="amira-wellness-${ENVIRONMENT}"
CACHE_ENGINE="redis"
CACHE_ENGINE_VERSION="${CACHE_ENGINE_VERSION:-6.2}"
CACHE_NODE_TYPE="${CACHE_NODE_TYPE:-cache.t3.small}"
CACHE_NUM_NODES="${CACHE_NUM_NODES:-2}"
CACHE_PARAMETER_GROUP_NAME="amira-wellness-${ENVIRONMENT}-redis-params"
CACHE_SUBNET_GROUP_NAME="amira-wellness-${ENVIRONMENT}-cache-subnet-group"
CACHE_SECURITY_GROUP_NAME="amira-wellness-${ENVIRONMENT}-cache-sg"
CACHE_PORT="${CACHE_PORT:-6379}"
CACHE_AUTOMATIC_FAILOVER="${CACHE_AUTOMATIC_FAILOVER:-true}"
CACHE_MULTI_AZ="${CACHE_MULTI_AZ:-true}"
CACHE_ENCRYPTION_AT_REST="${CACHE_ENCRYPTION_AT_REST:-true}"
CACHE_ENCRYPTION_IN_TRANSIT="${CACHE_ENCRYPTION_IN_TRANSIT:-true}"
CACHE_MAINTENANCE_WINDOW="${CACHE_MAINTENANCE_WINDOW:-sun:03:00-sun:04:00}"
CACHE_SNAPSHOT_RETENTION_LIMIT="${CACHE_SNAPSHOT_RETENTION_LIMIT:-7}"
CACHE_SNAPSHOT_WINDOW="${CACHE_SNAPSHOT_WINDOW:-04:00-05:00}"
CACHE_APPLY_IMMEDIATELY="${CACHE_APPLY_IMMEDIATELY:-false}"

# Required environment variables
# VPC_ID - The VPC ID where the ElastiCache cluster will be deployed
# SUBNET_IDS - Comma-separated list of subnet IDs for the cache subnet group
# APP_SECURITY_GROUP_ID - Security group ID of the application that will connect to Redis

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

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it for JSON parsing."
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

# Create a cache subnet group for the ElastiCache cluster
create_cache_subnet_group() {
  echo "Creating cache subnet group..."

  # Check if subnet group already exists
  if aws elasticache describe-cache-subnet-groups \
    --cache-subnet-group-name "$CACHE_SUBNET_GROUP_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "Cache subnet group $CACHE_SUBNET_GROUP_NAME already exists."
    return 0
  fi

  # Create subnet group
  IFS=',' read -ra SUBNET_ARRAY <<< "$SUBNET_IDS"
  SUBNET_LIST_JSON=$(printf '"%s" ' "${SUBNET_ARRAY[@]}" | sed 's/ $//')
  
  aws elasticache create-cache-subnet-group \
    --cache-subnet-group-name "$CACHE_SUBNET_GROUP_NAME" \
    --cache-subnet-group-description "Subnet group for Amira Wellness Redis - $ENVIRONMENT" \
    --subnet-ids $(echo $SUBNET_LIST_JSON | sed 's/"//g') \
    --region "$AWS_REGION" \
    --tags \
      Key=Environment,Value="$ENVIRONMENT" \
      Key=Project,Value="AmiraWellness" \
      Key=ManagedBy,Value="Terraform"

  if [ $? -eq 0 ]; then
    echo "Cache subnet group $CACHE_SUBNET_GROUP_NAME created successfully."
    return 0
  else
    echo "Failed to create cache subnet group."
    return 1
  fi
}

# Create a custom parameter group for Redis with optimized settings
create_cache_parameter_group() {
  echo "Creating cache parameter group..."

  # Redis family depends on the engine version
  REDIS_FAMILY="redis6.x"
  
  # Check if parameter group already exists
  if aws elasticache describe-cache-parameter-groups \
    --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "Cache parameter group $CACHE_PARAMETER_GROUP_NAME already exists."
  else
    # Create parameter group
    aws elasticache create-cache-parameter-group \
      --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
      --cache-parameter-group-family "$REDIS_FAMILY" \
      --description "Custom parameters for Amira Wellness Redis - $ENVIRONMENT" \
      --region "$AWS_REGION" \
      --tags \
        Key=Environment,Value="$ENVIRONMENT" \
        Key=Project,Value="AmiraWellness" \
        Key=ManagedBy,Value="Terraform"
    
    if [ $? -ne 0 ]; then
      echo "Failed to create cache parameter group."
      return 1
    fi
  fi

  # Configure parameters for performance optimization
  echo "Configuring optimized parameters..."
  
  # Memory management parameters
  aws elasticache modify-cache-parameter-group \
    --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
    --parameter-name-values \
      ParameterName=maxmemory-policy,ParameterValue=volatile-lru \
      ParameterName=activedefrag,ParameterValue=yes \
      ParameterName=active-defrag-cycle-min,ParameterValue=25 \
      ParameterName=active-defrag-cycle-max,ParameterValue=75 \
      ParameterName=active-defrag-threshold-lower,ParameterValue=10 \
      ParameterName=active-defrag-threshold-upper,ParameterValue=100 \
    --region "$AWS_REGION"

  # Connection parameters
  aws elasticache modify-cache-parameter-group \
    --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
    --parameter-name-values \
      ParameterName=timeout,ParameterValue=300 \
      ParameterName=tcp-keepalive,ParameterValue=300 \
      ParameterName=client-output-buffer-limit-normal-hard-limit,ParameterValue=0 \
      ParameterName=client-output-buffer-limit-normal-soft-limit,ParameterValue=0 \
      ParameterName=client-output-buffer-limit-normal-soft-seconds,ParameterValue=0 \
    --region "$AWS_REGION"

  # Performance optimization parameters
  aws elasticache modify-cache-parameter-group \
    --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
    --parameter-name-values \
      ParameterName=maxclients,ParameterValue=65000 \
      ParameterName=hash-max-ziplist-entries,ParameterValue=512 \
      ParameterName=hash-max-ziplist-value,ParameterValue=64 \
      ParameterName=list-max-ziplist-entries,ParameterValue=512 \
      ParameterName=list-max-ziplist-value,ParameterValue=64 \
    --region "$AWS_REGION"

  echo "Cache parameter group configured successfully."
  return 0
}

# Create a security group for the ElastiCache cluster
create_cache_security_group() {
  echo "Creating cache security group..."

  # Check if security group already exists
  EXISTING_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$CACHE_SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --region "$AWS_REGION")

  if [[ "$EXISTING_SG" != "None" && "$EXISTING_SG" != "" ]]; then
    echo "Security group $CACHE_SECURITY_GROUP_NAME already exists with ID: $EXISTING_SG"
    CACHE_SECURITY_GROUP_ID=$EXISTING_SG
  else
    # Create security group
    CACHE_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
      --group-name "$CACHE_SECURITY_GROUP_NAME" \
      --description "Security group for Amira Wellness Redis - $ENVIRONMENT" \
      --vpc-id "$VPC_ID" \
      --region "$AWS_REGION" \
      --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$CACHE_SECURITY_GROUP_NAME},{Key=Environment,Value=$ENVIRONMENT},{Key=Project,Value=AmiraWellness},{Key=ManagedBy,Value=Terraform}]" \
      --query "GroupId" \
      --output text)
    
    if [ $? -ne 0 ]; then
      echo "Failed to create security group."
      return 1
    fi
    
    echo "Created security group with ID: $CACHE_SECURITY_GROUP_ID"
  fi

  # Add ingress rule for Redis traffic from the application security group
  aws ec2 authorize-security-group-ingress \
    --group-id "$CACHE_SECURITY_GROUP_ID" \
    --protocol tcp \
    --port "$CACHE_PORT" \
    --source-group "$APP_SECURITY_GROUP_ID" \
    --region "$AWS_REGION" || true  # Ignore error if rule already exists

  echo "Security group configured successfully."
  echo "$CACHE_SECURITY_GROUP_ID"
  return 0
}

# Wait for the ElastiCache cluster to become available
wait_for_cache_available() {
  echo "Waiting for ElastiCache cluster to become available..."
  
  # Maximum wait time in seconds (30 minutes)
  MAX_WAIT=1800
  WAIT_INTERVAL=30
  ELAPSED=0
  
  while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws elasticache describe-replication-groups \
      --replication-group-id "$CACHE_CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query "ReplicationGroups[0].Status" \
      --output text)
    
    if [[ "$STATUS" == "available" ]]; then
      echo "ElastiCache cluster is now available."
      return 0
    fi
    
    echo "Current status: $STATUS. Waiting $WAIT_INTERVAL seconds..."
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
  done
  
  echo "Timeout waiting for ElastiCache cluster to become available."
  return 1
}

# Create the ElastiCache Redis cluster
create_cache_cluster() {
  echo "Creating ElastiCache Redis cluster..."

  # Check if cache cluster already exists
  if aws elasticache describe-replication-groups \
    --replication-group-id "$CACHE_CLUSTER_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    echo "Cache cluster $CACHE_CLUSTER_NAME already exists."
    
    # Get endpoint information
    CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
      --replication-group-id "$CACHE_CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query "ReplicationGroups[0].ConfigurationEndpoint.Address" \
      --output text)
    
    if [[ "$CACHE_ENDPOINT" == "None" || "$CACHE_ENDPOINT" == "" ]]; then
      CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
        --replication-group-id "$CACHE_CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query "ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address" \
        --output text)
    fi
    
    echo "$CACHE_ENDPOINT"
    return 0
  fi

  # Create the cache security group, subnet group, and parameter group
  SECURITY_GROUP_ID=$(create_cache_security_group)
  create_cache_subnet_group
  create_cache_parameter_group

  # Prepare automatic failover parameter
  if [[ "$CACHE_AUTOMATIC_FAILOVER" == "true" ]]; then
    AUTO_FAILOVER="--automatic-failover-enabled"
  else
    AUTO_FAILOVER="--no-automatic-failover"
  fi

  # Prepare multi-AZ parameter
  if [[ "$CACHE_MULTI_AZ" == "true" ]]; then
    MULTI_AZ="--multi-az-enabled"
  else
    MULTI_AZ="--no-multi-az"
  fi

  # Prepare encryption parameters
  if [[ "$CACHE_ENCRYPTION_AT_REST" == "true" ]]; then
    AT_REST_ENCRYPTION="--at-rest-encryption-enabled"
  else
    AT_REST_ENCRYPTION="--no-at-rest-encryption"
  fi

  if [[ "$CACHE_ENCRYPTION_IN_TRANSIT" == "true" ]]; then
    TRANSIT_ENCRYPTION="--transit-encryption-enabled"
  else
    TRANSIT_ENCRYPTION="--no-transit-encryption"
  fi

  # Create the replication group for Redis
  aws elasticache create-replication-group \
    --replication-group-id "$CACHE_CLUSTER_NAME" \
    --replication-group-description "ElastiCache Redis cluster for Amira Wellness - $ENVIRONMENT" \
    --engine "$CACHE_ENGINE" \
    --engine-version "$CACHE_ENGINE_VERSION" \
    --cache-node-type "$CACHE_NODE_TYPE" \
    --num-cache-clusters "$CACHE_NUM_NODES" \
    --cache-parameter-group-name "$CACHE_PARAMETER_GROUP_NAME" \
    --cache-subnet-group-name "$CACHE_SUBNET_GROUP_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --port "$CACHE_PORT" \
    --maintenance-window "$CACHE_MAINTENANCE_WINDOW" \
    --snapshot-retention-limit "$CACHE_SNAPSHOT_RETENTION_LIMIT" \
    --snapshot-window "$CACHE_SNAPSHOT_WINDOW" \
    $AUTO_FAILOVER \
    $MULTI_AZ \
    $AT_REST_ENCRYPTION \
    $TRANSIT_ENCRYPTION \
    --apply-immediately \
    --tags \
      Key=Environment,Value="$ENVIRONMENT" \
      Key=Project,Value="AmiraWellness" \
      Key=ManagedBy,Value="Terraform" \
    --region "$AWS_REGION"

  if [ $? -ne 0 ]; then
    echo "Failed to create ElastiCache Redis cluster."
    return 1
  fi

  echo "ElastiCache Redis cluster creation initiated. Waiting for it to become available..."
  
  # Wait for the cluster to be available
  wait_for_cache_available
  
  # Get the cluster endpoint
  CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
    --replication-group-id "$CACHE_CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "ReplicationGroups[0].ConfigurationEndpoint.Address" \
    --output text)
  
  if [[ "$CACHE_ENDPOINT" == "None" || "$CACHE_ENDPOINT" == "" ]]; then
    CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
      --replication-group-id "$CACHE_CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query "ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address" \
      --output text)
  fi
  
  echo "ElastiCache Redis cluster created successfully."
  echo "$CACHE_ENDPOINT"
  return 0
}

# Create output variables for use in other deployment scripts
create_output_variables() {
  echo "Creating output variables..."
  
  # Get the cluster endpoint
  CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
    --replication-group-id "$CACHE_CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "ReplicationGroups[0].ConfigurationEndpoint.Address" \
    --output text)
  
  if [[ "$CACHE_ENDPOINT" == "None" || "$CACHE_ENDPOINT" == "" ]]; then
    CACHE_ENDPOINT=$(aws elasticache describe-replication-groups \
      --replication-group-id "$CACHE_CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query "ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address" \
      --output text)
  fi
  
  # Create output file
  OUTPUT_FILE="elasticache_output.env"
  
  cat > $OUTPUT_FILE << EOF
# ElastiCache Redis configuration
# Generated on $(date)
REDIS_HOST=$CACHE_ENDPOINT
REDIS_PORT=$CACHE_PORT
REDIS_TLS_ENABLED=$CACHE_ENCRYPTION_IN_TRANSIT
REDIS_CLUSTER_MODE=true
REDIS_DATABASE_COUNT=16
EOF

  echo "Output variables written to $OUTPUT_FILE"
}

# Set up CloudWatch alarms for monitoring the ElastiCache cluster
setup_cloudwatch_alarms() {
  echo "Setting up CloudWatch alarms for ElastiCache monitoring..."
  
  # Get account ID for SNS topic ARN
  ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  SNS_TOPIC_ARN="arn:aws:sns:${AWS_REGION}:${ACCOUNT_ID}:${ENVIRONMENT}-alerts"
  
  # Verify if SNS topic exists, if not create it
  if ! aws sns get-topic-attributes --topic-arn "$SNS_TOPIC_ARN" --region "$AWS_REGION" &> /dev/null; then
    echo "Creating SNS topic for ElastiCache alarms..."
    aws sns create-topic --name "${ENVIRONMENT}-alerts" --region "$AWS_REGION"
  fi
  
  # Create CPU utilization alarm
  aws cloudwatch put-metric-alarm \
    --alarm-name "${CACHE_CLUSTER_NAME}-high-cpu" \
    --alarm-description "High CPU utilization for ElastiCache Redis cluster" \
    --metric-name "CPUUtilization" \
    --namespace "AWS/ElastiCache" \
    --statistic "Average" \
    --period 300 \
    --threshold 75 \
    --comparison-operator "GreaterThanThreshold" \
    --dimensions "Name=CacheClusterId,Value=${CACHE_CLUSTER_NAME}-001" \
    --evaluation-periods 3 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --region "$AWS_REGION"
  
  # Create memory usage alarm
  aws cloudwatch put-metric-alarm \
    --alarm-name "${CACHE_CLUSTER_NAME}-high-memory" \
    --alarm-description "High memory usage for ElastiCache Redis cluster" \
    --metric-name "DatabaseMemoryUsagePercentage" \
    --namespace "AWS/ElastiCache" \
    --statistic "Average" \
    --period 300 \
    --threshold 85 \
    --comparison-operator "GreaterThanThreshold" \
    --dimensions "Name=CacheClusterId,Value=${CACHE_CLUSTER_NAME}-001" \
    --evaluation-periods 3 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --region "$AWS_REGION"
  
  # Create evictions alarm
  aws cloudwatch put-metric-alarm \
    --alarm-name "${CACHE_CLUSTER_NAME}-evictions" \
    --alarm-description "High eviction rate for ElastiCache Redis cluster" \
    --metric-name "Evictions" \
    --namespace "AWS/ElastiCache" \
    --statistic "Sum" \
    --period 300 \
    --threshold 100 \
    --comparison-operator "GreaterThanThreshold" \
    --dimensions "Name=CacheClusterId,Value=${CACHE_CLUSTER_NAME}-001" \
    --evaluation-periods 3 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --region "$AWS_REGION"
  
  # Create connections alarm
  aws cloudwatch put-metric-alarm \
    --alarm-name "${CACHE_CLUSTER_NAME}-connections" \
    --alarm-description "High connection count for ElastiCache Redis cluster" \
    --metric-name "CurrConnections" \
    --namespace "AWS/ElastiCache" \
    --statistic "Average" \
    --period 300 \
    --threshold 5000 \
    --comparison-operator "GreaterThanThreshold" \
    --dimensions "Name=CacheClusterId,Value=${CACHE_CLUSTER_NAME}-001" \
    --evaluation-periods 3 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --region "$AWS_REGION"
  
  echo "CloudWatch alarms set up successfully."
  return 0
}

# Validate the ElastiCache configuration settings
validate_cache_configuration() {
  echo "Validating ElastiCache configuration..."
  
  # Validate node type is appropriate for the environment
  if [[ "$ENVIRONMENT" == "production" && "$CACHE_NODE_TYPE" == "cache.t3.micro" ]]; then
    echo "Warning: cache.t3.micro is not recommended for production use."
    # Not failing, just warning
  fi
  
  # Verify encryption settings for production environments
  if [[ "$ENVIRONMENT" == "production" && "$CACHE_ENCRYPTION_AT_REST" != "true" ]]; then
    echo "Error: Encryption at rest must be enabled for production environments."
    return 1
  fi
  
  if [[ "$ENVIRONMENT" == "production" && "$CACHE_ENCRYPTION_IN_TRANSIT" != "true" ]]; then
    echo "Error: Encryption in transit must be enabled for production environments."
    return 1
  fi
  
  # Check multi-AZ configuration aligns with environment requirements
  if [[ "$ENVIRONMENT" == "production" && "$CACHE_MULTI_AZ" != "true" ]]; then
    echo "Error: Multi-AZ must be enabled for production environments."
    return 1
  fi
  
  # Validate Redis version is supported
  SUPPORTED_VERSIONS=("6.0" "6.2" "7.0")
  VERSION_SUPPORTED=false
  
  for version in "${SUPPORTED_VERSIONS[@]}"; do
    if [[ "$CACHE_ENGINE_VERSION" == "$version"* ]]; then
      VERSION_SUPPORTED=true
      break
    fi
  done
  
  if [ "$VERSION_SUPPORTED" = false ]; then
    echo "Error: Redis version $CACHE_ENGINE_VERSION is not supported. Use one of: ${SUPPORTED_VERSIONS[*]}"
    return 1
  fi
  
  echo "ElastiCache configuration validated successfully."
  return 0
}

# Main function that orchestrates the ElastiCache setup process
main() {
  echo "Starting ElastiCache Redis setup for Amira Wellness ($ENVIRONMENT environment)..."
  
  # Check prerequisites
  check_prerequisites
  if [ $? -ne 0 ]; then
    echo "Prerequisites check failed. Exiting."
    return 1
  fi
  
  # Validate configuration
  validate_cache_configuration
  if [ $? -ne 0 ]; then
    echo "Configuration validation failed. Exiting."
    return 1
  fi
  
  # Create ElastiCache cluster and components
  CACHE_ENDPOINT=$(create_cache_cluster)
  if [ $? -ne 0 ]; then
    echo "Failed to create ElastiCache cluster. Exiting."
    return 1
  fi
  
  # Set up CloudWatch alarms
  setup_cloudwatch_alarms
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to set up CloudWatch alarms. Continuing anyway."
    # Not failing the script for monitoring setup issues
  fi
  
  # Create output variables
  create_output_variables
  
  echo "======================================================="
  echo "ElastiCache Redis cluster setup completed successfully!"
  echo "Cluster Name: $CACHE_CLUSTER_NAME"
  echo "Endpoint: $CACHE_ENDPOINT"
  echo "Port: $CACHE_PORT"
  echo "Environment: $ENVIRONMENT"
  echo "======================================================="
  
  return 0
}

# Execute main function
main
exit $?