#!/bin/bash
#
# Amira Wellness Database Migration Helper
# This script provides helper functions and commands for managing database migrations
# in the Amira Wellness application, with safeguards for different environments.
#

# Global variables for paths and configurations
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
BACKEND_DIR="$PROJECT_ROOT/src/backend"
MIGRATIONS_DIR="$BACKEND_DIR/migrations"
ALEMBIC_INI="$BACKEND_DIR/alembic.ini"
ENV_FILE="$BACKEND_DIR/.env"
DEFAULT_ENV="development"
LOG_FILE="$SCRIPT_DIR/db_migration.log"

# Display usage information for the script
print_usage() {
    echo "Amira Wellness Database Migration Helper"
    echo "Usage: $(basename "$0") [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create [message] [--autogenerate]  Create a new migration script"
    echo "  upgrade [target]                   Upgrade database to specified revision (default: head)"
    echo "  downgrade [target]                 Downgrade database to specified revision"
    echo "  history [--verbose]                Show migration history"
    echo "  current                            Show current database revision"
    echo "  verify                             Verify migration scripts for consistency"
    echo ""
    echo "Options:"
    echo "  --backup                           Create database backup before migration"
    echo "  --autogenerate                     Generate migration based on model changes"
    echo "  --verbose                          Show detailed information"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") create \"Add user table\" --autogenerate"
    echo "  $(basename "$0") upgrade"
    echo "  $(basename "$0") upgrade head"
    echo "  $(basename "$0") downgrade -1"
    echo "  $(basename "$0") history"
    echo "  $(basename "$0") current"
    echo "  $(basename "$0") verify"
}

# Log a message to both stdout and the log file
log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local formatted_message="[$timestamp] [$level] $message"
    
    echo "$formatted_message"
    echo "$formatted_message" >> "$LOG_FILE"
}

# Check if the current environment is allowed for the operation
check_environment() {
    local env="$1"
    local operation="$2"
    
    # Operations that need special confirmation in production
    if [ "$env" == "production" ] && [ "$operation" == "downgrade" ]; then
        log_message "WARNING: You are about to perform a database downgrade in PRODUCTION environment" "WARNING"
        read -p "Are you sure you want to continue? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_message "Operation cancelled by user" "INFO"
            return 1
        fi
        log_message "Production operation confirmed by user" "WARNING"
    fi
    
    if [ "$env" == "production" ] && [ "$operation" == "upgrade" ]; then
        log_message "WARNING: You are about to perform a database upgrade in PRODUCTION environment" "WARNING"
        read -p "Are you sure you want to continue? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_message "Operation cancelled by user" "INFO"
            return 1
        fi
        log_message "Production operation confirmed by user" "WARNING"
    fi
    
    return 0
}

# Load environment variables from .env file if it exists
load_environment() {
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi
    
    # Get current environment or use default
    local env="${ENVIRONMENT:-$DEFAULT_ENV}"
    log_message "Current environment: $env" "INFO"
    
    echo "$env"
}

# Create a new migration script
create_migration() {
    local message="$1"
    local autogenerate="$2"
    
    if [ -z "$message" ]; then
        log_message "Migration message is required" "ERROR"
        return 1
    fi
    
    log_message "Creating new migration: $message" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    local auto_flag=""
    if [ "$autogenerate" == "true" ]; then
        auto_flag="--autogenerate"
        log_message "Autogenerating migration based on model changes" "INFO"
    fi
    
    # Create migration using alembic
    alembic revision $auto_flag -m "$message"
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_message "Migration created successfully" "INFO"
    else
        log_message "Failed to create migration" "ERROR"
    fi
    
    return $status
}

# Run database migrations (upgrade or downgrade)
run_migrations() {
    local direction="$1"
    local target="$2"
    
    # Validate direction
    if [ "$direction" != "upgrade" ] && [ "$direction" != "downgrade" ]; then
        log_message "Invalid direction: $direction (must be 'upgrade' or 'downgrade')" "ERROR"
        return 1
    fi
    
    # Set default target for upgrade if not specified
    if [ "$direction" == "upgrade" ] && [ -z "$target" ]; then
        target="head"
    fi
    
    # Get current environment
    local env=$(load_environment)
    
    # Check if operation is allowed in current environment
    check_environment "$env" "$direction"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    log_message "Running database $direction to target: $target" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    # Execute migration
    alembic "$direction" "$target"
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_message "Migration $direction completed successfully" "INFO"
    else
        log_message "Migration $direction failed" "ERROR"
    fi
    
    return $status
}

# Show migration history
show_migration_history() {
    local verbose="$1"
    
    log_message "Showing migration history" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    local verbose_flag=""
    if [ "$verbose" == "true" ]; then
        verbose_flag="-v"
    fi
    
    # Show history using alembic
    alembic history $verbose_flag
    return $?
}

# Show current database revision
show_current_revision() {
    log_message "Showing current database revision" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    # Show current revision using alembic
    alembic current
    return $?
}

# Verify migration scripts for consistency
verify_migrations() {
    log_message "Verifying migration scripts for consistency" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    # Verify migrations using alembic
    alembic check
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_message "Migration scripts verification passed" "INFO"
    else
        log_message "Migration scripts verification failed" "ERROR"
    fi
    
    return $status
}

# Create a database backup before running migrations
backup_database() {
    log_message "Creating database backup before migration" "INFO"
    
    # Change to backend directory
    cd "$BACKEND_DIR" || { log_message "Failed to change to backend directory" "ERROR"; return 1; }
    
    # Run database backup script
    if [ -f "$SCRIPT_DIR/db-backup.sh" ]; then
        "$SCRIPT_DIR/db-backup.sh" --pre-migration
        local status=$?
        
        if [ $status -eq 0 ]; then
            log_message "Database backup created successfully" "INFO"
        else
            log_message "Database backup failed" "ERROR"
        fi
        
        return $status
    else
        # Fallback to direct PostgreSQL dump if backup script not found
        local db_name="${DB_NAME:-amira_db}"
        local backup_dir="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
        local timestamp=$(date "+%Y%m%d_%H%M%S")
        local backup_file="$backup_dir/pre_migration_${db_name}_${timestamp}.sql"
        
        # Create backup directory if it doesn't exist
        mkdir -p "$backup_dir"
        
        log_message "Backing up database $db_name to $backup_file" "INFO"
        PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$db_name" -f "$backup_file"
        local status=$?
        
        if [ $status -eq 0 ]; then
            log_message "Database backup created successfully at $backup_file" "INFO"
        else
            log_message "Database backup failed" "ERROR"
        fi
        
        return $status
    fi
}

# Main function that processes command-line arguments and executes appropriate functions
main() {
    # If no arguments provided, show usage
    if [ $# -eq 0 ]; then
        print_usage
        return 1
    fi
    
    # Parse command
    local command="$1"
    shift
    
    # Load environment
    local env=$(load_environment)
    
    # Process command
    case "$command" in
        create)
            local message=""
            local autogenerate="false"
            
            # Parse arguments
            while [ $# -gt 0 ]; do
                case "$1" in
                    --autogenerate)
                        autogenerate="true"
                        shift
                        ;;
                    *)
                        if [ -z "$message" ]; then
                            message="$1"
                        fi
                        shift
                        ;;
                esac
            done
            
            create_migration "$message" "$autogenerate"
            ;;
        
        upgrade|downgrade)
            local target=""
            local backup="false"
            
            # Parse arguments
            while [ $# -gt 0 ]; do
                case "$1" in
                    --backup)
                        backup="true"
                        shift
                        ;;
                    *)
                        if [ -z "$target" ]; then
                            target="$1"
                        fi
                        shift
                        ;;
                esac
            done
            
            # Create backup if requested
            if [ "$backup" == "true" ]; then
                backup_database
                if [ $? -ne 0 ]; then
                    log_message "Aborting migration due to backup failure" "ERROR"
                    return 1
                fi
            fi
            
            run_migrations "$command" "$target"
            ;;
        
        history)
            local verbose="false"
            
            # Parse arguments
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        verbose="true"
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            show_migration_history "$verbose"
            ;;
        
        current)
            show_current_revision
            ;;
        
        verify)
            verify_migrations
            ;;
        
        help)
            print_usage
            return 0
            ;;
        
        *)
            echo "Unknown command: $command"
            print_usage
            return 1
            ;;
    esac
    
    return $?
}

# Execute main function with all arguments
main "$@"