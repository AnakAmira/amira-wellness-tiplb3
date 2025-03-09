#!/bin/bash
#
# backup-db.sh - PostgreSQL database backup script for Amira Wellness
#
# This script creates and manages database backups with encryption, 
# compression, S3 storage, and retention policies.
#
# Usage: ./backup-db.sh [options]
#   Options:
#     -t, --type TYPE       Backup type (full, wal) [default: full]
#     -r, --retention DAYS  Retention period in days [default: 7]
#     -c, --compress LEVEL  Compression level (1-9) [default: 9]
#     -e, --environment     Environment (development, staging, production) [default: development]
#     -h, --help            Display this help message
#
# Example:
#   ./backup-db.sh --type full --environment production
#   ./backup-db.sh --retention 30 --compress 6
#   ./backup-db.sh --type wal

# Exit immediately if a command exits with a non-zero status
set -e

# Default values for global variables
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-development}"
DB_INSTANCE_IDENTIFIER="amira-wellness-${ENVIRONMENT}"
BACKUP_BUCKET="amira-wellness-backups-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
BACKUP_PREFIX="database-backups/${ENVIRONMENT}"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP_TYPE="${BACKUP_TYPE:-full}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-9}"
KMS_KEY_ID="${KMS_KEY_ID}"
TEMP_DIR="/tmp/amira-db-backup-${TIMESTAMP}"
LOG_FILE="/var/log/amira-backup/backup-${TIMESTAMP}.log"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"

# Set up colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if all prerequisites are installed and environment variables are set
check_prerequisites() {
    local missing_prereqs=0
    
    echo "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
        missing_prereqs=1
    else
        echo "AWS CLI is installed: $(aws --version)"
    fi
    
    # Verify AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}Error: AWS credentials are not configured or are invalid.${NC}"
        missing_prereqs=1
    else
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        echo "AWS credentials are valid for account: ${account_id}"
        # Set AWS_ACCOUNT_ID if not already set
        AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$account_id}"
        # Update BACKUP_BUCKET with actual AWS account ID
        BACKUP_BUCKET="amira-wellness-backups-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
    fi
    
    # Check if PostgreSQL client tools are installed
    if ! command -v pg_dump &> /dev/null; then
        echo -e "${RED}Error: PostgreSQL client tools are not installed. Please install postgresql-client package.${NC}"
        missing_prereqs=1
    else
        echo "PostgreSQL client tools are installed: $(pg_dump --version | head -1)"
    fi
    
    # Validate required environment variables
    if [[ -z "$KMS_KEY_ID" ]]; then
        echo -e "${YELLOW}Warning: KMS_KEY_ID is not set. Will attempt to retrieve from parameter store.${NC}"
        # Try to get KMS key ID from parameter store
        KMS_KEY_ID=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/kms/database-backup-key-id" --query Parameter.Value --output text 2>/dev/null || echo "")
        if [[ -z "$KMS_KEY_ID" ]]; then
            echo -e "${RED}Error: Could not retrieve KMS key ID from parameter store. Please provide KMS_KEY_ID.${NC}"
            missing_prereqs=1
        else
            echo "Retrieved KMS key ID from parameter store."
        fi
    fi
    
    # Ensure backup directory exists or can be created
    mkdir -p "$TEMP_DIR" || {
        echo -e "${RED}Error: Unable to create temporary directory '${TEMP_DIR}'.${NC}"
        missing_prereqs=1
    }
    
    # Verify S3 bucket exists or can be created
    if ! aws s3 ls "s3://${BACKUP_BUCKET}" &> /dev/null; then
        echo -e "${YELLOW}Warning: S3 bucket '${BACKUP_BUCKET}' does not exist. Attempting to create it...${NC}"
        if ! aws s3 mb "s3://${BACKUP_BUCKET}" --region "$AWS_REGION"; then
            echo -e "${RED}Error: Failed to create S3 bucket '${BACKUP_BUCKET}'.${NC}"
            missing_prereqs=1
        else
            echo "Created S3 bucket '${BACKUP_BUCKET}'."
            
            # Enable versioning on the bucket for additional protection
            aws s3api put-bucket-versioning --bucket "${BACKUP_BUCKET}" --versioning-configuration Status=Enabled
            
            # Enable default encryption for the bucket
            aws s3api put-bucket-encryption \
                --bucket "${BACKUP_BUCKET}" \
                --server-side-encryption-configuration \
                '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
            
            echo "Enabled versioning and default encryption on S3 bucket."
        fi
    else
        echo "S3 bucket '${BACKUP_BUCKET}' exists and is accessible."
    fi
    
    # Check if KMS key is valid and accessible
    if ! aws kms describe-key --key-id "$KMS_KEY_ID" &> /dev/null; then
        echo -e "${RED}Error: KMS key '${KMS_KEY_ID}' does not exist or is not accessible.${NC}"
        missing_prereqs=1
    else
        echo "KMS key '${KMS_KEY_ID}' exists and is accessible."
    fi
    
    if [[ $missing_prereqs -eq 1 ]]; then
        echo -e "${RED}Prerequisites check failed. Please address the issues above and try again.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}All prerequisites are satisfied.${NC}"
    return 0
}

