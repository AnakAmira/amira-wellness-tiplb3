#!/bin/bash
#
# cleanup-resources.sh
#
# This script automates the cleanup of AWS resources created for the 
# Amira Wellness application. It safely removes infrastructure components 
# like ECS services, S3 buckets, RDS instances, and other cloud resources 
# to prevent unnecessary costs and resource leakage during development 
# or after environment decommissioning.

# Set strict error handling
set -e

# Global variables
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-development}"
APP_NAME="amira-wellness"
RESOURCE_PREFIX="${APP_NAME}-${ENVIRONMENT}"
FORCE_DELETE="${FORCE_DELETE:-false}"
DRY_RUN="${DRY_RUN:-false}"
LOG_FILE="/tmp/cleanup-resources-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S).log"
SKIP_CONFIRMATION="${SKIP_CONFIRMATION:-false}"

# ANSI color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize the log file
touch "$LOG_FILE"
echo "Amira Wellness Resource Cleanup - $(date)" > "$LOG_FILE"
echo "Environment: $ENVIRONMENT" >> "$LOG_FILE"
echo "AWS Region: $AWS_REGION" >> "$LOG_FILE"
echo "Dry Run: $DRY_RUN" >> "$LOG_FILE"
echo "Force Delete: $FORCE_DELETE" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

# Logging functions
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $1"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

log_error() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${RED}[$timestamp] ERROR: $1${NC}"
    echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}

log_warning() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[$timestamp] WARNING: $1${NC}"
    echo "[$timestamp] WARNING: $1" >> "$LOG_FILE"
}

log_success() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${GREEN}[$timestamp] SUCCESS: $1${NC}"
    echo "[$timestamp] SUCCESS: $1" >> "$LOG_FILE"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    log "Checking AWS CLI installation and configuration..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        return 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured properly. Please run 'aws configure'."
        return 1
    fi
    
    # Set the specified AWS region
    aws configure set region "$AWS_REGION"
    
    log_success "AWS CLI is installed and configured properly."
    return 0
}

# Confirmation function
confirm_action() {
    local message=$1
    
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}"
    echo "========================================================"
    echo "WARNING: $message"
    echo "This action will delete resources in the $ENVIRONMENT environment."
    echo "This operation cannot be undone."
    echo "========================================================"
    echo -e "${NC}"
    
    # Extra warning for production environment
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo -e "${RED}"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "! YOU ARE ABOUT TO DELETE PRODUCTION RESOURCES        !"
        echo "! This could result in service disruption and data loss!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo -e "${NC}"
    fi
    
    read -p "To confirm, please type the environment name [$ENVIRONMENT]: " confirmation
    
    if [[ "$confirmation" != "$ENVIRONMENT" ]]; then
        log_error "Confirmation failed. Aborting."
        return 1
    fi
    
    return 0
}

# Cleanup S3 buckets
cleanup_s3_buckets() {
    log "Cleaning up S3 buckets with prefix $RESOURCE_PREFIX..."
    
    # List buckets with the resource prefix
    local buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${RESOURCE_PREFIX}')].Name" --output text)
    
    if [[ -z "$buckets" ]]; then
        log "No S3 buckets found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for bucket in $buckets; do
        log "Processing bucket: $bucket"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete S3 bucket: $bucket"
            continue
        fi
        
        # Check if bucket is empty
        local objects=$(aws s3api list-objects --bucket "$bucket" --max-items 1 --query "Contents[0].Key" --output text 2>/dev/null)
        
        if [[ -n "$objects" && "$objects" != "None" ]]; then
            log "Bucket $bucket is not empty."
            
            if [[ "$FORCE_DELETE" != "true" ]]; then
                log_warning "Skipping non-empty bucket $bucket. Use --force to delete content."
                continue
            fi
            
            log "Checking if versioning is enabled..."
            local versioning=$(aws s3api get-bucket-versioning --bucket "$bucket" --query "Status" --output text 2>/dev/null)
            
            if [[ "$versioning" == "Enabled" ]]; then
                log "Removing all versions and delete markers..."
                
                # Remove all versions
                aws s3api list-object-versions --bucket "$bucket" --query "{Objects: Versions[].{Key:Key,VersionId:VersionId}}" --output json > /tmp/versions-$bucket.json
                if [[ -s /tmp/versions-$bucket.json ]]; then
                    aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/versions-$bucket.json
                fi
                
                # Remove all delete markers
                aws s3api list-object-versions --bucket "$bucket" --query "{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}" --output json > /tmp/delete-markers-$bucket.json
                if [[ -s /tmp/delete-markers-$bucket.json ]]; then
                    aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/delete-markers-$bucket.json
                fi
                
                rm -f /tmp/versions-$bucket.json /tmp/delete-markers-$bucket.json
            else
                log "Emptying bucket..."
                aws s3 rm s3://$bucket --recursive
            fi
        fi
        
        # Delete the bucket
        log "Deleting bucket $bucket..."
        if aws s3api delete-bucket --bucket "$bucket"; then
            log_success "Successfully deleted S3 bucket: $bucket"
        else
            log_error "Failed to delete S3 bucket: $bucket"
        fi
    done
    
    return 0
}

