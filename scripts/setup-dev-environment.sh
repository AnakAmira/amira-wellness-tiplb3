#!/bin/bash
#
# Amira Wellness Development Environment Setup
# This script automates the setup of a complete development environment for the Amira Wellness
# application. It installs required dependencies, configures development tools, sets up databases,
# and prepares the environment for both backend and mobile development.
#

# Exit on error
set -e

# Global variables for paths
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
PROJECT_ROOT=$(realpath "$SCRIPT_DIR/..")
BACKEND_DIR="$PROJECT_ROOT/src/backend"
IOS_DIR="$PROJECT_ROOT/src/ios"
ANDROID_DIR="$PROJECT_ROOT/src/android"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/infrastructure/docker/docker-compose.yml"
ENV_FILE="$BACKEND_DIR/.env"
ENV_EXAMPLE_FILE="$BACKEND_DIR/.env.example"
LOG_FILE="$PROJECT_ROOT/setup-dev-environment.log"

# Display a welcome banner for the script
print_banner() {
    echo "================================================================="
    echo "          AMIRA WELLNESS DEVELOPMENT ENVIRONMENT SETUP           "
    echo "================================================================="
    echo "This script will set up your development environment for"
    echo "the Amira Wellness application."
    echo ""
    echo "Project root: $PROJECT_ROOT"
    echo "Log file: $LOG_FILE"
    echo "================================================================="
    echo ""
}

# Logs a message to both console and log file
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Logs an error message to both console and log file
log_error() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] \033[0;31mERROR: $1\033[0m"
    echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}

# Logs a success message to both console and log file
log_success() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] \033[0;32mSUCCESS: $1\033[0m"
    echo "[$timestamp] SUCCESS: $1" >> "$LOG_FILE"
}

# Checks if required tools are installed
check_prerequisites() {
    log "Checking prerequisites..."
    local missing_tools=()

    # Check for Git
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi

    # Check for Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_tools+=("docker-compose")
    fi

    # Check for Python
    if ! command -v python3 &> /dev/null; then
        missing_tools+=("python3")
    fi

    # Check for pip
    if ! command -v pip3 &> /dev/null; then
        missing_tools+=("pip3")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log "Please install the missing tools and run the script again."
        return 1
    fi

    log_success "All prerequisites are met."
    return 0
}

# Detects the operating system and sets OS-specific variables
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        OS="linux"
        log "Detected Linux operating system"
        
        # Detect specific distribution
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            log "Linux distribution: $NAME"
            
            # Set package manager based on distribution
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
                PKG_MANAGER="apt-get"
                PKG_INSTALL="$PKG_MANAGER install -y"
            elif [[ "$ID" == "fedora" ]]; then
                PKG_MANAGER="dnf"
                PKG_INSTALL="$PKG_MANAGER install -y"
            elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]]; then
                PKG_MANAGER="yum"
                PKG_INSTALL="$PKG_MANAGER install -y"
            else
                log "Unsupported Linux distribution for automatic package installation"
            fi
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        OS="macos"
        log "Detected macOS operating system"
        
        # Check if Homebrew is installed
        if command -v brew &> /dev/null; then
            PKG_MANAGER="brew"
            PKG_INSTALL="$PKG_MANAGER install"
        else
            log "Homebrew not found. Some automatic installations may not work."
        fi
        
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows with Git Bash or similar
        OS="windows"
        log "Detected Windows operating system"
        log "Note: For best results on Windows, use WSL (Windows Subsystem for Linux)"
    else
        OS="unknown"
        log "Detected unknown operating system: $OSTYPE"
    fi
    
    return "$OS"
}

# Sets up the backend development environment
setup_backend_environment() {
    log "Setting up backend environment..."
    
    # Create Python virtual environment if it doesn't exist
    if [ ! -d "$BACKEND_DIR/venv" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv "$BACKEND_DIR/venv"
    else
        log "Python virtual environment already exists"
    fi
    
    # Activate virtual environment
    source "$BACKEND_DIR/venv/bin/activate"
    
    # Install Python dependencies
    log "Installing Python dependencies..."
    pip3 install --upgrade pip
    pip3 install -r "$BACKEND_DIR/requirements.txt"
    
    # Create .env file from example if it doesn't exist
    if [ ! -f "$ENV_FILE" ] && [ -f "$ENV_EXAMPLE_FILE" ]; then
        log "Creating .env file from example..."
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        
        # Set development environment in .env
        if ! grep -q "ENVIRONMENT=" "$ENV_FILE"; then
            echo "ENVIRONMENT=development" >> "$ENV_FILE"
        else
            sed -i.bak "s/ENVIRONMENT=.*/ENVIRONMENT=development/" "$ENV_FILE"
            rm -f "$ENV_FILE.bak"
        fi
        
        log "Environment file created and configured for development"
    elif [ ! -f "$ENV_EXAMPLE_FILE" ]; then
        log_error "Environment example file not found: $ENV_EXAMPLE_FILE"
        return 1
    fi
    
    # Deactivate virtual environment
    deactivate
    
    log_success "Backend environment setup completed"
    return 0
}

# Sets up the PostgreSQL database for development
setup_database() {
    log "Setting up database..."
    
    # Source the database migration helper
    source "$SCRIPT_DIR/db-migration-helper.sh"
    
    # Check if PostgreSQL is running (locally or in Docker)
    local pg_running=false
    
    if command -v pg_isready &> /dev/null; then
        if pg_isready &> /dev/null; then
            pg_running=true
            log "PostgreSQL is running locally"
        fi
    fi
    
    if ! $pg_running; then
        if docker ps | grep -q postgres; then
            pg_running=true
            log "PostgreSQL is running in Docker"
        else
            log "Starting PostgreSQL in Docker..."
            if [ -f "$DOCKER_COMPOSE_FILE" ]; then
                docker-compose -f "$DOCKER_COMPOSE_FILE" up -d postgres
                sleep 10  # Wait for PostgreSQL to start
                pg_running=true
            else
                log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
                return 1
            fi
        fi
    fi
    
    if ! $pg_running; then
        log_error "PostgreSQL is not running and could not be started"
        return 1
    fi
    
    # Initialize database using the helper script function
    log "Initializing database schema..."
    init_database
    if [ $? -ne 0 ]; then
        log_error "Database initialization failed"
        return 1
    fi
    
    # Generate test data
    log "Generating test data..."
    # Activate virtual environment
    source "$BACKEND_DIR/venv/bin/activate"
    python3 "$SCRIPT_DIR/generate-test-data.py" --verbose
    if [ $? -ne 0 ]; then
        log_error "Test data generation failed"
        deactivate
        return 1
    fi
    deactivate
    
    log_success "Database setup completed"
    return 0
}

# Sets up Docker containers for development
setup_docker_environment() {
    log "Setting up Docker environment..."
    
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        return 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        return 1
    fi
    
    # Pull required Docker images
    log "Pulling Docker images..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" pull
    
    # Build custom images
    log "Building custom Docker images..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" build
    
    # Start Docker containers
    log "Starting Docker containers..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    # Check container health
    log "Waiting for containers to be healthy..."
    sleep 10
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
        log_error "Some containers failed to start. Check Docker logs for details."
        return 1
    fi
    
    log_success "Docker environment setup completed"
    return 0
}

# Sets up the iOS development environment
setup_ios_environment() {
    # Only proceed on macOS
    if [ "$OS" != "macos" ]; then
        log "Skipping iOS setup - not on macOS"
        return 0
    fi
    
    log "Setting up iOS environment..."
    
    # Check for Xcode
    if ! xcode-select -p &> /dev/null; then
        log_error "Xcode not found. Please install Xcode from the App Store."
        return 1
    fi
    
    # Check for CocoaPods
    if ! command -v pod &> /dev/null; then
        log "CocoaPods not found. Installing..."
        if command -v gem &> /dev/null; then
            sudo gem install cocoapods
        else
            log_error "Ruby gem command not found. Cannot install CocoaPods."
            return 1
        fi
    fi
    
    # Check if iOS directory exists
    if [ ! -d "$IOS_DIR" ]; then
        log_error "iOS project directory not found: $IOS_DIR"
        return 1
    fi
    
    # Install CocoaPods dependencies
    log "Installing CocoaPods dependencies..."
    cd "$IOS_DIR"
    pod install
    cd "$PROJECT_ROOT"
    
    log_success "iOS environment setup completed"
    return 0
}

# Sets up the Android development environment
setup_android_environment() {
    log "Setting up Android environment..."
    
    # Try to locate Android SDK
    local android_sdk_path=""
    
    if [ -n "$ANDROID_HOME" ]; then
        android_sdk_path="$ANDROID_HOME"
    elif [ -n "$ANDROID_SDK_ROOT" ]; then
        android_sdk_path="$ANDROID_SDK_ROOT"
    elif [ -d "$HOME/Android/Sdk" ]; then
        android_sdk_path="$HOME/Android/Sdk"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        android_sdk_path="$HOME/Library/Android/sdk"
    fi
    
    if [ -z "$android_sdk_path" ]; then
        log_error "Android SDK not found. Please install Android Studio and set ANDROID_HOME."
        log "You can add these lines to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        log "export ANDROID_HOME=\"\$HOME/Android/Sdk\""
        log "export PATH=\"\$PATH:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools\""
        return 1
    fi
    
    log "Android SDK found at: $android_sdk_path"
    
    # Check if Android project directory exists
    if [ ! -d "$ANDROID_DIR" ]; then
        log_error "Android project directory not found: $ANDROID_DIR"
        return 1
    fi
    
    # Create local.properties file with SDK path
    echo "sdk.dir=$android_sdk_path" > "$ANDROID_DIR/local.properties"
    log "Created local.properties file"
    
    # Check for Gradle
    if ! command -v gradle &> /dev/null; then
        log "Gradle not found. Will use the project's Gradle wrapper."
    fi
    
    # Verify Gradle wrapper
    if [ -f "$ANDROID_DIR/gradlew" ]; then
        log "Setting Gradle wrapper as executable..."
        chmod +x "$ANDROID_DIR/gradlew"
        
        # Run Gradle wrapper to verify it works
        log "Verifying Gradle wrapper..."
        cd "$ANDROID_DIR"
        ./gradlew --version
        cd "$PROJECT_ROOT"
    else
        log_error "Gradle wrapper script not found: $ANDROID_DIR/gradlew"
        return 1
    fi
    
    log_success "Android environment setup completed"
    return 0
}

# Sets up Git hooks for development workflow
setup_git_hooks() {
    log "Setting up Git hooks..."
    
    # Check if pre-commit is installed
    if ! command -v pre-commit &> /dev/null; then
        log "Installing pre-commit..."
        pip3 install pre-commit
    else
        log "pre-commit already installed"
    fi
    
    # Check if we're in a Git repository
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        log_error "Not a Git repository. Git hooks cannot be installed."
        return 1
    fi
    
    # Install pre-commit hooks
    cd "$PROJECT_ROOT"
    pre-commit install
    
    log_success "Git hooks setup completed"
    return 0
}

# Displays a completion message with next steps
print_completion_message() {
    echo ""
    echo "================================================================="
    echo "          AMIRA WELLNESS DEVELOPMENT ENVIRONMENT SETUP           "
    echo "                        SETUP COMPLETE                           "
    echo "================================================================="
    echo ""
    echo "Your development environment has been successfully set up!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Start the backend server:"
    echo "   cd $BACKEND_DIR && source venv/bin/activate && python manage.py runserver"
    echo ""
    echo "2. Open the iOS project in Xcode (macOS only):"
    echo "   open $IOS_DIR/AmiraWellness.xcworkspace"
    echo ""
    echo "3. Open the Android project in Android Studio:"
    echo "   Import project from $ANDROID_DIR"
    echo ""
    echo "For more information, please refer to the project documentation."
    echo "================================================================="
}

# Performs cleanup operations when an error occurs
cleanup_on_error() {
    log_error "Setup failed. Performing cleanup..."
    
    # Stop Docker containers if they were started
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        log "Stopping Docker containers..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" down
    fi
    
    log "Setup failed. Please check the log file for details: $LOG_FILE"
    exit 1
}

# Parses command-line arguments
parse_args() {
    # Default values
    SKIP_BACKEND=false
    SKIP_IOS=false
    SKIP_ANDROID=false
    SKIP_DOCKER=false
    SKIP_DATABASE=false
    FORCE=false
    
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --skip-backend)
                SKIP_BACKEND=true
                shift
                ;;
            --skip-ios)
                SKIP_IOS=true
                shift
                ;;
            --skip-android)
                SKIP_ANDROID=true
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-database)
                SKIP_DATABASE=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help)
                echo "Usage: ./scripts/setup-dev-environment.sh [options]"
                echo ""
                echo "Options:"
                echo "  --skip-backend    Skip backend environment setup"
                echo "  --skip-ios        Skip iOS environment setup"
                echo "  --skip-android    Skip Android environment setup"
                echo "  --skip-docker     Skip Docker environment setup"
                echo "  --skip-database   Skip database setup"
                echo "  --force           Force setup even if already done"
                echo "  --help            Display this help message"
                echo ""
                echo "Examples:"
                echo "  ./scripts/setup-dev-environment.sh"
                echo "  ./scripts/setup-dev-environment.sh --skip-ios --skip-android"
                echo "  ./scripts/setup-dev-environment.sh --force"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main function that orchestrates the setup process
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize log file
    echo "Amira Wellness Development Environment Setup Log" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "===============================================" >> "$LOG_FILE"
    
    # Display banner
    print_banner
    
    # Set trap for error handling
    trap cleanup_on_error ERR
    
    # Check prerequisites
    check_prerequisites || exit 1
    
    # Detect operating system
    check_os
    
    # Setup components based on flags
    if [ "$SKIP_BACKEND" = false ]; then
        setup_backend_environment || exit 1
    else
        log "Skipping backend setup (--skip-backend flag is set)"
    fi
    
    if [ "$SKIP_DOCKER" = false ]; then
        setup_docker_environment || exit 1
    else
        log "Skipping Docker setup (--skip-docker flag is set)"
    fi
    
    if [ "$SKIP_DATABASE" = false ]; then
        setup_database || exit 1
    else
        log "Skipping database setup (--skip-database flag is set)"
    fi
    
    if [ "$SKIP_IOS" = false ]; then
        setup_ios_environment || exit 1
    else
        log "Skipping iOS setup (--skip-ios flag is set)"
    fi
    
    if [ "$SKIP_ANDROID" = false ]; then
        setup_android_environment || exit 1
    else
        log "Skipping Android setup (--skip-android flag is set)"
    fi
    
    # Set up Git hooks (always done unless there's an error)
    setup_git_hooks || exit 1
    
    # Display completion message
    print_completion_message
    
    # Log completion
    log_success "Setup completed successfully!"
    echo "Setup completed at: $(date)" >> "$LOG_FILE"
    
    return 0
}

# Execute main function with all arguments
main "$@"