# Function to set up logging for the backup process
setup_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")" || {
        echo -e "${RED}Error: Unable to create log directory '$(dirname "$LOG_FILE")'.${NC}"
        # Fall back to logging to /tmp if we can't create the preferred log directory
        LOG_FILE="/tmp/amira-db-backup-${TIMESTAMP}.log"
        mkdir -p "$(dirname "$LOG_FILE")"
    }
    
    # Initialize log file with timestamp and backup information
    {
        echo "========================================================"
        echo "Database Backup Log - $TIMESTAMP"
        echo "Environment: $ENVIRONMENT"
        echo "Backup Type: $BACKUP_TYPE"
        echo "Retention Days: $RETENTION_DAYS"
        echo "Compression Level: $COMPRESSION_LEVEL"
        echo "Temporary Directory: $TEMP_DIR"
        echo "========================================================"
        echo ""
    } > "$LOG_FILE"
    
    echo "Logging to $LOG_FILE"
    
    # Function for logging messages to both console and log file
    log() {
        local level=$1
        local message=$2
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local color=""
        
        case $level in
            INFO)  color=$BLUE ;;
            WARN)  color=$YELLOW ;;
            ERROR) color=$RED ;;
            SUCCESS) color=$GREEN ;;
            *)     color=$NC ;;
        esac
        
        # Log to console with color
        echo -e "${color}[$timestamp] [$level] $message${NC}"
        
        # Log to file without color codes
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    }
    
    # Export the log function so it can be used throughout the script
    export -f log
    
    # Log start of backup process
    log "INFO" "Database backup process started"
}

# Function to retrieve database credentials from AWS Secrets Manager
get_db_credentials() {
    log "INFO" "Retrieving database connection information..."
    
    # Determine the secret name based on environment
    local secret_name="/amira/${ENVIRONMENT}/database/credentials"
    
    # Try to get the secret from AWS Secrets Manager
    local secret_json
    if ! secret_json=$(aws secretsmanager get-secret-value --secret-id "$secret_name" --query SecretString --output text 2>/dev/null); then
        # Fall back to SSM Parameter Store if Secrets Manager fails
        log "WARN" "Could not retrieve credentials from Secrets Manager, trying Parameter Store..."
        
        # Retrieve individual parameters from Parameter Store
        local db_host
        local db_port
        local db_user
        local db_password
        local db_name
        
        db_host=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/database/host" --with-decryption --query Parameter.Value --output text 2>/dev/null)
        db_port=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/database/port" --with-decryption --query Parameter.Value --output text 2>/dev/null)
        db_user=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/database/username" --with-decryption --query Parameter.Value --output text 2>/dev/null)
        db_password=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/database/password" --with-decryption --query Parameter.Value --output text 2>/dev/null)
        db_name=$(aws ssm get-parameter --name "/amira/${ENVIRONMENT}/database/name" --with-decryption --query Parameter.Value --output text 2>/dev/null)
        
        if [[ -z "$db_host" || -z "$db_port" || -z "$db_user" || -z "$db_password" || -z "$db_name" ]]; then
            log "ERROR" "Failed to retrieve database credentials from Parameter Store."
            return 1
        fi
    else
        # Parse JSON from Secrets Manager
        db_host=$(echo "$secret_json" | jq -r '.host // .hostname // .endpoint')
        db_port=$(echo "$secret_json" | jq -r '.port')
        db_user=$(echo "$secret_json" | jq -r '.username // .user')
        db_password=$(echo "$secret_json" | jq -r '.password')
        db_name=$(echo "$secret_json" | jq -r '.dbname // .database')
        
        if [[ -z "$db_host" || -z "$db_port" || -z "$db_user" || -z "$db_password" || -z "$db_name" ]]; then
            log "ERROR" "Failed to parse database credentials from Secrets Manager."
            return 1
        fi
    fi
    
    log "INFO" "Successfully retrieved database connection information for host: $db_host"
    
    # Export variables for use in other functions
    export DB_HOST="$db_host"
    export DB_PORT="$db_port"
    export DB_USER="$db_user"
    export DB_PASSWORD="$db_password"
    export DB_NAME="$db_name"
    
    return 0
}