# Cleanup CloudFront distributions
cleanup_cloudfront() {
    log "Cleaning up CloudFront distributions related to $RESOURCE_PREFIX..."
    
    # List CloudFront distributions with tags matching the application
    local distributions=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(ARN, '${RESOURCE_PREFIX}') || contains(Origins.Items[0].Id, '${RESOURCE_PREFIX}')].Id" --output text)
    
    if [[ -z "$distributions" || "$distributions" == "None" ]]; then
        log "No CloudFront distributions found related to $RESOURCE_PREFIX."
        return 0
    fi
    
    for dist_id in $distributions; do
        log "Processing CloudFront distribution: $dist_id"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete CloudFront distribution: $dist_id"
            continue
        fi
        
        # Check if the distribution is already disabled
        local enabled=$(aws cloudfront get-distribution --id "$dist_id" --query "Distribution.DistributionConfig.Enabled" --output text)
        local etag=$(aws cloudfront get-distribution --id "$dist_id" --query "ETag" --output text)
        
        if [[ "$enabled" == "true" ]]; then
            log "Distribution $dist_id is enabled. Disabling first..."
            
            # Get the current config
            aws cloudfront get-distribution-config --id "$dist_id" > /tmp/cf-config-$dist_id.json
            
            # Modify the config to disable the distribution
            jq '.DistributionConfig.Enabled = false' /tmp/cf-config-$dist_id.json > /tmp/cf-config-disabled-$dist_id.json
            
            # Update the distribution to disable it
            etag=$(jq -r '.ETag' /tmp/cf-config-$dist_id.json)
            aws cloudfront update-distribution --id "$dist_id" --if-match "$etag" --distribution-config "$(jq -r '.DistributionConfig' /tmp/cf-config-disabled-$dist_id.json)"
            
            log "Waiting for CloudFront distribution to deploy changes..."
            aws cloudfront wait distribution-deployed --id "$dist_id"
            
            rm -f /tmp/cf-config-$dist_id.json /tmp/cf-config-disabled-$dist_id.json
            
            # Get the new ETag
            etag=$(aws cloudfront get-distribution --id "$dist_id" --query "ETag" --output text)
        fi
        
        # Delete the distribution
        log "Deleting CloudFront distribution $dist_id..."
        if aws cloudfront delete-distribution --id "$dist_id" --if-match "$etag"; then
            log_success "Successfully deleted CloudFront distribution: $dist_id"
        else
            log_error "Failed to delete CloudFront distribution: $dist_id"
        fi
    done
    
    return 0
}

# Cleanup ECS resources (services, task definitions, clusters)
cleanup_ecs_resources() {
    log "Cleaning up ECS resources with prefix $RESOURCE_PREFIX..."
    
    # List ECS clusters
    local clusters=$(aws ecs list-clusters --query "clusterArns[?contains(@, '${RESOURCE_PREFIX}')]" --output text)
    
    if [[ -z "$clusters" || "$clusters" == "None" ]]; then
        log "No ECS clusters found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for cluster in $clusters; do
        local cluster_name=$(basename "$cluster")
        log "Processing ECS cluster: $cluster_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete ECS cluster and its services: $cluster_name"
            continue
        fi
        
        # List all services in the cluster
        local services=$(aws ecs list-services --cluster "$cluster_name" --query "serviceArns[]" --output text)
        
        if [[ -n "$services" && "$services" != "None" ]]; then
            for service in $services; do
                local service_name=$(basename "$service")
                log "Updating service $service_name to 0 desired count..."
                
                # Update the service to have 0 desired count
                aws ecs update-service --cluster "$cluster_name" --service "$service_name" --desired-count 0
                
                # Wait for the service to scale down
                log "Waiting for service to scale down..."
                aws ecs wait services-stable --cluster "$cluster_name" --services "$service_name"
                
                # Delete the service
                log "Deleting service $service_name..."
                if aws ecs delete-service --cluster "$cluster_name" --service "$service_name" --force; then
                    log_success "Successfully deleted ECS service: $service_name"
                else
                    log_error "Failed to delete ECS service: $service_name"
                fi
            done
        fi
        
        # List and deregister task definitions
        local task_defs=$(aws ecs list-task-definitions --family-prefix "$RESOURCE_PREFIX" --status ACTIVE --query "taskDefinitionArns[]" --output text)
        
        if [[ -n "$task_defs" && "$task_defs" != "None" ]]; then
            for task_def in $task_defs; do
                log "Deregistering task definition: $task_def"
                aws ecs deregister-task-definition --task-definition "$task_def"
            done
            log_success "Successfully deregistered ECS task definitions"
        fi
        
        # Delete the cluster
        log "Deleting ECS cluster: $cluster_name"
        if aws ecs delete-cluster --cluster "$cluster_name"; then
            log_success "Successfully deleted ECS cluster: $cluster_name"
        else
            log_error "Failed to delete ECS cluster: $cluster_name"
        fi
    done
    
    return 0
}

