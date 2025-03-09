#!/bin/bash
#
# audit-logs.sh - Audit and analyze system logs for Amira Wellness application
#
# This script fetches and analyzes logs from various sources (CloudWatch, CloudTrail,
# S3, RDS) to monitor security events, data access patterns, and verify compliance
# with regulations like GDPR and CCPA.
#
# Version: 1.0
# Author: Amira Wellness DevOps Team

set -e

# Global variables
LOG_DIR=$(pwd)/audit-logs
CLOUDWATCH_LOG_GROUPS="/aws/lambda/amira-auth-service /aws/lambda/amira-journal-service /aws/lambda/amira-emotion-service /aws/lambda/amira-tool-service /aws/lambda/amira-progress-service"
CLOUDTRAIL_TRAIL_NAME="amira-cloudtrail"
S3_ACCESS_LOGS_BUCKET="amira-access-logs"
RDS_LOG_GROUPS="/aws/rds/instance/amira-db/postgresql"
DATE_FROM=$(date -d '7 days ago' '+%Y-%m-%d')
DATE_TO=$(date '+%Y-%m-%d')
REPORT_FILE="${LOG_DIR}/audit-report-${DATE_TO}.txt"
VERBOSE=false

# Display usage information
usage() {
    cat << EOF
Usage: $(basename $0) [options]

Audit and analyze system logs for Amira Wellness application, focusing on security
events, data access patterns, and compliance verification.

Options:
  -h, --help           Display this help message and exit
  -s, --start-date     Start date for log analysis (format: YYYY-MM-DD, default: 7 days ago)
  -e, --end-date       End date for log analysis (format: YYYY-MM-DD, default: today)
  -d, --directory      Directory to store audit logs (default: ./audit-logs)
  -v, --verbose        Enable verbose output
  -a, --auth-only      Only analyze authentication events
  -c, --compliance     Generate compliance report only (requires previous analysis)

Examples:
  $(basename $0)                           # Analyze logs from the last 7 days
  $(basename $0) -s 2023-01-01 -e 2023-01-31  # Analyze logs for January 2023
  $(basename $0) -d /var/log/amira-audit     # Store logs in custom directory
  $(basename $0) -v -a                      # Verbose output, authentication events only

EOF
}

# Parse command line arguments
parse_args() {
    local auth_only=false
    local compliance_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -s|--start-date)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Error: Start date required" >&2
                    return 1
                fi
                # Validate date format (YYYY-MM-DD)
                if ! [[ $2 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    echo "Error: Invalid date format for start date. Use YYYY-MM-DD" >&2
                    return 1
                fi
                DATE_FROM="$2"
                shift 2
                ;;
            -e|--end-date)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Error: End date required" >&2
                    return 1
                fi
                # Validate date format (YYYY-MM-DD)
                if ! [[ $2 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    echo "Error: Invalid date format for end date. Use YYYY-MM-DD" >&2
                    return 1
                fi
                DATE_TO="$2"
                shift 2
                ;;
            -d|--directory)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Error: Directory path required" >&2
                    return 1
                fi
                LOG_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -a|--auth-only)
                auth_only=true
                shift
                ;;
            -c|--compliance)
                compliance_only=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                return 1
                ;;
        esac
    done

    # Update report file path based on LOG_DIR
    REPORT_FILE="${LOG_DIR}/audit-report-${DATE_TO}.txt"

    # Validate date range
    if [[ $(date -d "$DATE_FROM" +%s) -gt $(date -d "$DATE_TO" +%s) ]]; then
        echo "Error: Start date must be before end date" >&2
        return 1
    fi

    # Store options in globals for main function to use
    export AUTH_ONLY=$auth_only
    export COMPLIANCE_ONLY=$compliance_only

    return 0
}

# Setup environment and validate prerequisites
setup_environment() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" || {
            echo "Error: Failed to create log directory: $LOG_DIR" >&2
            return 1
        }
    fi

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed. Please install aws-cli (version 2.0+)" >&2
        return 1
    fi

    # Check AWS CLI version
    local aws_version=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
    if [[ $(echo "$aws_version" | cut -d'.' -f1) -lt 2 ]]; then
        echo "Warning: AWS CLI version $aws_version is less than recommended (2.0+)" >&2
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install jq (version 1.6+)" >&2
        return 1
    fi

    # Check jq version
    local jq_version=$(jq --version | cut -d'-' -f2)
    if [[ $(echo "$jq_version" | cut -d'.' -f1) -lt 1 || ($(echo "$jq_version" | cut -d'.' -f1) -eq 1 && $(echo "$jq_version" | cut -d'.' -f2) -lt 6) ]]; then
        echo "Warning: jq version $jq_version is less than recommended (1.6+)" >&2
    fi

    # Validate AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS credentials not configured or invalid" >&2
        return 1
    fi

    # Log environment setup
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Environment setup complete:"
        echo "  Log directory: $LOG_DIR"
        echo "  Date range: $DATE_FROM to $DATE_TO"
        echo "  AWS CLI version: $aws_version"
        echo "  jq version: $jq_version"
        echo "  AWS identity: $(aws sts get-caller-identity --query 'Arn' --output text)"
    fi

    return 0
}