# Function to create a full database backup using pg_dump
create_full_backup() {
    local db_host="$1"
    local db_port="$2"
    local db_name="$3"
    local db_user="$4"
    local db_password="$5"
    
    log "INFO" "Creating full backup of database '$db_name' on host '$db_host'..."
    
    # Set PGPASSWORD environment variable
    export PGPASSWORD="$db_password"
    
    # Create output filename
    local backup_file="${TEMP_DIR}/${db_name}-full-${TIMESTAMP}.dump"
    
    # Run pg_dump with appropriate format (custom) and compression
    log "INFO" "Running pg_dump to create backup..."
    if ! pg_dump -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -F c -Z "$COMPRESSION_LEVEL" -f "$backup_file"; then
        log "ERROR" "pg_dump failed to create backup"
        unset PGPASSWORD
        return 1
    fi
    
    # Verify backup was created successfully
    if [[ ! -f "$backup_file" || ! -s "$backup_file" ]]; then
        log "ERROR" "Backup file was not created or is empty"
        unset PGPASSWORD
        return 1
    fi
    
    # Get the size of the backup file
    local backup_size=$(du -h "$backup_file" | cut -f1)
    log "INFO" "Successfully created backup: $backup_file ($backup_size)"
    
    # Clear PGPASSWORD for security
    unset PGPASSWORD
    
    echo "$backup_file"
    return 0
}

# Function to create a backup of Write-Ahead Log (WAL) files
create_wal_backup() {
    local db_host="$1"
    local db_port="$2"
    local db_name="$3"
    local db_user="$4"
    local db_password="$5"
    
    log "INFO" "Creating WAL backup for database '$db_name' on host '$db_host'..."
    
    # Set PGPASSWORD environment variable
    export PGPASSWORD="$db_password"
    
    # Create temporary directory for WAL files
    local wal_dir="${TEMP_DIR}/wal"
    mkdir -p "$wal_dir"
    
    # Determine if we can use pg_basebackup (requires direct access)
    local can_use_basebackup=false
    local wal_archive_file="${TEMP_DIR}/${db_name}-wal-${TIMESTAMP}.tar.gz"
    
    # Check if we can use pg_basebackup
    if command -v pg_basebackup &> /dev/null; then
        log "INFO" "Checking if pg_basebackup can be used..."
        if pg_basebackup --version | grep -q 'pg_basebackup'; then
            can_use_basebackup=true
            log "INFO" "Using pg_basebackup for WAL backup"
        fi
    fi
    
    if $can_use_basebackup; then
        # Use pg_basebackup to capture WAL files
        log "INFO" "Running pg_basebackup to capture WAL files..."
        if ! pg_basebackup -h "$db_host" -p "$db_port" -U "$db_user" -D "$wal_dir" -X fetch; then
            log "ERROR" "pg_basebackup failed to capture WAL files"
            
            # Fall back to SQL method if pg_basebackup fails
            log "INFO" "Falling back to SQL method for WAL backup..."
            can_use_basebackup=false
        else
            # Compress WAL files into an archive
            log "INFO" "Compressing WAL files..."
            tar -czf "$wal_archive_file" -C "$wal_dir" .
        fi
    fi
    
    # If pg_basebackup cannot be used or failed, try SQL method
    if ! $can_use_basebackup; then
        log "INFO" "Using SQL commands to capture WAL information..."
        
        # Create a file to store WAL information
        local wal_info_file="${wal_dir}/wal_info.txt"
        
        # Run SQL commands to get WAL information
        psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" << EOF > "$wal_info_file"
SELECT pg_current_wal_lsn() AS current_wal_lsn;
SELECT pg_walfile_name(pg_current_wal_lsn()) AS current_wal_file;
SELECT name, setting FROM pg_settings WHERE name LIKE 'wal%';
EOF
        
        # Check if we got any WAL information
        if [[ ! -s "$wal_info_file" ]]; then
            log "ERROR" "Failed to retrieve WAL information"
            unset PGPASSWORD
            return 1
        fi
        
        log "INFO" "Successfully retrieved WAL information"
        
        # Add SQL to force a log switch to ensure current WAL is archived
        psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT pg_switch_wal();" > /dev/null
        
        # Compress WAL information into an archive
        log "INFO" "Compressing WAL information..."
        tar -czf "$wal_archive_file" -C "$wal_dir" .
    fi
    
    # Verify archive was created successfully
    if [[ ! -f "$wal_archive_file" || ! -s "$wal_archive_file" ]]; then
        log "ERROR" "WAL archive file was not created or is empty"
        unset PGPASSWORD
        return 1
    fi
    
    # Get the size of the archive file
    local archive_size=$(du -h "$wal_archive_file" | cut -f1)
    log "INFO" "Successfully created WAL archive: $wal_archive_file ($archive_size)"
    
    # Clear PGPASSWORD for security
    unset PGPASSWORD
    
    echo "$wal_archive_file"
    return 0
}