# Cleanup load balancers (ALB/NLB)
cleanup_load_balancers() {
    log "Cleaning up load balancers with prefix $RESOURCE_PREFIX..."
    
    # List load balancers
    local lbs=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, '${RESOURCE_PREFIX}')].LoadBalancerArn" --output text)
    
    if [[ -z "$lbs" || "$lbs" == "None" ]]; then
        log "No load balancers found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for lb in $lbs; do
        local lb_name=$(aws elbv2 describe-load-balancers --load-balancer-arns "$lb" --query "LoadBalancers[0].LoadBalancerName" --output text)
        log "Processing load balancer: $lb_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete load balancer: $lb_name"
            continue
        fi
        
        # List and delete all listeners
        local listeners=$(aws elbv2 describe-listeners --load-balancer-arn "$lb" --query "Listeners[].ListenerArn" --output text)
        
        if [[ -n "$listeners" && "$listeners" != "None" ]]; then
            for listener in $listeners; do
                log "Deleting listener: $listener"
                aws elbv2 delete-listener --listener-arn "$listener"
            done
            log_success "Successfully deleted listeners for load balancer: $lb_name"
        fi
        
        # List and delete target groups
        local target_groups=$(aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName, '${RESOURCE_PREFIX}')].TargetGroupArn" --output text)
        
        if [[ -n "$target_groups" && "$target_groups" != "None" ]]; then
            for tg in $target_groups; do
                local tg_name=$(aws elbv2 describe-target-groups --target-group-arns "$tg" --query "TargetGroups[0].TargetGroupName" --output text)
                log "Deleting target group: $tg_name"
                aws elbv2 delete-target-group --target-group-arn "$tg"
            done
            log_success "Successfully deleted target groups for load balancer: $lb_name"
        fi
        
        # Delete the load balancer
        log "Deleting load balancer: $lb_name"
        if aws elbv2 delete-load-balancer --load-balancer-arn "$lb"; then
            log_success "Successfully deleted load balancer: $lb_name"
        else
            log_error "Failed to delete load balancer: $lb_name"
        fi
    done
    
    return 0
}

# Cleanup RDS instances
cleanup_rds_instances() {
    log "Cleaning up RDS instances with prefix $RESOURCE_PREFIX..."
    
    # List RDS instances
    local instances=$(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '${RESOURCE_PREFIX}')].DBInstanceIdentifier" --output text)
    
    if [[ -z "$instances" || "$instances" == "None" ]]; then
        log "No RDS instances found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for instance in $instances; do
        log "Processing RDS instance: $instance"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete RDS instance: $instance"
            continue
        fi
        
        # Check if this is production and require extra confirmation
        if [[ "$ENVIRONMENT" == "production" && "$FORCE_DELETE" != "true" ]]; then
            log_warning "Attempting to delete a production RDS instance: $instance"
            if ! confirm_action "You are about to delete a production RDS instance: $instance"; then
                log "Skipping deletion of production RDS instance: $instance"
                continue
            fi
        fi
        
        local snapshot_identifier=""
        # Create a final snapshot unless force delete is enabled
        if [[ "$FORCE_DELETE" != "true" ]]; then
            snapshot_identifier="${instance}-final-snapshot-$(date +%Y%m%d%H%M%S)"
            log "Creating final snapshot: $snapshot_identifier before deletion..."
            aws rds delete-db-instance --db-instance-identifier "$instance" --final-db-snapshot-identifier "$snapshot_identifier"
            log "Waiting for instance deletion to complete..."
            aws rds wait db-instance-deleted --db-instance-identifier "$instance"
            log_success "Successfully deleted RDS instance with final snapshot: $instance"
        else
            log "Deleting RDS instance without final snapshot: $instance"
            aws rds delete-db-instance --db-instance-identifier "$instance" --skip-final-snapshot
            log "Waiting for instance deletion to complete..."
            aws rds wait db-instance-deleted --db-instance-identifier "$instance"
            log_success "Successfully deleted RDS instance: $instance"
        fi
    done
    
    return 0
}