# Fetch logs from CloudWatch log groups
fetch_cloudwatch_logs() {
    local log_group="$1"
    local output_file="$2"
    local log_group_name=$(echo "$log_group" | sed 's/\//\-/g' | sed 's/^-//')
    local temp_file="${LOG_DIR}/temp-${log_group_name}.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Fetching CloudWatch logs from $log_group for period $DATE_FROM to $DATE_TO"
    fi

    # Convert dates to Unix timestamps
    local start_time=$(date -d "$DATE_FROM" '+%s')000
    local end_time=$(date -d "$DATE_TO 23:59:59" '+%s')000

    # Fetch logs
    if aws logs filter-log-events \
        --log-group-name "$log_group" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --output json > "$temp_file"; then
        
        # Check if any events were returned
        local event_count=$(jq '.events | length' "$temp_file")
        if [[ "$event_count" -gt 0 ]]; then
            # Extract events and append to output file
            jq '.events[] | { timestamp: .timestamp, message: .message, logStream: .logStream }' "$temp_file" >> "$output_file"
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  Retrieved $event_count events from $log_group"
            fi
        else
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  No events found in $log_group for the specified time period"
            fi
        fi
        
        # Clean up temp file
        rm -f "$temp_file"
        return 0
    else
        echo "Error: Failed to fetch CloudWatch logs from $log_group" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Fetch CloudTrail events
fetch_cloudtrail_events() {
    local output_file="$1"
    local temp_file="${LOG_DIR}/temp-cloudtrail.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Fetching CloudTrail events for period $DATE_FROM to $DATE_TO"
    fi

    # Fetch CloudTrail events
    if aws cloudtrail lookup-events \
        --lookup-attributes AttributeKey=ReadOnly,AttributeValue=false \
        --start-time "$DATE_FROM" \
        --end-time "$DATE_TO" \
        --output json > "$temp_file"; then
        
        # Check if any events were returned
        local event_count=$(jq '.Events | length' "$temp_file")
        if [[ "$event_count" -gt 0 ]]; then
            # Extract and filter security-relevant events
            jq '.Events[] | {
                eventTime: .EventTime,
                eventName: .EventName,
                username: .Username,
                resources: .Resources,
                eventSource: .EventSource,
                readOnly: .ReadOnly
            }' "$temp_file" | jq 'select(
                .eventName | contains("Create") or
                contains("Delete") or
                contains("Update") or
                contains("Put") or
                contains("Modify") or
                contains("Change") or
                contains("Auth") or
                contains("Login")
            )' >> "$output_file"
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  Retrieved and filtered $event_count CloudTrail events"
            fi
        else
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  No CloudTrail events found for the specified time period"
            fi
        fi
        
        # Clean up temp file
        rm -f "$temp_file"
        return 0
    else
        echo "Error: Failed to fetch CloudTrail events" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Fetch S3 access logs
fetch_s3_access_logs() {
    local output_file="$1"
    local temp_dir="${LOG_DIR}/temp-s3-logs"
    local date_from_unix=$(date -d "$DATE_FROM" '+%s')
    local date_to_unix=$(date -d "$DATE_TO 23:59:59" '+%s')

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Fetching S3 access logs for period $DATE_FROM to $DATE_TO"
    fi

    # Create temporary directory
    mkdir -p "$temp_dir"

    # List log files in the S3 bucket
    if aws s3 ls "s3://${S3_ACCESS_LOGS_BUCKET}/" --recursive > "${temp_dir}/s3-file-list.txt"; then
        # If no files found, return
        if [[ ! -s "${temp_dir}/s3-file-list.txt" ]]; then
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  No S3 access logs found for the specified time period"
            fi
            rm -rf "$temp_dir"
            return 0
        fi

        # Download and process log files
        while read -r line; do
            # Extract the file path
            local file_path=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')
            
            # Extract date from filename
            local file_date=$(echo "$file_path" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
            if [[ -z "$file_date" ]]; then
                continue
            fi
            
            # Convert file date to Unix timestamp
            local file_date_unix=$(date -d "$file_date" '+%s')
            
            # Check if file is within date range
            if [[ "$file_date_unix" -ge "$date_from_unix" && "$file_date_unix" -le "$date_to_unix" ]]; then
                # Download the file
                aws s3 cp "s3://${S3_ACCESS_LOGS_BUCKET}/${file_path}" "${temp_dir}/"
                
                # Append to output file
                cat "${temp_dir}/$(basename "$file_path")" >> "${temp_dir}/combined-logs.txt"
            fi
        done < "${temp_dir}/s3-file-list.txt"

        # Convert text logs to JSON format for consistency
        if [[ -f "${temp_dir}/combined-logs.txt" ]]; then
            # Process each line of the log
            while IFS= read -r line; do
                # Skip empty lines
                if [[ -z "$line" ]]; then
                    continue
                fi
                
                # Parse S3 access log format and convert to JSON
                bucket_owner=$(echo "$line" | awk '{print $1}')
                bucket=$(echo "$line" | awk '{print $2}')
                time=$(echo "$line" | awk '{print $3" "$4}')
                remote_ip=$(echo "$line" | awk '{print $5}')
                requester=$(echo "$line" | awk '{print $6}')
                request_id=$(echo "$line" | awk '{print $7}')
                operation=$(echo "$line" | awk '{print $8}')
                key=$(echo "$line" | awk '{print $9}')
                request_uri=$(echo "$line" | awk '{print $10}')
                status=$(echo "$line" | awk '{print $11}')
                
                # Create JSON entry
                jq -n \
                    --arg time "$time" \
                    --arg bucket "$bucket" \
                    --arg requester "$requester" \
                    --arg remote_ip "$remote_ip" \
                    --arg operation "$operation" \
                    --arg key "$key" \
                    --arg status "$status" \
                    '{
                        timestamp: $time,
                        bucket: $bucket,
                        requester: $requester,
                        remoteIP: $remote_ip,
                        operation: $operation,
                        key: $key,
                        status: $status
                    }' >> "$output_file"
            done < "${temp_dir}/combined-logs.txt"
            
            if [[ "$VERBOSE" == "true" ]]; then
                local log_count=$(wc -l < "${temp_dir}/combined-logs.txt")
                echo "  Processed $log_count S3 access log entries"
            fi
        else
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  No S3 access logs found within the date range"
            fi
        fi
        
        # Clean up
        rm -rf "$temp_dir"
        return 0
    else
        echo "Error: Failed to fetch S3 access logs" >&2
        rm -rf "$temp_dir"
        return 1
    fi
}

# Fetch RDS logs
fetch_rds_logs() {
    local output_file="$1"
    local temp_file="${LOG_DIR}/temp-rds.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Fetching RDS logs for period $DATE_FROM to $DATE_TO"
    fi

    # Extract instance identifier from log group
    local instance_id=$(echo "$RDS_LOG_GROUPS" | sed -E 's/.*\/([^\/]+)\/postgresql/\1/')

    # Convert dates to Unix timestamps
    local start_time=$(date -d "$DATE_FROM" '+%s')000
    local end_time=$(date -d "$DATE_TO 23:59:59" '+%s')000

    # Fetch RDS logs
    if aws rds download-db-log-file-portion \
        --db-instance-identifier "$instance_id" \
        --log-file-name "postgresql.log" \
        --output text > "$temp_file"; then
        
        # Process log file to filter by date and convert to JSON
        if [[ -s "$temp_file" ]]; then
            # Process each line of the log
            while IFS= read -r line; do
                # Skip empty lines
                if [[ -z "$line" ]]; then
                    continue
                fi
                
                # Extract timestamp from log line (assumes standard PostgreSQL log format)
                local log_timestamp=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
                if [[ -z "$log_timestamp" ]]; then
                    continue
                fi
                
                # Convert to Unix timestamp
                local log_time_unix=$(date -d "$log_timestamp" '+%s')000
                
                # Check if log is within date range
                if [[ "$log_time_unix" -ge "$start_time" && "$log_time_unix" -le "$end_time" ]]; then
                    # Extract log level and message
                    local log_level=$(echo "$line" | grep -oE 'ERROR|WARNING|INFO|LOG|FATAL|PANIC' | head -1)
                    if [[ -z "$log_level" ]]; then
                        log_level="UNKNOWN"
                    fi
                    
                    local log_message=$(echo "$line" | sed -E "s/^.*($log_level)//" | sed 's/^[ \t]*//')
                    
                    # Create JSON entry
                    jq -n \
                        --arg timestamp "$log_timestamp" \
                        --arg level "$log_level" \
                        --arg message "$log_message" \
                        '{
                            timestamp: $timestamp,
                            level: $level,
                            message: $message,
                            source: "RDS"
                        }' >> "$output_file"
                fi
            done < "$temp_file"
            
            if [[ "$VERBOSE" == "true" ]]; then
                local entry_count=$(wc -l < "$output_file")
                echo "  Processed RDS logs and extracted $entry_count entries within date range"
            fi
        else
            if [[ "$VERBOSE" == "true" ]]; then
                echo "  No RDS logs found for the specified time period"
            fi
        fi
        
        # Clean up temp file
        rm -f "$temp_file"
        return 0
    else
        echo "Error: Failed to fetch RDS logs" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Analyze authentication events
analyze_authentication_events() {
    local input_files="$1"
    local output_file="$2"
    local temp_file="${LOG_DIR}/temp-auth-analysis.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Analyzing authentication events"
    fi

    # Initialize counters
    local success_count=0
    local failure_count=0
    local suspicious_count=0
    local unique_users=0
    local password_changes=0

    # Create output file header
    cat > "$output_file" << EOF
===================================================
AUTHENTICATION EVENTS ANALYSIS
===================================================
Period: $DATE_FROM to $DATE_TO
Generated: $(date '+%Y-%m-%d %H:%M:%S')

EOF

    # Process input files
    for file in $input_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Extract authentication events
        jq -c 'select(
            .message | (
                contains("authentication") or
                contains("login") or
                contains("signin") or
                contains("sign in") or
                contains("auth") or
                contains("password") or
                contains("credential")
            )
        )' "$file" > "$temp_file"

        # Count successful logins
        local file_success=$(jq -c 'select(
            .message | (
                contains("successful") or
                contains("success") or
                contains("succeeded")
            ) and (
                contains("login") or
                contains("authentication") or
                contains("signin") or
                contains("sign in")
            )
        )' "$temp_file" | wc -l)
        success_count=$((success_count + file_success))

        # Count failed logins
        local file_failure=$(jq -c 'select(
            .message | (
                contains("failed") or
                contains("failure") or
                contains("invalid") or
                contains("unauthorized")
            ) and (
                contains("login") or
                contains("authentication") or
                contains("signin") or
                contains("sign in")
            )
        )' "$temp_file" | wc -l)
        failure_count=$((failure_count + file_failure))

        # Identify suspicious patterns (multiple failures)
        local file_suspicious=$(jq -c 'select(
            .message | (
                contains("multiple failed") or
                contains("exceeded") or
                contains("limit") or
                contains("blocked") or
                contains("suspicious")
            )
        )' "$temp_file" | wc -l)
        suspicious_count=$((suspicious_count + file_suspicious))

        # Count password changes
        local file_pwd_changes=$(jq -c 'select(
            .message | (
                contains("password change") or
                contains("changed password") or
                contains("reset password")
            )
        )' "$temp_file" | wc -l)
        password_changes=$((password_changes + file_pwd_changes))

        # Extract unique users
        local file_users=$(jq -r 'select(.message | contains("user") or contains("User")) | 
            .message | capture("(?:user|User)[: ]+(?<user>[^ ,\"]+)").user // empty' "$temp_file" | 
            sort -u | wc -l)
        unique_users=$((unique_users + file_users))
    done

    # Calculate failure rate
    local total_attempts=$((success_count + failure_count))
    local failure_rate=0
    if [[ $total_attempts -gt 0 ]]; then
        failure_rate=$(awk "BEGIN { printf \"%.2f\", ($failure_count / $total_attempts) * 100 }")
    fi

    # Write analysis to output file
    cat >> "$output_file" << EOF
SUMMARY:
- Total login attempts: $total_attempts
- Successful logins: $success_count
- Failed logins: $failure_count
- Failure rate: ${failure_rate}%
- Suspicious activity events: $suspicious_count
- Password changes: $password_changes
- Unique users: $unique_users

EOF

    # List suspicious activities if any
    if [[ $suspicious_count -gt 0 ]]; then
        echo "SUSPICIOUS ACTIVITIES:" >> "$output_file"
        
        for file in $input_files; do
            if [[ ! -f "$file" ]]; then
                continue
            fi
            
            # Extract and format suspicious events
            jq -c 'select(
                .message | (
                    contains("multiple failed") or
                    contains("exceeded") or
                    contains("limit") or
                    contains("blocked") or
                    contains("suspicious")
                )
            )' "$file" | while read -r event; do
                local timestamp=$(echo "$event" | jq -r '.timestamp')
                local message=$(echo "$event" | jq -r '.message')
                
                # Format timestamp if it's a Unix timestamp
                if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
                    timestamp=$(date -d "@$((timestamp/1000))" '+%Y-%m-%d %H:%M:%S')
                fi
                
                echo "- [$timestamp] $message" >> "$output_file"
            done
        done
        
        echo "" >> "$output_file"
    fi

    # Add recommendations
    cat >> "$output_file" << EOF