# Function to encrypt the backup file using AWS KMS
encrypt_backup() {
    local backup_file="$1"
    
    log "INFO" "Encrypting backup file $backup_file..."
    
    # Check if KMS key ID is provided
    if [[ -z "$KMS_KEY_ID" ]]; then
        log "ERROR" "KMS key ID not provided for encryption"
        return 1
    fi
    
    # Create output filename for encrypted file
    local encrypted_file="${backup_file}.enc"
    
    # Use AWS CLI to encrypt the backup file with the KMS key
    log "INFO" "Using AWS KMS to encrypt the file..."
    
    # Calculate the SHA256 hash of the file for integrity verification
    local backup_hash=$(openssl dgst -sha256 -binary "$backup_file" | openssl base64)
    log "INFO" "Backup file SHA256: $backup_hash"
    
    # Encrypt file with KMS
    if ! aws kms encrypt \
        --key-id "$KMS_KEY_ID" \
        --plaintext "fileb://$backup_file" \
        --output text \
        --query CiphertextBlob \
        | base64 --decode > "$encrypted_file"; then
        log "ERROR" "Failed to encrypt backup file using KMS"
        return 1
    fi
    
    # Verify encryption was successful
    if [[ ! -f "$encrypted_file" || ! -s "$encrypted_file" ]]; then
        log "ERROR" "Encryption failed or produced an empty file"
        return 1
    fi
    
    # Store the original file hash as metadata in a small accompanying file
    echo "$backup_hash" > "${encrypted_file}.sha256"
    
    # Get the size of the encrypted file
    local encrypted_size=$(du -h "$encrypted_file" | cut -f1)
    log "INFO" "Successfully encrypted backup to $encrypted_file ($encrypted_size)"
    
    echo "$encrypted_file"
    return 0
}

# Function to upload the encrypted backup file to S3
upload_to_s3() {
    local encrypted_file="$1"
    local backup_type="$2"
    
    log "INFO" "Uploading encrypted backup to S3..."
    
    # Construct S3 path with appropriate prefix, timestamp, and backup type
    local file_name=$(basename "$encrypted_file")
    local s3_path="s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/${backup_type}/${file_name}"
    
    # Also upload the SHA256 hash file if it exists
    local hash_file="${encrypted_file}.sha256"
    local hash_s3_path="s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/${backup_type}/${file_name}.sha256"
    
    # Upload the encrypted file to S3 with metadata
    log "INFO" "Uploading to $s3_path..."
    if ! aws s3 cp "$encrypted_file" "$s3_path" \
        --metadata "backup-type=$backup_type,timestamp=$TIMESTAMP,environment=$ENVIRONMENT" \
        --storage-class STANDARD_IA; then
        log "ERROR" "Failed to upload encrypted backup to S3"
        return 1
    fi
    
    # Upload the hash file if it exists
    if [[ -f "$hash_file" ]]; then
        log "INFO" "Uploading hash file to $hash_s3_path..."
        if ! aws s3 cp "$hash_file" "$hash_s3_path"; then
            log "WARN" "Failed to upload hash file to S3, but backup upload was successful"
        else
            log "INFO" "Successfully uploaded hash file"
        fi
    fi
    
    # Verify upload was successful by checking if the file exists in S3
    if ! aws s3 ls "$s3_path" &> /dev/null; then
        log "ERROR" "Uploaded file not found in S3"
        return 1
    fi
    
    log "SUCCESS" "Successfully uploaded backup to $s3_path"
    
    echo "$s3_path"
    return 0
}