# Cleanup ElastiCache clusters
cleanup_elasticache() {
    log "Cleaning up ElastiCache clusters with prefix $RESOURCE_PREFIX..."
    
    # List ElastiCache clusters
    local clusters=$(aws elasticache describe-cache-clusters --query "CacheClusters[?contains(CacheClusterId, '${RESOURCE_PREFIX}')].CacheClusterId" --output text)
    
    if [[ -z "$clusters" || "$clusters" == "None" ]]; then
        log "No ElastiCache clusters found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for cluster in $clusters; do
        log "Processing ElastiCache cluster: $cluster"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete ElastiCache cluster: $cluster"
            continue
        fi
        
        # Delete the cluster
        log "Deleting ElastiCache cluster: $cluster"
        if aws elasticache delete-cache-cluster --cache-cluster-id "$cluster"; then
            log "Waiting for ElastiCache cluster deletion to complete..."
            # There's no wait command for ElastiCache, so we'll poll
            local status="available"
            while [[ "$status" != "None" && "$status" != "" ]]; do
                sleep 30
                status=$(aws elasticache describe-cache-clusters --cache-cluster-id "$cluster" --query "CacheClusters[0].CacheClusterStatus" --output text 2>/dev/null || echo "None")
                log "Current status: $status"
            done
            log_success "Successfully deleted ElastiCache cluster: $cluster"
        else
            log_error "Failed to delete ElastiCache cluster: $cluster"
        fi
    done
    
    return 0
}

# Cleanup security groups
cleanup_security_groups() {
    log "Cleaning up security groups with prefix $RESOURCE_PREFIX..."
    
    # List security groups
    local sgs=$(aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '${RESOURCE_PREFIX}')].GroupId" --output text)
    
    if [[ -z "$sgs" || "$sgs" == "None" ]]; then
        log "No security groups found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for sg in $sgs; do
        local sg_name=$(aws ec2 describe-security-groups --group-ids "$sg" --query "SecurityGroups[0].GroupName" --output text)
        log "Processing security group: $sg_name ($sg)"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete security group: $sg_name ($sg)"
            continue
        fi
        
        # Remove all ingress rules
        log "Removing ingress rules from security group: $sg"
        aws ec2 describe-security-groups --group-ids "$sg" --query "SecurityGroups[0].IpPermissions" --output json > /tmp/sg-ingress-$sg.json
        if [[ -s /tmp/sg-ingress-$sg.json && "$(cat /tmp/sg-ingress-$sg.json)" != "[]" ]]; then
            aws ec2 revoke-security-group-ingress --group-id "$sg" --ip-permissions file:///tmp/sg-ingress-$sg.json
        fi
        
        # Remove all egress rules
        log "Removing egress rules from security group: $sg"
        aws ec2 describe-security-groups --group-ids "$sg" --query "SecurityGroups[0].IpPermissionsEgress" --output json > /tmp/sg-egress-$sg.json
        if [[ -s /tmp/sg-egress-$sg.json && "$(cat /tmp/sg-egress-$sg.json)" != "[]" ]]; then
            aws ec2 revoke-security-group-egress --group-id "$sg" --ip-permissions file:///tmp/sg-egress-$sg.json
        fi
        
        rm -f /tmp/sg-ingress-$sg.json /tmp/sg-egress-$sg.json
        
        # Delete the security group
        log "Deleting security group: $sg_name ($sg)"
        if aws ec2 delete-security-group --group-id "$sg"; then
            log_success "Successfully deleted security group: $sg_name ($sg)"
        else
            log_error "Failed to delete security group: $sg_name ($sg). It may still be associated with resources."
        fi
    done
    
    return 0
}

# Cleanup VPC resources
cleanup_vpc_resources() {
    log "Cleaning up VPC resources with prefix $RESOURCE_PREFIX..."
    
    # List VPCs
    local vpcs=$(aws ec2 describe-vpcs --query "Vpcs[?contains(Tags[?Key=='Name'].Value | [0], '${RESOURCE_PREFIX}')].VpcId" --output text)
    
    if [[ -z "$vpcs" || "$vpcs" == "None" ]]; then
        log "No VPCs found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for vpc in $vpcs; do
        local vpc_name=$(aws ec2 describe-vpcs --vpc-ids "$vpc" --query "Vpcs[0].Tags[?Key=='Name'].Value | [0]" --output text)
        log "Processing VPC: $vpc_name ($vpc)"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would delete VPC: $vpc_name ($vpc) and all its resources"
            continue
        fi
        
        # Delete NAT Gateways
        local nat_gateways=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text)
        if [[ -n "$nat_gateways" && "$nat_gateways" != "None" ]]; then
            for nat in $nat_gateways; do
                log "Deleting NAT Gateway: $nat"
                aws ec2 delete-nat-gateway --nat-gateway-id "$nat"
                
                # Wait for the NAT Gateway to be deleted
                log "Waiting for NAT Gateway to be deleted..."
                local state="available"
                while [[ "$state" != "deleted" && "$state" != "None" && "$state" != "" ]]; do
                    sleep 10
                    state=$(aws ec2 describe-nat-gateways --nat-gateway-id "$nat" --query "NatGateways[0].State" --output text 2>/dev/null || echo "None")
                    log "NAT Gateway state: $state"
                done
            done
        fi
        
        # Delete Internet Gateways
        local igws=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[].InternetGatewayId" --output text)
        if [[ -n "$igws" && "$igws" != "None" ]]; then
            for igw in $igws; do
                log "Detaching Internet Gateway: $igw"
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
                
                log "Deleting Internet Gateway: $igw"
                aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
            done
        fi
        
        # Delete Subnets
        local subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" --output text)
        if [[ -n "$subnets" && "$subnets" != "None" ]]; then
            for subnet in $subnets; do
                log "Deleting Subnet: $subnet"
                aws ec2 delete-subnet --subnet-id "$subnet"
            done
        fi
        
        # Delete Route Tables (except the main one)
        local route_tables=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query "RouteTables[?Associations[0].Main != \`true\`].RouteTableId" --output text)
        if [[ -n "$route_tables" && "$route_tables" != "None" ]]; then
            for rt in $route_tables; do
                # Delete route table associations
                local associations=$(aws ec2 describe-route-tables --route-table-id "$rt" --query "RouteTables[0].Associations[?!Main].RouteTableAssociationId" --output text)
                if [[ -n "$associations" && "$associations" != "None" ]]; then
                    for assoc in $associations; do
                        log "Deleting Route Table Association: $assoc"
                        aws ec2 disassociate-route-table --association-id "$assoc"
                    done
                fi
                
                log "Deleting Route Table: $rt"
                aws ec2 delete-route-table --route-table-id "$rt"
            done
        fi
        
        # Delete Network ACLs (except the default one)
        local acls=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$vpc" --query "NetworkAcls[?!IsDefault].NetworkAclId" --output text)
        if [[ -n "$acls" && "$acls" != "None" ]]; then
            for acl in $acls; do
                log "Deleting Network ACL: $acl"
                aws ec2 delete-network-acl --network-acl-id "$acl"
            done
        fi
        
        # Delete VPC Endpoints
        local endpoints=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc" --query "VpcEndpoints[].VpcEndpointId" --output text)
        if [[ -n "$endpoints" && "$endpoints" != "None" ]]; then
            for endpoint in $endpoints; do
                log "Deleting VPC Endpoint: $endpoint"
                aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint"
            done
        fi
        
        # Delete the VPC
        log "Deleting VPC: $vpc_name ($vpc)"
        if aws ec2 delete-vpc --vpc-id "$vpc"; then
            log_success "Successfully deleted VPC: $vpc_name ($vpc)"
        else
            log_error "Failed to delete VPC: $vpc_name ($vpc). It may still have dependencies."
        fi
    done
    
    return 0
}

# Cleanup IAM resources
cleanup_iam_resources() {
    log "Cleaning up IAM resources with prefix $RESOURCE_PREFIX..."
    
    # List IAM roles
    local roles=$(aws iam list-roles --query "Roles[?contains(RoleName, '${RESOURCE_PREFIX}')].RoleName" --output text)
    
    if [[ -n "$roles" && "$roles" != "None" ]]; then
        for role in $roles; do
            log "Processing IAM role: $role"
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "DRY RUN: Would delete IAM role: $role"
                continue
            fi
            
            # Detach all managed policies
            local policies=$(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text)
            if [[ -n "$policies" && "$policies" != "None" ]]; then
                for policy in $policies; do
                    log "Detaching policy $policy from role $role"
                    aws iam detach-role-policy --role-name "$role" --policy-arn "$policy"
                done
            fi
            
            # Delete inline policies
            local inline_policies=$(aws iam list-role-policies --role-name "$role" --query "PolicyNames[]" --output text)
            if [[ -n "$inline_policies" && "$inline_policies" != "None" ]]; then
                for policy in $inline_policies; do
                    log "Deleting inline policy $policy from role $role"
                    aws iam delete-role-policy --role-name "$role" --policy-name "$policy"
                done
            fi
            
            # Delete instance profiles associated with the role
            local profiles=$(aws iam list-instance-profiles-for-role --role-name "$role" --query "InstanceProfiles[].InstanceProfileName" --output text)
            if [[ -n "$profiles" && "$profiles" != "None" ]]; then
                for profile in $profiles; do
                    log "Removing role $role from instance profile $profile"
                    aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role"
                    
                    log "Deleting instance profile $profile"
                    aws iam delete-instance-profile --instance-profile-name "$profile"
                done
            fi
            
            # Delete the role
            log "Deleting IAM role: $role"
            if aws iam delete-role --role-name "$role"; then
                log_success "Successfully deleted IAM role: $role"
            else
                log_error "Failed to delete IAM role: $role"
            fi
        done
    else
        log "No IAM roles found with prefix $RESOURCE_PREFIX."
    fi
    
    # List IAM policies
    local policies=$(aws iam list-policies --scope Local --query "Policies[?contains(PolicyName, '${RESOURCE_PREFIX}')].Arn" --output text)
    
    if [[ -n "$policies" && "$policies" != "None" ]]; then
        for policy_arn in $policies; do
            local policy_name=$(basename "$policy_arn")
            log "Processing IAM policy: $policy_name"
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "DRY RUN: Would delete IAM policy: $policy_name"
                continue
            fi
            
            # Delete policy versions (except the default version)
            local versions=$(aws iam list-policy-versions --policy-arn "$policy_arn" --query "Versions[?!IsDefaultVersion].VersionId" --output text)
            if [[ -n "$versions" && "$versions" != "None" ]]; then
                for version in $versions; do
                    log "Deleting policy version $version from policy $policy_name"
                    aws iam delete-policy-version --policy-arn "$policy_arn" --version-id "$version"
                done
            fi
            
            # Delete the policy
            log "Deleting IAM policy: $policy_name"
            if aws iam delete-policy --policy-arn "$policy_arn"; then
                log_success "Successfully deleted IAM policy: $policy_name"
            else
                log_error "Failed to delete IAM policy: $policy_name"
            fi
        done
    else
        log "No IAM policies found with prefix $RESOURCE_PREFIX."
    fi
    
    return 0
}

# Cleanup CloudWatch resources
cleanup_cloudwatch_resources() {
    log "Cleaning up CloudWatch resources with prefix $RESOURCE_PREFIX..."
    
    # List CloudWatch alarms
    local alarms=$(aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName, '${RESOURCE_PREFIX}')].AlarmName" --output text)
    
    if [[ -n "$alarms" && "$alarms" != "None" ]]; then
        log "Found CloudWatch alarms to delete: $alarms"
        
        if [[ "$DRY_RUN" != "true" ]]; then
            log "Deleting CloudWatch alarms..."
            aws cloudwatch delete-alarms --alarm-names $alarms
            log_success "Successfully deleted CloudWatch alarms"
        else
            log "DRY RUN: Would delete CloudWatch alarms: $alarms"
        fi
    else
        log "No CloudWatch alarms found with prefix $RESOURCE_PREFIX."
    fi
    
    # List CloudWatch dashboards
    local dashboards=$(aws cloudwatch list-dashboards --query "DashboardEntries[?contains(DashboardName, '${RESOURCE_PREFIX}')].DashboardName" --output text)
    
    if [[ -n "$dashboards" && "$dashboards" != "None" ]]; then
        for dashboard in $dashboards; do
            log "Processing CloudWatch dashboard: $dashboard"
            
            if [[ "$DRY_RUN" != "true" ]]; then
                log "Deleting CloudWatch dashboard: $dashboard"
                aws cloudwatch delete-dashboards --dashboard-names "$dashboard"
                log_success "Successfully deleted CloudWatch dashboard: $dashboard"
            else
                log "DRY RUN: Would delete CloudWatch dashboard: $dashboard"
            fi
        done
    else
        log "No CloudWatch dashboards found with prefix $RESOURCE_PREFIX."
    fi
    
    # List CloudWatch log groups
    local log_groups=$(aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '/${RESOURCE_PREFIX}') || contains(logGroupName, '${RESOURCE_PREFIX}/')].logGroupName" --output text)
    
    if [[ -n "$log_groups" && "$log_groups" != "None" ]]; then
        for log_group in $log_groups; do
            log "Processing CloudWatch log group: $log_group"
            
            if [[ "$DRY_RUN" != "true" ]]; then
                log "Deleting CloudWatch log group: $log_group"
                aws logs delete-log-group --log-group-name "$log_group"
                log_success "Successfully deleted CloudWatch log group: $log_group"
            else
                log "DRY RUN: Would delete CloudWatch log group: $log_group"
            fi
        done
    else
        log "No CloudWatch log groups found with prefix $RESOURCE_PREFIX."
    fi
    
    return 0
}

# Cleanup KMS keys
cleanup_kms_keys() {
    log "Cleaning up KMS keys with alias prefix $RESOURCE_PREFIX..."
    
    # List KMS key aliases
    local aliases=$(aws kms list-aliases --query "Aliases[?contains(AliasName, '${RESOURCE_PREFIX}')].AliasName" --output text)
    
    if [[ -z "$aliases" || "$aliases" == "None" ]]; then
        log "No KMS key aliases found with prefix $RESOURCE_PREFIX."
        return 0
    fi
    
    for alias in $aliases; do
        log "Processing KMS key with alias: $alias"
        
        # Get the key ID from the alias
        local key_id=$(aws kms list-aliases --query "Aliases[?AliasName=='$alias'].TargetKeyId" --output text)
        
        if [[ -z "$key_id" || "$key_id" == "None" ]]; then
            log_warning "Could not find key ID for alias: $alias"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY RUN: Would schedule deletion of KMS key: $key_id (alias: $alias)"
            continue
        fi
        
        # Check if key is already scheduled for deletion
        local key_state=$(aws kms describe-key --key-id "$key_id" --query "KeyMetadata.KeyState" --output text)
        
        if [[ "$key_state" == "PendingDeletion" ]]; then
            log "KMS key $key_id is already scheduled for deletion."
            continue
        fi
        
        # Schedule key deletion (default 7 days waiting period)
        log "Scheduling deletion of KMS key: $key_id (alias: $alias)"
        if aws kms schedule-key-deletion --key-id "$key_id" --pending-window-in-days 7; then
            log_success "Successfully scheduled deletion of KMS key: $key_id (alias: $alias)"
        else
            log_error "Failed to schedule deletion of KMS key: $key_id (alias: $alias)"
        fi
    done
    
    return 0
}

# Cleanup Cognito resources
cleanup_cognito_resources() {
    log "Cleaning up Cognito resources with prefix $RESOURCE_PREFIX..."
    
    # List Cognito user pools
    local user_pools=$(aws cognito-idp list-user-pools --max-results 60 --query "UserPools[?contains(Name, '${RESOURCE_PREFIX}')].Id" --output text)
    
    if [[ -n "$user_pools" && "$user_pools" != "None" ]]; then
        for pool_id in $user_pools; do
            local pool_name=$(aws cognito-idp describe-user-pool --user-pool-id "$pool_id" --query "UserPool.Name" --output text)
            log "Processing Cognito user pool: $pool_name ($pool_id)"
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "DRY RUN: Would delete Cognito user pool: $pool_name ($pool_id)"
                continue
            fi
            
            # List and delete user pool clients
            local clients=$(aws cognito-idp list-user-pool-clients --user-pool-id "$pool_id" --query "UserPoolClients[].ClientId" --output text)
            if [[ -n "$clients" && "$clients" != "None" ]]; then
                for client in $clients; do
                    log "Deleting user pool client: $client"
                    aws cognito-idp delete-user-pool-client --user-pool-id "$pool_id" --client-id "$client"
                done
            fi
            
            # Delete the user pool
            log "Deleting Cognito user pool: $pool_name ($pool_id)"
            if aws cognito-idp delete-user-pool --user-pool-id "$pool_id"; then
                log_success "Successfully deleted Cognito user pool: $pool_name ($pool_id)"
            else
                log_error "Failed to delete Cognito user pool: $pool_name ($pool_id)"
            fi
        done
    else
        log "No Cognito user pools found with prefix $RESOURCE_PREFIX."
    fi
    
    # List Cognito identity pools
    local identity_pools=$(aws cognito-identity list-identity-pools --max-results 60 --query "IdentityPools[?contains(IdentityPoolName, '${RESOURCE_PREFIX}')].IdentityPoolId" --output text)
    
    if [[ -n "$identity_pools" && "$identity_pools" != "None" ]]; then
        for pool_id in $identity_pools; do
            local pool_name=$(aws cognito-identity describe-identity-pool --identity-pool-id "$pool_id" --query "IdentityPoolName" --output text)
            log "Processing Cognito identity pool: $pool_name ($pool_id)"
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "DRY RUN: Would delete Cognito identity pool: $pool_name ($pool_id)"
                continue
            fi
            
            # Delete the identity pool
            log "Deleting Cognito identity pool: $pool_name ($pool_id)"
            if aws cognito-identity delete-identity-pool --identity-pool-id "$pool_id"; then
                log_success "Successfully deleted Cognito identity pool: $pool_name ($pool_id)"
            else
                log_error "Failed to delete Cognito identity pool: $pool_name ($pool_id)"
            fi
        done
    else
        log "No Cognito identity pools found with prefix $RESOURCE_PREFIX."
    fi
    
    return 0
}

# Generate a report of cleaned up resources
generate_report() {
    log "Generating cleanup report..."
    
    echo "" >> "$LOG_FILE"
    echo "=======================================================" >> "$LOG_FILE"
    echo "              CLEANUP SUMMARY REPORT                    " >> "$LOG_FILE"
    echo "=======================================================" >> "$LOG_FILE"
    echo "Environment: $ENVIRONMENT" >> "$LOG_FILE"
    echo "AWS Region: $AWS_REGION" >> "$LOG_FILE"
    echo "Date and Time: $(date)" >> "$LOG_FILE"
    echo "Dry Run: $DRY_RUN" >> "$LOG_FILE"
    echo "Force Delete: $FORCE_DELETE" >> "$LOG_FILE"
    echo "-------------------------------------------------------" >> "$LOG_FILE"
    
    local success_count=$(grep -c "SUCCESS:" "$LOG_FILE")
    local error_count=$(grep -c "ERROR:" "$LOG_FILE")
    local warning_count=$(grep -c "WARNING:" "$LOG_FILE")
    
    echo "Resources successfully deleted: $success_count" >> "$LOG_FILE"
    echo "Resources with errors: $error_count" >> "$LOG_FILE"
    echo "Warnings: $warning_count" >> "$LOG_FILE"
    echo "-------------------------------------------------------" >> "$LOG_FILE"
    echo "See the complete log for details: $LOG_FILE" >> "$LOG_FILE"
    echo "=======================================================" >> "$LOG_FILE"
    
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    echo "              CLEANUP SUMMARY REPORT                    "
    echo -e "${GREEN}=======================================================${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "AWS Region: $AWS_REGION"
    echo "Date and Time: $(date)"
    echo "Dry Run: $DRY_RUN"
    echo "Force Delete: $FORCE_DELETE"
    echo "-------------------------------------------------------"
    
    echo -e "${GREEN}Resources successfully deleted: $success_count${NC}"
    echo -e "${RED}Resources with errors: $error_count${NC}"
    echo -e "${YELLOW}Warnings: $warning_count${NC}"
    echo "-------------------------------------------------------"
    echo "See the complete log for details: $LOG_FILE"
    echo -e "${GREEN}=======================================================${NC}"
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --force)
                FORCE_DELETE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --skip-confirmation)
                SKIP_CONFIRMATION="true"
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Update resource prefix after parsing
    RESOURCE_PREFIX="${APP_NAME}-${ENVIRONMENT}"
    
    # Update log file name
    LOG_FILE="/tmp/cleanup-resources-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S).log"
    
    # Initialize the log file
    touch "$LOG_FILE"
    echo "Amira Wellness Resource Cleanup - $(date)" > "$LOG_FILE"
    echo "Environment: $ENVIRONMENT" >> "$LOG_FILE"
    echo "AWS Region: $AWS_REGION" >> "$LOG_FILE"
    echo "Dry Run: $DRY_RUN" >> "$LOG_FILE"
    echo "Force Delete: $FORCE_DELETE" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
}

# Print usage information
print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "This script automates the cleanup of AWS resources created for the"
    echo "Amira Wellness application."
    echo ""
    echo "Options:"
    echo "  --environment     Target environment to clean up (default: development)"
    echo "  --region          AWS region (default: us-east-1)"
    echo "  --force           Force deletion of resources that might contain data"
    echo "  --dry-run         Show what would be deleted without taking action"
    echo "  --skip-confirmation Skip confirmation prompts"
    echo "  --help            Display usage information"
    echo ""
    echo "Examples:"
    echo "  $0 --environment development"
    echo "  $0 --environment staging --force"
    echo "  $0 --dry-run --environment development"
}

# Main function
main() {
    # Parse command-line arguments
    parse_args "$@"
    
    log "Starting cleanup of Amira Wellness resources for environment: $ENVIRONMENT"
    log "AWS Region: $AWS_REGION"
    log "Resource prefix: $RESOURCE_PREFIX"
    log "Force delete: $FORCE_DELETE"
    log "Dry run: $DRY_RUN"
    
    # Check AWS CLI
    if ! check_aws_cli; then
        log_error "AWS CLI check failed. Please ensure AWS CLI is installed and configured."
        return 1
    fi
    
    # If this is a production environment, require explicit confirmation
    if [[ "$ENVIRONMENT" == "production" && "$SKIP_CONFIRMATION" != "true" ]]; then
        log_warning "You are targeting the PRODUCTION environment for resource cleanup."
        if ! confirm_action "You are about to delete resources in the PRODUCTION environment"; then
            log_error "Operation cancelled by user."
            return 1
        fi
    elif [[ "$DRY_RUN" != "true" && "$SKIP_CONFIRMATION" != "true" ]]; then
        # For non-production, still confirm
        if ! confirm_action "You are about to delete resources in the $ENVIRONMENT environment"; then
            log_error "Operation cancelled by user."
            return 1
        fi
    fi
    
    # Execute cleanup functions in the right order to handle dependencies
    
    # First, disable CloudFront distributions
    cleanup_cloudfront
    
    # Scale down ECS services to 0
    cleanup_ecs_resources
    
    # Delete load balancers and target groups
    cleanup_load_balancers
    
    # Clean up RDS instances
    cleanup_rds_instances
    
    # Clean up ElastiCache clusters
    cleanup_elasticache
    
    # Clean up S3 buckets
    cleanup_s3_buckets
    
    # Clean up Cognito resources
    cleanup_cognito_resources
    
    # Clean up KMS keys
    cleanup_kms_keys
    
    # Clean up CloudWatch resources
    cleanup_cloudwatch_resources
    
    # Clean up IAM resources
    cleanup_iam_resources
    
    # Clean up security groups
    cleanup_security_groups
    
    # Clean up VPC resources
    cleanup_vpc_resources
    
    # Generate cleanup report
    generate_report
    
    log "Cleanup process completed. See $LOG_FILE for details."
    
    return 0
}

# Execute the main function with all provided arguments
main "$@"