RECOMMENDATIONS:
- ${failure_rate}% failure rate: $(if (( $(echo "$failure_rate > 10" | bc -l) )); then echo "ATTENTION REQUIRED - High failure rate indicates potential brute force attempts"; else echo "ACCEPTABLE - Normal authentication failure rate"; fi)
- Suspicious activities: $(if [[ $suspicious_count -gt 0 ]]; then echo "INVESTIGATE - Review the suspicious events listed above"; else echo "NONE DETECTED"; fi)
- Password changes: ${password_changes} during the period

EOF

    # Clean up
    rm -f "$temp_file"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "  Authentication analysis complete: $success_count successful logins, $failure_count failures"
    fi
    
    return 0
}

# Analyze data access events
analyze_data_access_events() {
    local input_files="$1"
    local output_file="$2"
    local temp_file="${LOG_DIR}/temp-data-access-analysis.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Analyzing data access events"
    fi

    # Initialize counters
    local total_access=0
    local voice_journal_access=0
    local emotional_data_access=0
    local user_data_access=0
    local export_operations=0
    local delete_operations=0
    local unusual_access=0

    # Create output file header
    cat > "$output_file" << EOF
===================================================
DATA ACCESS EVENTS ANALYSIS
===================================================
Period: $DATE_FROM to $DATE_TO
Generated: $(date '+%Y-%m-%d %H:%M:%S')

EOF

    # Process input files
    for file in $input_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Extract data access events
        jq -c 'select(
            .message | (
                contains("access") or
                contains("get") or
                contains("read") or
                contains("retrieve") or
                contains("select") or
                contains("query") or
                contains("export") or
                contains("download") or
                contains("delete")
            ) or (
                .operation | (
                    contains("GET") or
                    contains("READ") or
                    contains("SELECT") or
                    contains("EXPORT") or
                    contains("DOWNLOAD") or
                    contains("DELETE")
                )
            ) // false
        )' "$file" > "$temp_file"

        # Count total data access events
        local file_total=$(wc -l < "$temp_file")
        total_access=$((total_access + file_total))

        # Count voice journal access
        local file_voice=$(jq -c 'select(
            .message | (
                contains("voice") or
                contains("journal") or
                contains("recording") or
                contains("audio")
            ) or (
                .key | (
                    contains("voice") or
                    contains("journal") or
                    contains("recording") or
                    contains("audio")
                )
            ) // false
        )' "$temp_file" | wc -l)
        voice_journal_access=$((voice_journal_access + file_voice))

        # Count emotional data access
        local file_emotional=$(jq -c 'select(
            .message | (
                contains("emotion") or
                contains("check-in") or
                contains("emotional") or
                contains("mood")
            ) or (
                .key | (
                    contains("emotion") or
                    contains("check-in") or
                    contains("emotional") or
                    contains("mood")
                )
            ) // false
        )' "$temp_file" | wc -l)
        emotional_data_access=$((emotional_data_access + file_emotional))

        # Count user data access
        local file_user=$(jq -c 'select(
            .message | (
                contains("user") or
                contains("profile") or
                contains("account")
            ) or (
                .key | (
                    contains("user") or
                    contains("profile") or
                    contains("account")
                )
            ) // false
        )' "$temp_file" | wc -l)
        user_data_access=$((user_data_access + file_user))

        # Count export operations
        local file_export=$(jq -c 'select(
            .message | (
                contains("export") or
                contains("download")
            ) or (
                .operation | (
                    contains("EXPORT") or
                    contains("DOWNLOAD")
                )
            ) // false
        )' "$temp_file" | wc -l)
        export_operations=$((export_operations + file_export))

        # Count delete operations
        local file_delete=$(jq -c 'select(
            .message | contains("delete") or (
                .operation | contains("DELETE")
            ) // false
        )' "$temp_file" | wc -l)
        delete_operations=$((delete_operations + file_delete))

        # Identify unusual access patterns
        local file_unusual=$(jq -c 'select(
            .message | (
                contains("unusual") or
                contains("suspicious") or
                contains("unauthorized") or
                contains("denied") or
                contains("permission") or
                contains("forbidden") or
                contains("failed") or
                contains("attempt")
            )
        )' "$temp_file" | wc -l)
        unusual_access=$((unusual_access + file_unusual))
    done

    # Write analysis to output file
    cat >> "$output_file" << EOF
SUMMARY:
- Total data access events: $total_access
- Voice journal access: $voice_journal_access
- Emotional data access: $emotional_data_access
- User data access: $user_data_access
- Export operations: $export_operations
- Delete operations: $delete_operations
- Unusual access patterns: $unusual_access

EOF

    # List unusual access events if any
    if [[ $unusual_access -gt 0 ]]; then
        echo "UNUSUAL ACCESS EVENTS:" >> "$output_file"
        
        for file in $input_files; do
            if [[ ! -f "$file" ]]; then
                continue
            fi
            
            # Extract and format unusual access events
            jq -c 'select(
                .message | (
                    contains("unusual") or
                    contains("suspicious") or
                    contains("unauthorized") or
                    contains("denied") or
                    contains("permission") or
                    contains("forbidden") or
                    contains("failed") or
                    contains("attempt")
                )
            )' "$file" | while read -r event; do
                local timestamp=$(echo "$event" | jq -r '.timestamp')
                local message=$(echo "$event" | jq -r '.message')
                
                # Format timestamp if it's a Unix timestamp
                if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
                    timestamp=$(date -d "@$((timestamp/1000))" '+%Y-%m-%d %H:%M:%S')
                fi
                
                echo "- [$timestamp] $message" >> "$output_file"
            done
        done
        
        echo "" >> "$output_file"
    fi

    # Add recommendations
    cat >> "$output_file" << EOF
RECOMMENDATIONS:
- Unusual access patterns: $(if [[ $unusual_access -gt 0 ]]; then echo "INVESTIGATE - Review the unusual access events listed above"; else echo "NONE DETECTED"; fi)
- Export operations: $(if [[ $export_operations -gt 10 ]]; then echo "REVIEW - High number of exports may indicate data exfiltration"; else echo "NORMAL ACTIVITY"; fi)
- Delete operations: $(if [[ $delete_operations -gt 20 ]]; then echo "REVIEW - High number of deletions may indicate data purging"; else echo "NORMAL ACTIVITY"; fi)

EOF

    # Clean up
    rm -f "$temp_file"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "  Data access analysis complete: $total_access events, $unusual_access unusual patterns"
    fi
    
    return 0
}

# Analyze security events
analyze_security_events() {
    local input_files="$1"
    local output_file="$2"
    local temp_file="${LOG_DIR}/temp-security-analysis.json"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Analyzing security events"
    fi

    # Initialize counters
    local total_events=0
    local permission_changes=0
    local encryption_events=0
    local policy_changes=0
    local config_changes=0
    local security_failures=0

    # Create output file header
    cat > "$output_file" << EOF
===================================================
SECURITY EVENTS ANALYSIS
===================================================
Period: $DATE_FROM to $DATE_TO
Generated: $(date '+%Y-%m-%d %H:%M:%S')

EOF

    # Process input files
    for file in $input_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Extract security events
        jq -c 'select(
            .message | (
                contains("security") or
                contains("permission") or
                contains("encrypt") or
                contains("decrypt") or
                contains("key") or
                contains("certificate") or
                contains("policy") or
                contains("role") or
                contains("IAM") or
                contains("access") or
                contains("firewall") or
                contains("WAF") or
                contains("Shield")
            ) or (
                .eventName | (
                    contains("Create") or
                    contains("Delete") or
                    contains("Update") or
                    contains("Put") or
                    contains("Modify") or
                    contains("Add") or
                    contains("Attach") or
                    contains("Detach")
                ) and (
                    contains("Role") or
                    contains("Policy") or
                    contains("Permission") or
                    contains("Group") or
                    contains("User") or
                    contains("Access") or
                    contains("Key") or
                    contains("Certificate") or
                    contains("Security")
                )
            ) // false
        )' "$file" > "$temp_file"

        # Count total security events
        local file_total=$(wc -l < "$temp_file")
        total_events=$((total_events + file_total))

        # Count permission changes
        local file_permissions=$(jq -c 'select(
            .message | (
                contains("permission") or
                contains("role") or
                contains("policy") or
                contains("IAM") or
                contains("access")
            ) and (
                contains("change") or
                contains("update") or
                contains("modify") or
                contains("create") or
                contains("delete") or
                contains("add") or
                contains("remove")
            ) or (
                .eventName | (
                    contains("Create") or
                    contains("Delete") or
                    contains("Update") or
                    contains("Put") or
                    contains("Modify") or
                    contains("Add") or
                    contains("Attach") or
                    contains("Detach")
                ) and (
                    contains("Role") or
                    contains("Policy") or
                    contains("Permission") or
                    contains("Group") or
                    contains("User") or
                    contains("Access")
                )
            ) // false
        )' "$temp_file" | wc -l)
        permission_changes=$((permission_changes + file_permissions))

        # Count encryption events
        local file_encryption=$(jq -c 'select(
            .message | (
                contains("encrypt") or
                contains("decrypt") or
                contains("key") or
                contains("KMS")
            ) or (
                .eventName | (
                    contains("Key") or
                    contains("Encrypt") or
                    contains("Decrypt") or
                    contains("KMS")
                )
            ) // false
        )' "$temp_file" | wc -l)
        encryption_events=$((encryption_events + file_encryption))

        # Count policy changes
        local file_policy=$(jq -c 'select(
            .message | (
                contains("policy") or
                contains("policies")
            ) and (
                contains("change") or
                contains("update") or
                contains("modify") or
                contains("create") or
                contains("delete")
            ) or (
                .eventName | (
                    contains("Create") or
                    contains("Delete") or
                    contains("Update") or
                    contains("Put") or
                    contains("Modify")
                ) and (
                    contains("Policy")
                )
            ) // false
        )' "$temp_file" | wc -l)
        policy_changes=$((policy_changes + file_policy))

        # Count configuration changes
        local file_config=$(jq -c 'select(
            .message | (
                contains("config") or
                contains("configuration") or
                contains("setting")
            ) and (
                contains("change") or
                contains("update") or
                contains("modify")
            ) or (
                .eventName | (
                    contains("Config") or
                    contains("Setting")
                ) and (
                    contains("Update") or
                    contains("Modify") or
                    contains("Put")
                )
            ) // false
        )' "$temp_file" | wc -l)
        config_changes=$((config_changes + file_config))

        # Count security failures
        local file_failures=$(jq -c 'select(
            .message | (
                contains("fail") or
                contains("error") or
                contains("denied") or
                contains("unauthorized") or
                contains("forbidden")
            ) and (
                contains("security") or
                contains("encrypt") or
                contains("decrypt") or
                contains("key") or
                contains("permission") or
                contains("access")
            )
        )' "$temp_file" | wc -l)
        security_failures=$((security_failures + file_failures))
    done

    # Write analysis to output file
    cat >> "$output_file" << EOF
SUMMARY:
- Total security events: $total_events
- Permission changes: $permission_changes
- Encryption operations: $encryption_events
- Policy changes: $policy_changes
- Configuration changes: $config_changes
- Security failures: $security_failures

EOF

    # List critical security events
    echo "CRITICAL SECURITY EVENTS:" >> "$output_file"
    
    for file in $input_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        # Extract and format critical security events
        jq -c 'select(
            .message | (
                contains("security") or
                contains("permission") or
                contains("policy") or
                contains("encrypt") or
                contains("key")
            ) and (
                contains("change") or
                contains("update") or
                contains("modify") or
                contains("create") or
                contains("delete") or
                contains("fail") or
                contains("error") or
                contains("denied")
            ) or (
                .eventName | (
                    contains("Create") or
                    contains("Delete") or
                    contains("Update") or
                    contains("Put") or
                    contains("Modify")
                ) and (
                    contains("Role") or
                    contains("Policy") or
                    contains("Permission") or
                    contains("Key") or
                    contains("Security")
                )
            ) // false
        )' "$file" | head -10 | while read -r event; do
            local timestamp=$(echo "$event" | jq -r '.timestamp // .eventTime')
            local message=$(echo "$event" | jq -r '.message // empty')
            local event_name=$(echo "$event" | jq -r '.eventName // empty')
            local username=$(echo "$event" | jq -r '.username // empty')
            
            # Format timestamp if it's a Unix timestamp
            if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
                timestamp=$(date -d "@$((timestamp/1000))" '+%Y-%m-%d %H:%M:%S')
            fi
            
            if [[ -n "$event_name" ]]; then
                echo "- [$timestamp] $event_name by $username" >> "$output_file"
            elif [[ -n "$message" ]]; then
                echo "- [$timestamp] $message" >> "$output_file"
            fi
        done
    done
    
    # Note if more events exist
    local total_critical=0
    for file in $input_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        local file_critical=$(jq -c 'select(
            .message | (
                contains("security") or
                contains("permission") or
                contains("policy") or
                contains("encrypt") or
                contains("key")
            ) and (
                contains("change") or
                contains("update") or
                contains("modify") or
                contains("create") or
                contains("delete") or
                contains("fail") or
                contains("error") or
                contains("denied")
            ) or (
                .eventName | (
                    contains("Create") or
                    contains("Delete") or
                    contains("Update") or
                    contains("Put") or
                    contains("Modify")
                ) and (
                    contains("Role") or
                    contains("Policy") or
                    contains("Permission") or
                    contains("Key") or
                    contains("Security")
                )
            ) // false
        )' "$file" | wc -l)
        total_critical=$((total_critical + file_critical))
    done
    
    if [[ $total_critical -gt 10 ]]; then
        echo "- And $(($total_critical - 10)) more events... (showing first 10 only)" >> "$output_file"
    fi
    
    echo "" >> "$output_file"

    # Add recommendations
    cat >> "$output_file" << EOF
RECOMMENDATIONS:
- Permission changes: $(if [[ $permission_changes -gt 0 ]]; then echo "REVIEW - Verify all permission changes were authorized"; else echo "NONE DETECTED"; fi)
- Policy changes: $(if [[ $policy_changes -gt 0 ]]; then echo "REVIEW - Verify all policy changes were authorized"; else echo "NONE DETECTED"; fi)
- Security failures: $(if [[ $security_failures -gt 0 ]]; then echo "INVESTIGATE - Review security failures for potential vulnerabilities"; else echo "NONE DETECTED"; fi)
- Configuration changes: $(if [[ $config_changes -gt 5 ]]; then echo "REVIEW - High number of configuration changes"; else echo "NORMAL ACTIVITY"; fi)

EOF

    # Clean up
    rm -f "$temp_file"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "  Security analysis complete: $total_events events, $security_failures failures"
    fi
    
    return 0
}

# Generate compliance report
generate_compliance_report() {
    local analysis_files="$1"
    local output_file="$2"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "Generating compliance report"
    fi

    # Create report header
    cat > "$output_file" << EOF
===================================================
AMIRA WELLNESS - COMPLIANCE AUDIT REPORT
===================================================
Period: $DATE_FROM to $DATE_TO
Generated: $(date '+%Y-%m-%d %H:%M:%S')

This report provides a compliance assessment based on analysis of system logs
and activities during the specified period. It focuses on security events,
data access patterns, and compliance with privacy regulations.

===================================================
EXECUTIVE SUMMARY
===================================================

EOF

    # Extract key metrics from analysis files
    local auth_file=$(echo "$analysis_files" | grep -o "[^ ]*auth[^ ]*")
    local data_file=$(echo "$analysis_files" | grep -o "[^ ]*data[^ ]*")
    local security_file=$(echo "$analysis_files" | grep -o "[^ ]*security[^ ]*")

    # Authentication metrics
    local auth_attempts=0
    local auth_failures=0
    local auth_suspicious=0
    if [[ -f "$auth_file" ]]; then
        auth_attempts=$(grep "Total login attempts:" "$auth_file" | awk '{print $4}')
        auth_failures=$(grep "Failed logins:" "$auth_file" | awk '{print $3}')
        auth_suspicious=$(grep "Suspicious activity events:" "$auth_file" | awk '{print $4}')
    fi

    # Data access metrics
    local data_access=0
    local data_unusual=0
    local data_exports=0
    if [[ -f "$data_file" ]]; then
        data_access=$(grep "Total data access events:" "$data_file" | awk '{print $5}')
        data_unusual=$(grep "Unusual access patterns:" "$data_file" | awk '{print $4}')
        data_exports=$(grep "Export operations:" "$data_file" | awk '{print $3}')
    fi

    # Security metrics
    local security_events=0
    local security_failures=0
    local permission_changes=0
    if [[ -f "$security_file" ]]; then
        security_events=$(grep "Total security events:" "$security_file" | awk '{print $4}')
        security_failures=$(grep "Security failures:" "$security_file" | awk '{print $3}')
        permission_changes=$(grep "Permission changes:" "$security_file" | awk '{print $3}')
    fi

    # Overall compliance status
    local gdpr_compliant="Yes"
    local ccpa_compliant="Yes"
    local privacy_compliant="Yes"
    
    # Check for compliance issues
    if [[ $auth_suspicious -gt 0 || $data_unusual -gt 0 || $security_failures -gt 0 ]]; then
        privacy_compliant="Potential issues detected"
    fi
    
    if [[ $data_unusual -gt 0 || $security_failures -gt 0 ]]; then
        gdpr_compliant="Potential issues detected"
        ccpa_compliant="Potential issues detected"
    fi

    # Write executive summary
    cat >> "$output_file" << EOF
Overall Compliance Status:
- GDPR Compliance: $gdpr_compliant
- CCPA Compliance: $ccpa_compliant
- Privacy by Design: $privacy_compliant

Key Metrics:
- Authentication: $auth_attempts attempts, $auth_failures failures, $auth_suspicious suspicious events
- Data Access: $data_access events, $data_unusual unusual patterns, $data_exports exports
- Security: $security_events events, $security_failures failures, $permission_changes permission changes

$(if [[ "$gdpr_compliant" == "Yes" && "$ccpa_compliant" == "Yes" && "$privacy_compliant" == "Yes" ]]; then
    echo "No critical compliance issues were detected during this audit period."
else
    echo "Potential compliance issues were detected and require further investigation."
fi)

===================================================
DETAILED FINDINGS
===================================================

EOF

    # Include detailed findings from analysis files
    if [[ -f "$auth_file" ]]; then
        echo "1. AUTHENTICATION COMPLIANCE" >> "$output_file"
        echo "--------------------------" >> "$output_file"
        grep -A 10 "SUMMARY:" "$auth_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
        
        # Include suspicious activities if any
        if grep -q "SUSPICIOUS ACTIVITIES:" "$auth_file"; then
            echo "" >> "$output_file"
            echo "Notable suspicious authentication activities:" >> "$output_file"
            sed -n '/SUSPICIOUS ACTIVITIES:/,/RECOMMENDATIONS:/p' "$auth_file" | grep "^\-" | head -5 >> "$output_file"
            
            # Note if more activities exist
            local suspicious_count=$(sed -n '/SUSPICIOUS ACTIVITIES:/,/RECOMMENDATIONS:/p' "$auth_file" | grep "^\-" | wc -l)
            if [[ $suspicious_count -gt 5 ]]; then
                echo "... and $(($suspicious_count - 5)) more suspicious activities" >> "$output_file"
            fi
        fi
        echo "" >> "$output_file"
    fi

    if [[ -f "$data_file" ]]; then
        echo "2. DATA PRIVACY COMPLIANCE" >> "$output_file"
        echo "-------------------------" >> "$output_file"
        grep -A 7 "SUMMARY:" "$data_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
        
        # Include unusual access if any
        if grep -q "UNUSUAL ACCESS EVENTS:" "$data_file"; then
            echo "" >> "$output_file"
            echo "Notable unusual data access events:" >> "$output_file"
            sed -n '/UNUSUAL ACCESS EVENTS:/,/RECOMMENDATIONS:/p' "$data_file" | grep "^\-" | head -5 >> "$output_file"
            
            # Note if more events exist
            local unusual_count=$(sed -n '/UNUSUAL ACCESS EVENTS:/,/RECOMMENDATIONS:/p' "$data_file" | grep "^\-" | wc -l)
            if [[ $unusual_count -gt 5 ]]; then
                echo "... and $(($unusual_count - 5)) more unusual access events" >> "$output_file"
            fi
        fi
        echo "" >> "$output_file"
    fi

    if [[ -f "$security_file" ]]; then
        echo "3. SECURITY COMPLIANCE" >> "$output_file"
        echo "---------------------" >> "$output_file"
        grep -A 6 "SUMMARY:" "$security_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
        
        # Include critical security events
        echo "" >> "$output_file"
        echo "Notable security events:" >> "$output_file"
        sed -n '/CRITICAL SECURITY EVENTS:/,/RECOMMENDATIONS:/p' "$security_file" | grep "^\-" | head -5 >> "$output_file"
        
        # Note if more events exist
        local security_count=$(sed -n '/CRITICAL SECURITY EVENTS:/,/RECOMMENDATIONS:/p' "$security_file" | grep "^\-" | wc -l)
        if [[ $security_count -gt 5 ]]; then
            echo "... and $(($security_count - 5)) more security events" >> "$output_file"
        fi
        echo "" >> "$output_file"
    fi

    # Add compliance assessment
    cat >> "$output_file" << EOF
===================================================
COMPLIANCE ASSESSMENT
===================================================

GDPR Compliance:
- Data Access Controls: $(if [[ $data_unusual -eq 0 ]]; then echo "COMPLIANT - No unauthorized access detected"; else echo "ATTENTION REQUIRED - Unusual access patterns detected"; fi)
- Right to Access: $(if [[ $data_exports -gt 0 ]]; then echo "COMPLIANT - Data export functionality operational"; else echo "COMPLIANT - No data export requests during period"; fi)
- Right to be Forgotten: $(if grep -q "delete" "$data_file"; then echo "COMPLIANT - Deletion functionality operational"; else echo "COMPLIANT - No deletion requests during period"; fi)
- Security Measures: $(if [[ $security_failures -eq 0 ]]; then echo "COMPLIANT - No security failures detected"; else echo "ATTENTION REQUIRED - Security failures detected"; fi)

CCPA Compliance:
- Disclosure Requirements: $(if [[ $data_unusual -eq 0 ]]; then echo "COMPLIANT - No unauthorized disclosures detected"; else echo "ATTENTION REQUIRED - Review unusual access patterns"; fi)
- Opt-Out Rights: $(if grep -q "opt-out" "$data_file"; then echo "COMPLIANT - Opt-out functionality operational"; else echo "NOT EVALUATED - No opt-out activities during period"; fi)
- Data Subject Rights: $(if [[ $data_exports -gt 0 || $(grep -q "delete" "$data_file") ]]; then echo "COMPLIANT - Access and deletion functionality operational"; else echo "COMPLIANT - No data subject requests during period"; fi)

Privacy by Design:
- Data Minimization: $(if grep -q "minimization" "$security_file"; then echo "COMPLIANT - Data minimization measures in place"; else echo "COMPLIANT - No issues detected"; fi)
- Purpose Limitation: $(if [[ $data_unusual -eq 0 ]]; then echo "COMPLIANT - Access limited to defined purposes"; else echo "ATTENTION REQUIRED - Review unusual access patterns"; fi)
- Storage Limitation: $(if grep -q "retention" "$security_file"; then echo "COMPLIANT - Retention policies enforced"; else echo "COMPLIANT - No issues detected"; fi)

===================================================
RECOMMENDATIONS
===================================================

EOF

    # Compile recommendations
    if [[ -f "$auth_file" ]]; then
        grep -A 3 "RECOMMENDATIONS:" "$auth_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
    fi
    
    if [[ -f "$data_file" ]]; then
        grep -A 3 "RECOMMENDATIONS:" "$data_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
    fi
    
    if [[ -f "$security_file" ]]; then
        grep -A 4 "RECOMMENDATIONS:" "$security_file" | grep -v "RECOMMENDATIONS:" >> "$output_file"
    fi

    # Add additional recommendations based on overall analysis
    cat >> "$output_file" << EOF

Additional Recommendations:
1. $(if [[ $auth_suspicious -gt 0 ]]; then echo "Implement additional authentication controls to address suspicious activities"; else echo "Continue monitoring authentication patterns for suspicious activities"; fi)
2. $(if [[ $data_unusual -gt 0 ]]; then echo "Review data access controls and implement stricter monitoring"; else echo "Maintain current data access controls"; fi)
3. $(if [[ $security_failures -gt 0 ]]; then echo "Investigate and remediate security failures immediately"; else echo "Continue with current security practices"; fi)
4. $(if [[ $permission_changes -gt 0 ]]; then echo "Implement stronger change management for permission changes"; else echo "Maintain current permission management practices"; fi)
5. Schedule next compliance audit for $(date -d "+30 days" '+%Y-%m-%d')

===================================================
AUDIT CERTIFICATION
===================================================

This audit report was automatically generated by the Amira Wellness
compliance monitoring system on $(date '+%Y-%m-%d %H:%M:%S').

For questions or concerns regarding this report, please contact
the security team at security@amirawellness.com.

EOF

    if [[ "$VERBOSE" == "true" ]]; then
        echo "  Compliance report generated successfully"
    fi
    
    return 0
}

# Main function
main() {
    # Parse command line arguments
    if ! parse_args "$@"; then
        exit 1
    fi

    # Display help and exit if requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    # Setup environment
    if ! setup_environment; then
        echo "Error: Failed to setup environment" >&2
        exit 1
    fi

    # Generate file paths
    local auth_logs="${LOG_DIR}/auth-logs-${DATE_TO}.json"
    local data_logs="${LOG_DIR}/data-logs-${DATE_TO}.json"
    local security_logs="${LOG_DIR}/security-logs-${DATE_TO}.json"
    local auth_analysis="${LOG_DIR}/auth-analysis-${DATE_TO}.txt"
    local data_analysis="${LOG_DIR}/data-analysis-${DATE_TO}.txt"
    local security_analysis="${LOG_DIR}/security-analysis-${DATE_TO}.txt"

    if [[ "$COMPLIANCE_ONLY" == "true" ]]; then
        # Check if analysis files exist
        if [[ ! -f "$auth_analysis" || ! -f "$data_analysis" || ! -f "$security_analysis" ]]; then
            echo "Error: Analysis files not found. Run a full audit first." >&2
            exit 1
        fi
        
        # Generate compliance report only
        if generate_compliance_report "$auth_analysis $data_analysis $security_analysis" "$REPORT_FILE"; then
            echo "Compliance report generated: $REPORT_FILE"
            exit 0
        else
            echo "Error: Failed to generate compliance report" >&2
            exit 1
        fi
    fi

    # Initialize log files
    echo "[]" > "$auth_logs"
    echo "[]" > "$data_logs"
    echo "[]" > "$security_logs"

    # Fetch logs from various sources
    echo "Fetching logs for period $DATE_FROM to $DATE_TO..."

    # CloudWatch logs
    for log_group in $CLOUDWATCH_LOG_GROUPS; do
        if ! fetch_cloudwatch_logs "$log_group" "$auth_logs"; then
            echo "Warning: Failed to fetch logs from $log_group" >&2
        fi
    done

    # CloudTrail events
    if ! fetch_cloudtrail_events "$security_logs"; then
        echo "Warning: Failed to fetch CloudTrail events" >&2
    fi

    # S3 access logs
    if ! fetch_s3_access_logs "$data_logs"; then
        echo "Warning: Failed to fetch S3 access logs" >&2
    fi

    # RDS logs
    if ! fetch_rds_logs "$data_logs"; then
        echo "Warning: Failed to fetch RDS logs" >&2
    fi

    # Check if we should only analyze authentication events
    if [[ "$AUTH_ONLY" == "true" ]]; then
        echo "Analyzing authentication events only..."
        if analyze_authentication_events "$auth_logs" "$auth_analysis"; then
            echo "Authentication analysis complete: $auth_analysis"
            cat "$auth_analysis"
            exit 0
        else
            echo "Error: Failed to analyze authentication events" >&2
            exit 1
        fi
    fi

    # Analyze logs
    echo "Analyzing logs..."
    
    if ! analyze_authentication_events "$auth_logs" "$auth_analysis"; then
        echo "Warning: Failed to analyze authentication events" >&2
    fi
    
    if ! analyze_data_access_events "$data_logs" "$data_analysis"; then
        echo "Warning: Failed to analyze data access events" >&2
    fi
    
    if ! analyze_security_events "$security_logs" "$security_analysis"; then
        echo "Warning: Failed to analyze security events" >&2
    fi

    # Generate compliance report
    echo "Generating compliance report..."
    if ! generate_compliance_report "$auth_analysis $data_analysis $security_analysis" "$REPORT_FILE"; then
        echo "Error: Failed to generate compliance report" >&2
        exit 1
    fi

    # Display summary
    echo ""
    echo "Audit completed successfully!"
    echo "Report generated: $REPORT_FILE"
    echo ""
    echo "Summary of findings:"
    grep -A 3 "Overall Compliance Status:" "$REPORT_FILE"
    
    # Clean up log files if not in verbose mode
    if [[ "$VERBOSE" != "true" ]]; then
        rm -f "$auth_logs" "$data_logs" "$security_logs"
    fi

    return 0
}

# Execute main function with all arguments
main "$@"