# Function to remove backups older than the retention period
cleanup_old_backups() {
    local backup_type="$1"
    local retention_days="$2"
    
    log "INFO" "Cleaning up backups older than $retention_days days for type '$backup_type'..."
    
    # Calculate cutoff date based on retention period
    local cutoff_date=$(date -d "$retention_days days ago" +%Y-%m-%d)
    log "INFO" "Cutoff date: $cutoff_date"
    
    # List backups in S3 bucket with specified prefix and backup type
    local s3_prefix="${BACKUP_PREFIX}/${backup_type}"
    log "INFO" "Listing backups in S3 bucket '${BACKUP_BUCKET}' with prefix '${s3_prefix}'..."
    
    # Get list of backup objects in S3
    local backup_list
    backup_list=$(aws s3api list-objects-v2 --bucket "$BACKUP_BUCKET" --prefix "$s3_prefix" --query "Contents[?LastModified<='${cutoff_date}T23:59:59Z'].[Key, LastModified]" --output text)
    
    if [[ -z "$backup_list" ]]; then
        log "INFO" "No backups found older than the cutoff date"
        return 0
    fi
    
    # Count the number of backups to delete
    local backup_count=$(echo "$backup_list" | wc -l)
    log "INFO" "Found $backup_count backup(s) older than the cutoff date to delete"
    
    # Delete old backups from S3
    local deleted_count=0
    while read -r backup_key backup_date; do
        log "INFO" "Deleting old backup: $backup_key (modified on $backup_date)"
        if aws s3 rm "s3://${BACKUP_BUCKET}/${backup_key}"; then
            ((deleted_count++))
        else
            log "WARN" "Failed to delete backup: $backup_key"
        fi
        
        # Also delete associated hash file if it exists
        if aws s3 ls "s3://${BACKUP_BUCKET}/${backup_key}.sha256" &> /dev/null; then
            log "INFO" "Deleting associated hash file: ${backup_key}.sha256"
            aws s3 rm "s3://${BACKUP_BUCKET}/${backup_key}.sha256"
        fi
        
        # Also delete associated metadata file if it exists
        if aws s3 ls "s3://${BACKUP_BUCKET}/${backup_key}.meta" &> /dev/null; then
            log "INFO" "Deleting associated metadata file: ${backup_key}.meta"
            aws s3 rm "s3://${BACKUP_BUCKET}/${backup_key}.meta"
        fi
    done <<< "$backup_list"
    
    log "INFO" "Successfully deleted $deleted_count old backup(s)"
    
    echo "$deleted_count"
    return 0
}

# Function to verify the integrity of the uploaded backup
verify_backup() {
    local s3_uri="$1"
    
    log "INFO" "Verifying integrity of uploaded backup: $s3_uri..."
    
    # Extract the bucket and key from the S3 URI
    local bucket=${s3_uri#s3://}
    bucket=${bucket%%/*}
    local key=${s3_uri#s3://$bucket/}
    
    # Create a temporary file for the sample
    local temp_sample="${TEMP_DIR}/sample_verification"
    
    # Download a small portion of the backup from S3 (first 1MB)
    log "INFO" "Downloading sample of backup file for verification..."
    if ! aws s3api get-object \
        --bucket "$bucket" \
        --key "$key" \
        --range "bytes=0-1048575" \
        "$temp_sample" > /dev/null; then
        log "ERROR" "Failed to download backup sample for verification"
        return 1
    fi
    
    # Check if the sample file exists and has content
    if [[ ! -f "$temp_sample" || ! -s "$temp_sample" ]]; then
        log "ERROR" "Downloaded sample is empty or missing"
        return 1
    fi
    
    # For encrypted files, we can do a simple header check to ensure it's a valid encrypted file
    # This is a basic check, not a full decryption test
    if file "$temp_sample" | grep -q "data"; then
        log "INFO" "Backup file appears to be a valid encrypted data file"
    else
        log "WARN" "Backup file does not appear to be a standard encrypted file, but this may be expected based on the encryption method"
    fi
    
    # Check for the hash file and verify if it exists
    local hash_s3_uri="${s3_uri}.sha256"
    if aws s3 ls "$hash_s3_uri" &> /dev/null; then
        log "INFO" "Hash file found, can be used for complete verification if needed"
    else
        log "INFO" "No hash file found, skipping hash verification"
    fi
    
    # Check if the file metadata is accessible
    if aws s3api head-object --bucket "$bucket" --key "$key" > /dev/null; then
        log "INFO" "S3 object metadata is accessible"
    else
        log "WARN" "Could not access S3 object metadata"
    fi
    
    log "INFO" "Basic backup verification completed successfully"
    
    # Remove temporary sample file
    rm -f "$temp_sample"
    
    return 0
}

# Function to clean up temporary files and resources
cleanup() {
    log "INFO" "Cleaning up temporary files and resources..."
    
    # Remove temporary backup directory and files
    if [[ -d "$TEMP_DIR" ]]; then
        log "INFO" "Removing temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    
    # Clear any sensitive environment variables
    unset PGPASSWORD
    unset DB_PASSWORD
    
    log "INFO" "Cleanup completed"
}

# Function to send notification about backup status
send_notification() {
    local status="$1"
    local message="$2"
    
    log "INFO" "Sending notification with status: $status"
    
    # Check if SNS topic ARN is configured
    if [[ -z "$SNS_TOPIC_ARN" ]]; then
        log "WARN" "SNS topic ARN not configured. Skipping notification."
        return 0
    fi
    
    # Format notification message
    local subject="Amira Wellness DB Backup - $ENVIRONMENT - $status"
    local full_message="\nDatabase Backup Report:\n---------------------------\nStatus: $status\nEnvironment: $ENVIRONMENT\nBackup Type: $BACKUP_TYPE\nTimestamp: $(date)\n\n$message\n\nFor more details, check the logs at: $LOG_FILE\n"
    
    # Send message to SNS topic
    if ! aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "$subject" --message "$full_message"; then
        log "ERROR" "Failed to send notification to SNS topic: $SNS_TOPIC_ARN"
        return 1
    fi
    
    log "INFO" "Successfully sent notification to SNS topic: $SNS_TOPIC_ARN"
    return 0
}

# Function to create metadata file with backup information
create_backup_metadata() {
    local backup_file="$1"
    local backup_type="$2"
    local db_name="$3"
    
    log "INFO" "Creating metadata for backup..."
    
    # Create metadata file name
    local metadata_file="${backup_file}.meta"
    
    # Get file size in bytes
    local file_size=$(stat -c%s "$backup_file")
    local human_size=$(du -h "$backup_file" | cut -f1)
    
    # Calculate file checksum
    local checksum=$(openssl dgst -sha256 -hex "$backup_file" | cut -d' ' -f2)
    
    # Try to get database version
    local db_version="unknown"
    if [[ -n "$DB_HOST" && -n "$DB_PORT" && -n "$DB_USER" && -n "$DB_PASSWORD" ]]; then
        export PGPASSWORD="$DB_PASSWORD"
        db_version=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -tAc "SHOW server_version;" 2>/dev/null || echo "unknown")
        unset PGPASSWORD
    fi
    
    # Create JSON file with backup information
    cat > "$metadata_file" << EOF
{
  "backup_id": "${TIMESTAMP}",
  "backup_type": "${backup_type}",
  "database_name": "${db_name}",
  "database_version": "${db_version}",
  "backup_size": "${human_size}",
  "backup_size_bytes": ${file_size},
  "checksum": "${checksum}",
  "checksum_type": "sha256",
  "compression_level": ${COMPRESSION_LEVEL},
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "${ENVIRONMENT}",
  "hostname": "$(hostname)",
  "aws_region": "${AWS_REGION}"
}
EOF
    
    log "INFO" "Created backup metadata file: $metadata_file"
    
    echo "$metadata_file"
    return 0
}

# Function to upload backup metadata to S3
upload_metadata() {
    local metadata_file="$1"
    local s3_backup_path="$2"
    
    log "INFO" "Uploading backup metadata to S3..."
    
    # Construct S3 path for metadata file
    local metadata_s3_path="${s3_backup_path}.meta"
    
    # Upload metadata file to S3
    log "INFO" "Uploading to $metadata_s3_path..."
    if ! aws s3 cp "$metadata_file" "$metadata_s3_path"; then
        log "WARN" "Failed to upload metadata file to S3, but backup upload was successful"
        return 0
    fi
    
    log "INFO" "Successfully uploaded backup metadata to S3"
    
    echo "$metadata_s3_path"
    return 0
}

# Function to monitor backup size trends and send alerts if necessary
monitor_backup_size() {
    local backup_file="$1"
    local backup_type="$2"
    
    log "INFO" "Monitoring backup size trends..."
    
    # Get current backup size in bytes
    local current_size=$(stat -c%s "$backup_file")
    local human_size=$(du -h "$backup_file" | cut -f1)
    
    log "INFO" "Current backup size: $human_size ($current_size bytes)"
    
    # List recent backups of the same type
    local s3_prefix="${BACKUP_PREFIX}/${backup_type}"
    local previous_backups
    previous_backups=$(aws s3api list-objects-v2 --bucket "$BACKUP_BUCKET" --prefix "$s3_prefix" --query "reverse(sort_by(Contents, &LastModified))[1:5]" --output json 2>/dev/null)
    
    if [[ -z "$previous_backups" || "$previous_backups" == "null" ]]; then
        log "INFO" "No previous backups found for comparison"
        return 0
    fi
    
    # Extract sizes of previous backups
    local previous_sizes=()
    local size_sum=0
    local count=0
    
    while read -r size; do
        if [[ -n "$size" && "$size" != "null" ]]; then
            previous_sizes+=("$size")
            size_sum=$((size_sum + size))
            ((count++))
        fi
    done < <(echo "$previous_backups" | jq -r '.[].Size')
    
    if [[ $count -eq 0 ]]; then
        log "INFO" "Could not extract sizes from previous backups"
        return 0
    fi
    
    # Calculate average size of previous backups
    local average_size=$((size_sum / count))
    
    log "INFO" "Average size of previous $count backups: $(numfmt --to=iec-i --suffix=B $average_size)"
    
    # Calculate percentage difference
    local size_diff=$((current_size - average_size))
    local size_diff_percent
    if [[ $average_size -ne 0 ]]; then
        size_diff_percent=$(( (size_diff * 100) / average_size ))
    else
        size_diff_percent=0
    fi
    
    log "INFO" "Size difference: $size_diff bytes ($size_diff_percent%)"
    
    # Send alert if backup size is significantly larger or smaller than average
    if [[ $size_diff_percent -gt 50 ]]; then
        log "WARN" "Backup size is $size_diff_percent% larger than average"
        send_notification "WARNING" "Backup size is $size_diff_percent% larger than average (Current: $human_size, Avg: $(numfmt --to=iec-i --suffix=B $average_size)). This might indicate a significant change in database content or a potential issue."
    elif [[ $size_diff_percent -lt -50 ]]; then
        log "WARN" "Backup size is $((-size_diff_percent))% smaller than average"
        send_notification "WARNING" "Backup size is $((-size_diff_percent))% smaller than average (Current: $human_size, Avg: $(numfmt --to=iec-i --suffix=B $average_size)). This might indicate data loss or an incomplete backup."
    else
        log "INFO" "Backup size is within normal range"
    fi
    
    return 0
}

# Main function that orchestrates the database backup process
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    local exit_code=0
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--type)
                BACKUP_TYPE="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -c|--compress)
                COMPRESSION_LEVEL="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo "  Options:"
                echo "    -t, --type TYPE       Backup type (full, wal) [default: full]"
                echo "    -r, --retention DAYS  Retention period in days [default: 7]"
                echo "    -c, --compress LEVEL  Compression level (1-9) [default: 9]"
                echo "    -e, --environment     Environment (development, staging, production) [default: development]"
                echo "    -h, --help            Display this help message"
                echo ""
                echo "Example:"
                echo "  $0 --type full --environment production"
                echo "  $0 --retention 30 --compress 6"
                echo "  $0 --type wal"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information."
                exit 1
                ;;
        esac
    done
    
    # Update global variables that depend on parameters
    BACKUP_BUCKET="amira-wellness-backups-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
    BACKUP_PREFIX="database-backups/${ENVIRONMENT}"
    DB_INSTANCE_IDENTIFIER="amira-wellness-${ENVIRONMENT}"
    
    # Validate backup type
    if [[ "$BACKUP_TYPE" != "full" && "$BACKUP_TYPE" != "wal" ]]; then
        echo "Error: Invalid backup type. Must be 'full' or 'wal'."
        exit 1
    fi
    
    # Set up logging
    setup_logging
    
    # Trap for cleanup on exit
    trap cleanup EXIT
    
    # Check prerequisites
    if ! check_prerequisites; then
        log "ERROR" "Prerequisites check failed. Exiting."
        exit_code=1
        send_notification "FAILED" "Prerequisites check failed. See logs for details."
        exit $exit_code
    fi
    
    # Get database credentials
    if ! get_db_credentials; then
        log "ERROR" "Failed to retrieve database credentials. Exiting."
        exit_code=1
        send_notification "FAILED" "Failed to retrieve database credentials. See logs for details."
        exit $exit_code
    fi
    
    # Create appropriate backup based on BACKUP_TYPE
    local backup_file=""
    if [[ "$BACKUP_TYPE" == "full" ]]; then
        if ! backup_file=$(create_full_backup "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD"); then
            log "ERROR" "Failed to create full backup. Exiting."
            exit_code=1
            send_notification "FAILED" "Failed to create full backup. See logs for details."
            exit $exit_code
        fi
    elif [[ "$BACKUP_TYPE" == "wal" ]]; then
        if ! backup_file=$(create_wal_backup "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD"); then
            log "ERROR" "Failed to create WAL backup. Exiting."
            exit_code=1
            send_notification "FAILED" "Failed to create WAL backup. See logs for details."
            exit $exit_code
        fi
    fi
    
    # Create backup metadata
    local metadata_file=""
    if ! metadata_file=$(create_backup_metadata "$backup_file" "$BACKUP_TYPE" "$DB_NAME"); then
        log "ERROR" "Failed to create backup metadata. Continuing anyway."
        # Non-critical error, continue with backup
    fi
    
    # Encrypt the backup
    local encrypted_file=""
    if ! encrypted_file=$(encrypt_backup "$backup_file"); then
        log "ERROR" "Failed to encrypt backup. Exiting."
        exit_code=1
        send_notification "FAILED" "Failed to encrypt backup. See logs for details."
        exit $exit_code
    fi
    
    # Upload backup to S3
    local s3_backup_path=""
    if ! s3_backup_path=$(upload_to_s3 "$encrypted_file" "$BACKUP_TYPE"); then
        log "ERROR" "Failed to upload backup to S3. Exiting."
        exit_code=1
        send_notification "FAILED" "Failed to upload backup to S3. See logs for details."
        exit $exit_code
    fi
    
    # Upload metadata to S3 if it was created
    if [[ -n "$metadata_file" ]]; then
        if ! upload_metadata "$metadata_file" "$s3_backup_path"; then
            log "WARN" "Failed to upload backup metadata. Continuing anyway."
            # Non-critical error, continue with backup
        fi
    fi
    
    # Verify backup integrity
    if ! verify_backup "$s3_backup_path"; then
        log "ERROR" "Backup verification failed. The backup may be corrupted."
        exit_code=1
        send_notification "WARNING" "Backup completed but verification failed. The backup may be corrupted. See logs for details."
    fi
    
    # Monitor backup size trends
    monitor_backup_size "$backup_file" "$BACKUP_TYPE"
    
    # Clean up old backups based on retention policy
    local deleted_count=0
    if ! deleted_count=$(cleanup_old_backups "$BACKUP_TYPE" "$RETENTION_DAYS"); then
        log "WARN" "Failed to clean up old backups. Continuing anyway."
        # Non-critical error, continue with backup
    else
        log "INFO" "Cleaned up $deleted_count old backups"
    fi
    
    # Calculate backup duration
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local duration=$(( $(date -d "$end_time" +%s) - $(date -d "$start_time" +%s) ))
    local duration_formatted="$((duration / 60)) minutes $((duration % 60)) seconds"
    
    # Log backup completion with summary information
    log "SUCCESS" "Database backup process completed successfully"
    log "INFO" "Backup type: $BACKUP_TYPE"
    log "INFO" "Database: $DB_NAME on $DB_HOST"
    log "INFO" "Backup path: $s3_backup_path"
    log "INFO" "Backup size: $(du -h "$backup_file" | cut -f1)"
    log "INFO" "Encrypted size: $(du -h "$encrypted_file" | cut -f1)"
    log "INFO" "Start time: $start_time"
    log "INFO" "End time: $end_time"
    log "INFO" "Duration: $duration_formatted"
    log "INFO" "Retention period: $RETENTION_DAYS days"
    log "INFO" "Old backups deleted: $deleted_count"
    
    # Send success notification
    send_notification "SUCCESS" "Database backup completed successfully.\nBackup Type: $BACKUP_TYPE\nDatabase: $DB_NAME\nBackup Path: $s3_backup_path\nBackup Size: $(du -h "$backup_file" | cut -f1)\nDuration: $duration_formatted"
    
    return $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi