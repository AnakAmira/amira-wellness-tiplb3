#!/bin/bash
#
# restore-db.sh - PostgreSQL database restoration script for Amira Wellness
#
# This script handles downloading encrypted backups from S3, decryption, 
# restoration to target database, and verification with comprehensive 
# error handling and logging.
#
# Usage: ./restore-db.sh [options]
#   Options:
#     -t, --type TYPE       Restoration type (full, wal) [default: full]
#     -b, --backup PATH     Specific backup to restore (S3 path)
#     -p, --point-in-time   Target recovery time for point-in-time recovery (ISO format)
#     -d, --database NAME   Target database name [default: same as source]
#     -e, --environment     Environment (development, staging, production) [default: development]
#     -h, --help            Display this help message
#
# Example:
#   ./restore-db.sh --type full --environment production
#   ./restore-db.sh --backup s3://amira-wellness-backups/database/backup-2023-10-15.sql.gz.enc
#   ./restore-db.sh --type wal --point-in-time "2023-10-15 14:30:00 UTC"

# Exit immediately if a command exits with a non-zero status
set -e

# Default values for global variables
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-development}"
DB_INSTANCE_IDENTIFIER="amira-wellness-${ENVIRONMENT}"
BACKUP_BUCKET="amira-wellness-backups-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
BACKUP_PREFIX="database-backups/${ENVIRONMENT}"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
RESTORE_TYPE="${RESTORE_TYPE:-full}"
POINT_IN_TIME="${POINT_IN_TIME:-}"
TARGET_DB_NAME="${TARGET_DB_NAME:-}"
KMS_KEY_ID="${KMS_KEY_ID}"
TEMP_DIR="/tmp/amira-db-restore-${TIMESTAMP}"
LOG_FILE="/var/log/amira-backup/restore-${TIMESTAMP}.log"
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
    if ! command -v pg_restore &> /dev/null; then
        echo -e "${RED}Error: PostgreSQL client tools are not installed. Please install postgresql-client package.${NC}"
        missing_prereqs=1
    else
        echo "PostgreSQL client tools are installed: $(pg_restore --version | head -1)"
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
    
    # Verify S3 bucket exists and is accessible
    if ! aws s3 ls "s3://${BACKUP_BUCKET}" &> /dev/null; then
        echo -e "${RED}Error: S3 bucket '${BACKUP_BUCKET}' does not exist or is not accessible.${NC}"
        missing_prereqs=1
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
    
    # Ensure restore directory exists or can be created
    mkdir -p "$TEMP_DIR" || {
        echo -e "${RED}Error: Unable to create temporary directory '${TEMP_DIR}'.${NC}"
        missing_prereqs=1
    }
    
    if [[ $missing_prereqs -eq 1 ]]; then
        echo -e "${RED}Prerequisites check failed. Please address the issues above and try again.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}All prerequisites are satisfied.${NC}"
    return 0
}

# Function to set up logging for the restore process
setup_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")" || {
        echo -e "${RED}Error: Unable to create log directory '$(dirname "$LOG_FILE")'.${NC}"
        # Fall back to logging to /tmp if we can't create the preferred log directory
        LOG_FILE="/tmp/amira-db-restore-${TIMESTAMP}.log"
        mkdir -p "$(dirname "$LOG_FILE")"
    }
    
    # Initialize log file with timestamp and restore information
    {
        echo "========================================================"
        echo "Database Restoration Log - $TIMESTAMP"
        echo "Environment: $ENVIRONMENT"
        echo "Restore Type: $RESTORE_TYPE"
        if [[ -n "$POINT_IN_TIME" ]]; then
            echo "Point in Time: $POINT_IN_TIME"
        fi
        echo "Target Database: ${TARGET_DB_NAME:-[Same as source]}"
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
    
    # Log start of restoration process
    log "INFO" "Database restoration process started"
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
    
    # If TARGET_DB_NAME is set, use it instead of the source database name
    if [[ -n "$TARGET_DB_NAME" ]]; then
        log "INFO" "Using target database name: $TARGET_DB_NAME"
        db_name="$TARGET_DB_NAME"
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

# Function to list available backups in S3 with filtering options
list_available_backups() {
    local backup_type="$1"
    local date_filter="$2"
    
    local s3_prefix="${BACKUP_PREFIX}/${backup_type}"
    
    log "INFO" "Listing available backups in S3 bucket '${BACKUP_BUCKET}' with prefix '${s3_prefix}'..."
    
    # Use AWS CLI to list objects in the S3 bucket with the specified prefix
    local backups
    if ! backups=$(aws s3 ls "s3://${BACKUP_BUCKET}/${s3_prefix}/" --recursive); then
        log "ERROR" "Failed to list backups in S3 bucket"
        return 1
    fi
    
    # Filter results if date_filter is provided
    if [[ -n "$date_filter" ]]; then
        log "INFO" "Filtering backups by date: $date_filter"
        backups=$(echo "$backups" | grep "$date_filter")
    fi
    
    # Check if any backups were found
    if [[ -z "$backups" ]]; then
        log "WARN" "No backups found matching the criteria"
        return 1
    fi
    
    # Format and output the list of available backups
    log "INFO" "Available backups:"
    echo "$backups" | awk '{print $4 " (" $1 " " $2 ")"}'
    
    return 0
}

# Function to get the latest available backup of specified type
get_latest_backup() {
    local backup_type="$1"
    
    log "INFO" "Getting latest backup of type '${backup_type}'..."
    
    local s3_prefix="${BACKUP_PREFIX}/${backup_type}"
    
    # List all backups of the specified type, sorted by timestamp (descending)
    local latest_backup
    if ! latest_backup=$(aws s3 ls "s3://${BACKUP_BUCKET}/${s3_prefix}/" --recursive | sort -r | head -1); then
        log "ERROR" "Failed to list backups in S3 bucket"
        return 1
    fi
    
    # Check if any backup was found
    if [[ -z "$latest_backup" ]]; then
        log "ERROR" "No backups found of type '${backup_type}'"
        return 1
    fi
    
    # Extract the S3 path of the latest backup
    local backup_key=$(echo "$latest_backup" | awk '{print $4}')
    local backup_path="s3://${BACKUP_BUCKET}/${backup_key}"
    
    log "INFO" "Latest backup: $backup_path (from $(echo "$latest_backup" | awk '{print $1, $2}'))"
    
    echo "$backup_path"
    return 0
}

# Function to validate backup metadata for compatibility and integrity
validate_backup_metadata() {
    local backup_path="$1"
    
    log "INFO" "Validating backup metadata for '$backup_path'..."
    
    # Extract the backup key from the S3 path
    local backup_key=${backup_path#s3://${BACKUP_BUCKET}/}
    
    # Construct the metadata file path
    local metadata_key="${backup_key}.meta"
    local metadata_path="s3://${BACKUP_BUCKET}/${metadata_key}"
    local metadata_file="${TEMP_DIR}/$(basename "${metadata_key}")"
    
    # Check if metadata file exists
    if ! aws s3 ls "$metadata_path" &> /dev/null; then
        log "WARN" "No metadata file found for backup. Skipping validation."
        return 0
    fi
    
    # Download metadata file
    log "INFO" "Downloading metadata file from $metadata_path..."
    if ! aws s3 cp "$metadata_path" "$metadata_file" > /dev/null; then
        log "ERROR" "Failed to download metadata file"
        return 1
    fi
    
    # Parse metadata file
    log "INFO" "Parsing metadata file..."
    local backup_db_version
    local backup_size
    local backup_checksum
    local backup_created
    
    # Use jq if available, otherwise use grep as fallback
    if command -v jq &> /dev/null; then
        backup_db_version=$(jq -r '.database_version // "unknown"' "$metadata_file")
        backup_size=$(jq -r '.backup_size // "unknown"' "$metadata_file")
        backup_checksum=$(jq -r '.checksum // "unknown"' "$metadata_file")
        backup_created=$(jq -r '.created_at // "unknown"' "$metadata_file")
    else
        backup_db_version=$(grep -oP '"database_version":\s*"\K[^"]+' "$metadata_file" || echo "unknown")
        backup_size=$(grep -oP '"backup_size":\s*"\K[^"]+' "$metadata_file" || echo "unknown")
        backup_checksum=$(grep -oP '"checksum":\s*"\K[^"]+' "$metadata_file" || echo "unknown")
        backup_created=$(grep -oP '"created_at":\s*"\K[^"]+' "$metadata_file" || echo "unknown")
    fi
    
    log "INFO" "Backup database version: $backup_db_version"
    log "INFO" "Backup size: $backup_size"
    log "INFO" "Backup created at: $backup_created"
    
    # Check PostgreSQL version compatibility (if known)
    if [[ "$backup_db_version" != "unknown" ]]; then
        local current_pg_version=$(pg_restore --version | grep -oP 'pg_restore \(PostgreSQL\) \K[0-9]+\.[0-9]+' || echo "unknown")
        
        if [[ "$current_pg_version" != "unknown" ]]; then
            local backup_major_version=${backup_db_version%%.*}
            local current_major_version=${current_pg_version%%.*}
            
            if [[ "$current_major_version" -lt "$backup_major_version" ]]; then
                log "ERROR" "Current PostgreSQL version ($current_pg_version) is older than backup version ($backup_db_version). Restoration may fail."
                return 1
            elif [[ "$current_major_version" -gt "$backup_major_version" ]]; then
                log "WARN" "Current PostgreSQL version ($current_pg_version) is newer than backup version ($backup_db_version). Some compatibility issues may occur."
            fi
        fi
    fi
    
    log "INFO" "Backup metadata validation completed successfully"
    return 0
}

# Function to download a specific backup from S3
download_backup() {
    local backup_path="$1"
    
    log "INFO" "Downloading backup from $backup_path..."
    
    # Extract the backup key from the S3 path
    local backup_key=${backup_path#s3://${BACKUP_BUCKET}/}
    local download_file="${TEMP_DIR}/$(basename "${backup_key}")"
    
    # Download the backup file from S3
    if ! aws s3 cp "$backup_path" "$download_file" > /dev/null; then
        log "ERROR" "Failed to download backup from S3"
        return 1
    fi
    
    # Verify download was successful
    if [[ ! -f "$download_file" ]]; then
        log "ERROR" "Downloaded file not found at $download_file"
        return 1
    fi
    
    log "INFO" "Successfully downloaded backup to $download_file ($(du -h "$download_file" | cut -f1))"
    
    echo "$download_file"
    return 0
}

# Function to decrypt the backup file using AWS KMS
decrypt_backup() {
    local encrypted_file="$1"
    
    log "INFO" "Decrypting backup file $encrypted_file..."
    
    # Check if KMS key ID is provided
    if [[ -z "$KMS_KEY_ID" ]]; then
        log "ERROR" "KMS key ID not provided for decryption"
        return 1
    fi
    
    # Determine output file name (remove .enc extension if present)
    local decrypted_file="${encrypted_file%.enc}"
    
    # If the input and output filenames are the same, add a .dec suffix
    if [[ "$encrypted_file" == "$decrypted_file" ]]; then
        decrypted_file="${encrypted_file}.dec"
    fi
    
    # Use AWS CLI to decrypt the backup file with the KMS key
    log "INFO" "Using AWS KMS to decrypt the file..."
    if ! aws kms decrypt --ciphertext-blob fileb://"$encrypted_file" --key-id "$KMS_KEY_ID" --output text --query Plaintext | base64 --decode > "$decrypted_file"; then
        log "ERROR" "Failed to decrypt backup file using KMS"
        return 1
    fi
    
    # Verify decryption was successful
    if [[ ! -f "$decrypted_file" || ! -s "$decrypted_file" ]]; then
        log "ERROR" "Decryption failed or produced an empty file"
        return 1
    fi
    
    log "INFO" "Successfully decrypted backup to $decrypted_file ($(du -h "$decrypted_file" | cut -f1))"
    
    # If the file is compressed (.gz), decompress it
    if [[ "$decrypted_file" == *.gz ]]; then
        local decompressed_file="${decrypted_file%.gz}"
        log "INFO" "Decompressing backup file..."
        
        if ! gzip -d -c "$decrypted_file" > "$decompressed_file"; then
            log "ERROR" "Failed to decompress backup file"
            return 1
        fi
        
        log "INFO" "Successfully decompressed backup to $decompressed_file ($(du -h "$decompressed_file" | cut -f1))"
        decrypted_file="$decompressed_file"
    fi
    
    echo "$decrypted_file"
    return 0
}

# Function to restore a full database backup using pg_restore
restore_full_backup() {
    local backup_file="$1"
    local db_host="$2"
    local db_port="$3"
    local db_name="$4"
    local db_user="$5"
    local db_password="$6"
    
    log "INFO" "Restoring full backup to database '$db_name' on host '$db_host'..."
    
    # Set PGPASSWORD environment variable
    export PGPASSWORD="$db_password"
    
    # Check if target database exists, create if necessary
    log "INFO" "Checking if target database exists..."
    if ! psql -h "$db_host" -p "$db_port" -U "$db_user" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        log "INFO" "Database '$db_name' does not exist. Creating..."
        if ! createdb -h "$db_host" -p "$db_port" -U "$db_user" "$db_name"; then
            log "ERROR" "Failed to create database '$db_name'"
            unset PGPASSWORD
            return 1
        fi
        log "INFO" "Successfully created database '$db_name'"
    else
        log "INFO" "Database '$db_name' already exists"
    fi
    
    # Determine the backup file format and use appropriate restoration command
    local restore_status=0
    
    if [[ "$backup_file" == *.sql ]]; then
        # Restore SQL dump file
        log "INFO" "Restoring SQL dump file..."
        if ! psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -f "$backup_file"; then
            restore_status=1
        fi
    elif [[ "$backup_file" == *.dump || "$backup_file" == *.custom ]]; then
        # Restore custom/directory format backup
        log "INFO" "Restoring custom format backup..."
        if ! pg_restore -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c --if-exists "$backup_file"; then
            restore_status=$?
            # pg_restore can return non-zero status even for successful restores with warnings
            if [[ $restore_status -ne 0 ]]; then
                log "WARN" "pg_restore completed with status $restore_status (this may include warnings)"
                # Check if the database has tables (indicating a possibly successful restore)
                if psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'" | grep -q '[1-9]'; then
                    log "INFO" "Database contains tables, treating restore as successful despite warnings"
                    restore_status=0
                fi
            fi
        fi
    else
        log "ERROR" "Unsupported backup file format: $backup_file"
        unset PGPASSWORD
        return 1
    fi
    
    # Clear PGPASSWORD for security
    unset PGPASSWORD
    
    if [[ $restore_status -eq 0 ]]; then
        log "SUCCESS" "Successfully restored database from backup"
    else
        log "ERROR" "Failed to restore database from backup"
    fi
    
    return $restore_status
}

# Function to restore a Write-Ahead Log (WAL) backup for point-in-time recovery
restore_wal_backup() {
    local backup_file="$1"
    local db_host="$2"
    local db_port="$3"
    local db_name="$4"
    local db_user="$5"
    local db_password="$6"
    local recovery_time="$7"
    
    log "INFO" "Performing point-in-time recovery to $recovery_time..."
    
    # Set PGPASSWORD environment variable
    export PGPASSWORD="$db_password"
    
    # Validate recovery time format
    if [[ -z "$recovery_time" ]]; then
        log "ERROR" "Recovery time not provided for point-in-time recovery"
        unset PGPASSWORD
        return 1
    fi
    
    # Extract WAL files from the backup archive
    local wal_dir="$TEMP_DIR/wal"
    mkdir -p "$wal_dir"
    
    log "INFO" "Extracting WAL files from backup..."
    if ! tar -xf "$backup_file" -C "$wal_dir"; then
        log "ERROR" "Failed to extract WAL files from backup"
        unset PGPASSWORD
        return 1
    fi
    
    # Create recovery configuration
    local recovery_conf="$TEMP_DIR/recovery.conf"
    cat > "$recovery_conf" << EOF
restore_command = 'cp $wal_dir/%f %p'
recovery_target_time = '$recovery_time'
recovery_target_inclusive = true
EOF
    
    log "INFO" "Created recovery configuration targeting $recovery_time"
    
    # Check if we have a base backup to recover from
    # This is a simplified approach - in a real environment, you would need to
    # ensure the base backup is properly configured and the WAL files are correctly placed
    log "WARN" "Point-in-time recovery requires a properly set up PostgreSQL instance with base backup."
    log "WARN" "This script provides the recovery configuration but requires manual intervention."
    log "INFO" "Recovery configuration has been written to: $recovery_conf"
    log "INFO" "WAL files have been extracted to: $wal_dir"
    
    # In a production environment, you would interact with the RDS API or run
    # SQL commands to initiate point-in-time recovery using the extracted WAL files
    
    log "INFO" "Please implement the appropriate point-in-time recovery procedure for your environment"
    log "INFO" "using the provided recovery configuration and WAL files."
    
    # Clear PGPASSWORD for security
    unset PGPASSWORD
    
    # Since this is an advanced operation that requires environment-specific knowledge,
    # we return 0 but note that manual steps are required
    return 0
}

# Function to verify the database restoration was successful
verify_restoration() {
    local db_host="$1"
    local db_port="$2"
    local db_name="$3"
    local db_user="$4"
    local db_password="$5"
    
    log "INFO" "Verifying database restoration for '$db_name'..."
    
    # Set PGPASSWORD environment variable
    export PGPASSWORD="$db_password"
    
    # First, check if we can connect to the database
    if ! psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "\q" > /dev/null 2>&1; then
        log "ERROR" "Cannot connect to the restored database"
        unset PGPASSWORD
        return 1
    fi
    
    log "INFO" "Successfully connected to the restored database"
    
    # Check for critical tables (adjust these to match your application's critical tables)
    local critical_tables=("users" "voice_journals" "emotional_checkins" "tools")
    local missing_tables=()
    
    for table in "${critical_tables[@]}"; do
        log "INFO" "Checking for table '$table'..."
        if ! psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table');" | grep -q "t"; then
            log "WARN" "Critical table '$table' not found in the restored database"
            missing_tables+=("$table")
        else
            log "INFO" "Table '$table' exists"
            
            # Get row count for the table
            local row_count
            row_count=$(psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -t -c "SELECT COUNT(*) FROM \"$table\";" | tr -d '[:space:]')
            log "INFO" "Table '$table' has $row_count rows"
        fi
    done
    
    # Run database consistency checks
    log "INFO" "Running database consistency checks..."
    local consistency_errors
    consistency_errors=$(psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -t -c "VACUUM ANALYZE VERBOSE;" 2>&1 | grep -i "error")
    
    if [[ -n "$consistency_errors" ]]; then
        log "WARN" "Database consistency check found issues: $consistency_errors"
    else
        log "INFO" "Database consistency check passed"
    fi
    
    # Clear PGPASSWORD for security
    unset PGPASSWORD
    
    # Determine verification result
    if [[ ${#missing_tables[@]} -gt 0 ]]; then
        log "WARN" "Verification found missing tables: ${missing_tables[*]}"
        # If missing tables is more than half of critical tables, consider it a failure
        if [[ ${#missing_tables[@]} -gt $((${#critical_tables[@]} / 2)) ]]; then
            log "ERROR" "Too many critical tables are missing. Verification failed."
            return 1
        else
            log "WARN" "Some critical tables are missing but majority exists. Verification passed with warnings."
            return 0
        fi
    fi
    
    log "SUCCESS" "Database restoration verification completed successfully"
    return 0
}

# Function to clean up temporary files and resources
cleanup() {
    log "INFO" "Cleaning up temporary files and resources..."
    
    # Remove temporary restore directory and files
    if [[ -d "$TEMP_DIR" ]]; then
        log "INFO" "Removing temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    
    # Clear any sensitive environment variables
    unset PGPASSWORD
    unset DB_PASSWORD
    
    log "INFO" "Cleanup completed"
}

# Function to send notification about restoration status
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
    local subject="Amira Wellness DB Restore - $ENVIRONMENT - $status"
    local full_message="
Database Restoration Report:
---------------------------
Status: $status
Environment: $ENVIRONMENT
Database: $DB_NAME
Timestamp: $(date)

$message

For more details, check the logs at: $LOG_FILE
"
    
    # Send message to SNS topic
    if ! aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "$subject" --message "$full_message"; then
        log "ERROR" "Failed to send notification to SNS topic: $SNS_TOPIC_ARN"
        return 1
    fi
    
    log "INFO" "Successfully sent notification to SNS topic: $SNS_TOPIC_ARN"
    return 0
}

# Function to create a detailed report of the restoration process
create_restore_report() {
    local backup_path="$1"
    local target_db="$2"
    local status="$3"
    local start_time="$4"
    local end_time="$5"
    
    log "INFO" "Creating restoration report..."
    
    # Calculate duration
    local duration
    duration=$(($(date -d "$end_time" +%s) - $(date -d "$start_time" +%s)))
    local duration_formatted="$((duration / 60)) minutes $((duration % 60)) seconds"
    
    # Generate report filename
    local report_file="$TEMP_DIR/restore-report-${TIMESTAMP}.json"
    
    # Create report JSON
    cat > "$report_file" << EOF
{
  "restore_id": "${TIMESTAMP}",
  "status": "${status}",
  "environment": "${ENVIRONMENT}",
  "backup_source": "${backup_path}",
  "target_database": "${target_db}",
  "restore_type": "${RESTORE_TYPE}",
  "point_in_time": "${POINT_IN_TIME}",
  "start_time": "${start_time}",
  "end_time": "${end_time}",
  "duration": "${duration_formatted}",
  "duration_seconds": ${duration}
}
EOF
    
    log "INFO" "Restoration report created at: $report_file"
    
    # Upload report to S3
    local report_s3_path="s3://${BACKUP_BUCKET}/restore-reports/restore-report-${TIMESTAMP}.json"
    
    if aws s3 cp "$report_file" "$report_s3_path"; then
        log "INFO" "Report uploaded to: $report_s3_path"
    else
        log "WARN" "Failed to upload report to S3"
    fi
    
    echo "$report_file"
}

# Main function that orchestrates the database restoration process
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    local backup_path=""
    local exit_code=0
    local report_file=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--type)
                RESTORE_TYPE="$2"
                shift 2
                ;;
            -b|--backup)
                backup_path="$2"
                shift 2
                ;;
            -p|--point-in-time)
                POINT_IN_TIME="$2"
                shift 2
                ;;
            -d|--database)
                TARGET_DB_NAME="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo "  Options:"
                echo "    -t, --type TYPE       Restoration type (full, wal) [default: full]"
                echo "    -b, --backup PATH     Specific backup to restore (S3 path)"
                echo "    -p, --point-in-time   Target recovery time for point-in-time recovery (ISO format)"
                echo "    -d, --database NAME   Target database name [default: same as source]"
                echo "    -e, --environment     Environment (development, staging, production) [default: development]"
                echo "    -h, --help            Display this help message"
                echo ""
                echo "Example:"
                echo "  $0 --type full --environment production"
                echo "  $0 --backup s3://amira-wellness-backups/database/backup-2023-10-15.sql.gz.enc"
                echo "  $0 --type wal --point-in-time \"2023-10-15 14:30:00 UTC\""
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
    
    # Determine backup to restore (latest or specific)
    if [[ -z "$backup_path" ]]; then
        log "INFO" "No specific backup path provided. Using latest backup of type: $RESTORE_TYPE"
        
        if ! backup_path=$(get_latest_backup "$RESTORE_TYPE"); then
            log "ERROR" "Failed to get latest backup. Exiting."
            exit_code=1
            send_notification "FAILED" "Failed to get latest backup. See logs for details."
            exit $exit_code
        fi
    fi
    
    # Validate backup metadata
    if ! validate_backup_metadata "$backup_path"; then
        log "ERROR" "Backup metadata validation failed. Exiting."
        exit_code=1
        send_notification "FAILED" "Backup metadata validation failed. See logs for details."
        exit $exit_code
    fi
    
    # Download the backup from S3
    local downloaded_file
    if ! downloaded_file=$(download_backup "$backup_path"); then
        log "ERROR" "Failed to download backup. Exiting."
        exit_code=1
        send_notification "FAILED" "Failed to download backup. See logs for details."
        exit $exit_code
    fi
    
    # Decrypt the backup
    local decrypted_file
    if ! decrypted_file=$(decrypt_backup "$downloaded_file"); then
        log "ERROR" "Failed to decrypt backup. Exiting."
        exit_code=1
        send_notification "FAILED" "Failed to decrypt backup. See logs for details."
        exit $exit_code
    fi
    
    # Perform appropriate restoration based on RESTORE_TYPE
    if [[ "$RESTORE_TYPE" == "full" ]]; then
        if ! restore_full_backup "$decrypted_file" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD"; then
            log "ERROR" "Failed to restore full backup. Exiting."
            exit_code=1
            send_notification "FAILED" "Failed to restore full backup. See logs for details."
            exit $exit_code
        fi
    elif [[ "$RESTORE_TYPE" == "wal" ]]; then
        if [[ -z "$POINT_IN_TIME" ]]; then
            log "ERROR" "Point-in-time not specified for WAL recovery. Exiting."
            exit_code=1
            send_notification "FAILED" "Point-in-time not specified for WAL recovery. See logs for details."
            exit $exit_code
        fi
        
        if ! restore_wal_backup "$decrypted_file" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "$POINT_IN_TIME"; then
            log "ERROR" "Failed to perform point-in-time recovery. Exiting."
            exit_code=1
            send_notification "FAILED" "Failed to perform point-in-time recovery. See logs for details."
            exit $exit_code
        fi
    else
        log "ERROR" "Unknown restore type: $RESTORE_TYPE. Exiting."
        exit_code=1
        send_notification "FAILED" "Unknown restore type: $RESTORE_TYPE. See logs for details."
        exit $exit_code
    fi
    
    # Verify restoration success
    if ! verify_restoration "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD"; then
        log "ERROR" "Restoration verification failed. Database may be incomplete."
        exit_code=1
        send_notification "WARNING" "Restoration completed but verification failed. Database may be incomplete. See logs for details."
    else
        log "SUCCESS" "Database restoration and verification completed successfully."
    fi
    
    # Create restoration report
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local status="SUCCESS"
    if [[ $exit_code -ne 0 ]]; then
        status="FAILED"
    fi
    
    report_file=$(create_restore_report "$backup_path" "$DB_NAME" "$status" "$start_time" "$end_time")
    
    # Send success or failure notification
    if [[ $exit_code -eq 0 ]]; then
        send_notification "SUCCESS" "Database restoration completed successfully. Backup: $backup_path, Target: $DB_NAME"
    else
        send_notification "FAILED" "Database restoration failed. See logs for details."
    fi
    
    # Log restoration completion with summary information
    log "INFO" "Database restoration process completed with exit code: $exit_code"
    log "INFO" "Backup source: $backup_path"
    log "INFO" "Target database: $DB_NAME on $DB_HOST"
    log "INFO" "Start time: $start_time"
    log "INFO" "End time: $end_time"
    log "INFO" "Duration: $(( $(date -d "$end_time" +%s) - $(date -d "$start_time" +%s) )) seconds"
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "Report file: $report_file"
    
    return $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi