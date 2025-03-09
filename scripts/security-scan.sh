#!/bin/bash
# security-scan.sh
#
# A comprehensive security scanning script for the Amira Wellness application.
# This script automates vulnerability detection, dependency checking, and security report generation
# for backend Python code, mobile applications (iOS and Android), and container images.
#
# Version: 1.0.0

# Global variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(realpath "${SCRIPT_DIR}/..")"
OUTPUT_DIR="${REPO_ROOT}/security-reports"
SEVERITY_THRESHOLD="MEDIUM"
LOG_FILE=""
EXIT_CODE=0

# Terminal colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
NC="\033[0m" # No Color

# Log messages to console and log file
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} ${message}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${message}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${message}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${message}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
    
    if [ -n "$LOG_FILE" ]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# Checks if required tools are installed
check_dependencies() {
    local missing_tools=()
    local required_tools=(
        "safety"
        "bandit"
        "trivy"
        "mobsfscan"
        "gitleaks"
    )
    
    log "INFO" "Checking for required security scanning tools..."
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
            log "WARNING" "Missing required tool: $tool"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "Please install the following required tools: ${missing_tools[*]}"
        log "INFO" "You can install Python tools with: pip install safety bandit mobsfscan"
        log "INFO" "For Trivy installation, see: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        log "INFO" "For Gitleaks installation, see: https://github.com/zricethezav/gitleaks#installation"
        return 1
    fi
    
    log "SUCCESS" "All required tools are installed."
    return 0
}

# Prepares the environment for security scanning
setup_environment() {
    # Use environment variables if set
    if [ -n "$SECURITY_SCAN_SEVERITY" ]; then
        SEVERITY_THRESHOLD="$SECURITY_SCAN_SEVERITY"
    fi
    
    if [ -n "$SECURITY_SCAN_OUTPUT_DIR" ]; then
        OUTPUT_DIR="$SECURITY_SCAN_OUTPUT_DIR"
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to create output directory: $OUTPUT_DIR"
            return 1
        fi
    fi
    
    # Setup logging
    LOG_FILE="${OUTPUT_DIR}/security-scan-$(date +"%Y%m%d%H%M%S").log"
    touch "$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} Failed to create log file: $LOG_FILE"
        LOG_FILE=""
    fi
    
    log "INFO" "Security scan started at $(date)"
    log "INFO" "Repository root: $REPO_ROOT"
    log "INFO" "Output directory: $OUTPUT_DIR"
    log "INFO" "Severity threshold: $SEVERITY_THRESHOLD"
    
    return 0
}

# Scans Python dependencies for known vulnerabilities
scan_python_dependencies() {
    local requirements_file="$1"
    
    if [ ! -f "$requirements_file" ]; then
        log "ERROR" "Requirements file not found: $requirements_file"
        return 1
    fi
    
    log "INFO" "Scanning Python dependencies in: $requirements_file"
    
    local output_file="${OUTPUT_DIR}/python-dependencies-scan.json"
    
    safety check --file="$requirements_file" --output=json --save-json="$output_file" 2>/dev/null
    local scan_exit_code=$?
    
    # Count vulnerabilities by severity
    local vuln_count=$(jq '.vulnerabilities | length' "$output_file" 2>/dev/null || echo "0")
    
    if [ "$vuln_count" -gt 0 ]; then
        log "WARNING" "Found $vuln_count potential vulnerabilities in Python dependencies"
        
        # Display a summary of findings
        log "INFO" "Vulnerability summary:"
        jq -r '.vulnerabilities[] | "\(.severity): \(.package_name) \(.vulnerable_spec) - \(.advisory)"' "$output_file" 2>/dev/null | \
        while read -r line; do
            log "WARNING" "$line"
        done
        
        # Check against threshold
        local high_critical=$(jq -r '.vulnerabilities[] | select(.severity == "high" or .severity == "critical") | .severity' "$output_file" 2>/dev/null | wc -l)
        
        if [ "$high_critical" -gt 0 ] && [[ "$SEVERITY_THRESHOLD" == "HIGH" || "$SEVERITY_THRESHOLD" == "CRITICAL" ]]; then
            log "ERROR" "Found $high_critical high or critical severity vulnerabilities"
            return 1
        fi
    else
        log "SUCCESS" "No vulnerabilities found in Python dependencies"
    fi
    
    return $scan_exit_code
}

# Performs static analysis on Python code to find security issues
scan_python_code() {
    local source_dir="$1"
    
    if [ ! -d "$source_dir" ]; then
        log "ERROR" "Source directory not found: $source_dir"
        return 1
    fi
    
    log "INFO" "Performing static analysis on Python code in: $source_dir"
    
    local output_file="${OUTPUT_DIR}/python-code-scan.json"
    
    bandit -r "$source_dir" -f json -o "$output_file" 2>/dev/null
    local scan_exit_code=$?
    
    # Count issues by severity
    local issue_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
    
    if [ "$issue_count" -gt 0 ]; then
        log "WARNING" "Found $issue_count potential security issues in Python code"
        
        # Display a summary of findings
        log "INFO" "Security issue summary:"
        jq -r '.results[] | "\(.issue_severity): \(.issue_text) at \(.filename):\(.line_number)"' "$output_file" 2>/dev/null | \
        while read -r line; do
            log "WARNING" "$line"
        done
        
        # Check against threshold
        local high_count=$(jq -r '.results[] | select(.issue_severity == "HIGH") | .issue_severity' "$output_file" 2>/dev/null | wc -l)
        local medium_count=$(jq -r '.results[] | select(.issue_severity == "MEDIUM") | .issue_severity' "$output_file" 2>/dev/null | wc -l)
        
        if [ "$high_count" -gt 0 ] && [[ "$SEVERITY_THRESHOLD" == "HIGH" || "$SEVERITY_THRESHOLD" == "CRITICAL" ]]; then
            log "ERROR" "Found $high_count high severity issues in Python code"
            return 1
        elif [ "$medium_count" -gt 0 ] && [[ "$SEVERITY_THRESHOLD" == "MEDIUM" ]]; then
            log "ERROR" "Found $medium_count medium severity issues in Python code"
            return 1
        fi
    else
        log "SUCCESS" "No security issues found in Python code"
    fi
    
    return $scan_exit_code
}

# Scans container images for vulnerabilities
scan_container_image() {
    local image_name="$1"
    
    if [ -z "$image_name" ]; then
        log "ERROR" "No container image specified"
        return 1
    fi
    
    log "INFO" "Scanning container image: $image_name"
    
    local output_file="${OUTPUT_DIR}/container-scan.json"
    local sarif_file="${OUTPUT_DIR}/container-scan.sarif"
    
    # Pull the image first if it doesn't exist locally
    docker pull "$image_name" &>/dev/null
    if [ $? -ne 0 ]; then
        log "WARNING" "Failed to pull image: $image_name. Will try to scan anyway."
    fi
    
    # Run trivy scan
    trivy image --format json --output "$output_file" "$image_name" 2>/dev/null
    local scan_exit_code=$?
    
    # Also generate SARIF format for better CI/CD integration
    trivy image --format sarif --output "$sarif_file" "$image_name" 2>/dev/null
    
    # Count vulnerabilities by severity
    local vuln_count=$(jq '.Results[] | .Vulnerabilities | length' "$output_file" 2>/dev/null | awk '{sum+=$1} END {print sum}')
    
    if [ -z "$vuln_count" ] || [ "$vuln_count" == "null" ]; then
        vuln_count=0
    fi
    
    if [ "$vuln_count" -gt 0 ]; then
        log "WARNING" "Found $vuln_count potential vulnerabilities in container image"
        
        # Display a summary by severity
        log "INFO" "Vulnerability summary by severity:"
        jq -r '.Results[] | .Vulnerabilities[] | .Severity' "$output_file" 2>/dev/null | sort | uniq -c | \
        while read -r count severity; do
            log "WARNING" "$count $severity severity vulnerabilities"
        done
        
        # Check against threshold
        local critical_count=$(jq -r '.Results[] | .Vulnerabilities[] | select(.Severity == "CRITICAL") | .Severity' "$output_file" 2>/dev/null | wc -l)
        local high_count=$(jq -r '.Results[] | .Vulnerabilities[] | select(.Severity == "HIGH") | .Severity' "$output_file" 2>/dev/null | wc -l)
        
        if [ "$critical_count" -gt 0 ] && [ "$SEVERITY_THRESHOLD" == "CRITICAL" ]; then
            log "ERROR" "Found $critical_count critical severity vulnerabilities in container image"
            return 1
        elif [ "$high_count" -gt 0 ] && [[ "$SEVERITY_THRESHOLD" == "HIGH" || "$SEVERITY_THRESHOLD" == "CRITICAL" ]]; then
            log "ERROR" "Found $high_count high severity vulnerabilities in container image"
            return 1
        fi
    else
        log "SUCCESS" "No vulnerabilities found in container image"
    fi
    
    return $scan_exit_code
}

# Scans mobile application code for security issues
scan_mobile_code() {
    local platform="$1"
    local source_dir="$2"
    
    if [ ! -d "$source_dir" ]; then
        log "ERROR" "Source directory not found: $source_dir"
        return 1
    fi
    
    log "INFO" "Scanning $platform mobile code in: $source_dir"
    
    local output_file="${OUTPUT_DIR}/mobile-${platform}-scan.json"
    
    mobsfscan "$source_dir" --json --output "$output_file" 2>/dev/null
    local scan_exit_code=$?
    
    # Count issues by severity
    local issue_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
    
    if [ "$issue_count" -gt 0 ]; then
        log "WARNING" "Found $issue_count potential security issues in $platform code"
        
        # Display a summary of findings
        log "INFO" "Security issue summary:"
        jq -r '.results[] | "\(.severity): \(.description) at \(.file):\(.line)"' "$output_file" 2>/dev/null | \
        while read -r line; do
            log "WARNING" "$line"
        done
        
        # Check against threshold
        local high_count=$(jq -r '.results[] | select(.severity == "high") | .severity' "$output_file" 2>/dev/null | wc -l)
        local medium_count=$(jq -r '.results[] | select(.severity == "medium") | .severity' "$output_file" 2>/dev/null | wc -l)
        
        if [ "$high_count" -gt 0 ] && [[ "$SEVERITY_THRESHOLD" == "HIGH" || "$SEVERITY_THRESHOLD" == "CRITICAL" ]]; then
            log "ERROR" "Found $high_count high severity issues in $platform code"
            return 1
        elif [ "$medium_count" -gt 0 ] && [ "$SEVERITY_THRESHOLD" == "MEDIUM" ]; then
            log "ERROR" "Found $medium_count medium severity issues in $platform code"
            return 1
        fi
    else
        log "SUCCESS" "No security issues found in $platform code"
    fi
    
    return $scan_exit_code
}

# Scans repository for leaked secrets and credentials
scan_secrets() {
    local repo_dir="$1"
    
    if [ ! -d "$repo_dir" ]; then
        log "ERROR" "Repository directory not found: $repo_dir"
        return 1
    fi
    
    log "INFO" "Scanning for secrets in repository: $repo_dir"
    
    local output_file="${OUTPUT_DIR}/secrets-scan.json"
    
    gitleaks detect --source="$repo_dir" --report-format=json --report-path="$output_file" 2>/dev/null
    local scan_exit_code=$?
    
    # Count leaked secrets
    local secret_count=$(jq '. | length' "$output_file" 2>/dev/null || echo "0")
    
    if [ "$secret_count" -gt 0 ]; then
        log "ERROR" "Found $secret_count potential secrets in the repository"
        
        # Display a summary of findings
        log "INFO" "Secrets summary:"
        jq -r '.[] | "\(.Description) in \(.File):\(.StartLine)"' "$output_file" 2>/dev/null | \
        while read -r line; do
            log "ERROR" "$line"
        done
        
        return 1
    else
        log "SUCCESS" "No secrets found in the repository"
    fi
    
    return $scan_exit_code
}

# Generates a consolidated security report from all scan results
generate_report() {
    log "INFO" "Generating consolidated security report..."
    
    local report_file="${OUTPUT_DIR}/security-report.html"
    local date_time=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Initialize HTML report
    cat > "$report_file" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Amira Wellness Security Scan Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .critical {
            color: #721c24;
            background-color: #f8d7da;
            padding: 10px;
            border-radius: 5px;
        }
        .high {
            color: #856404;
            background-color: #fff3cd;
            padding: 10px;
            border-radius: 5px;
        }
        .medium {
            color: #0c5460;
            background-color: #d1ecf1;
            padding: 10px;
            border-radius: 5px;
        }
        .low {
            color: #155724;
            background-color: #d4edda;
            padding: 10px;
            border-radius: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Amira Wellness Security Scan Report</h1>
        <p><strong>Generated:</strong> $date_time</p>
        <p><strong>Severity Threshold:</strong> $SEVERITY_THRESHOLD</p>
        
        <div class="summary">
            <h2>Scan Summary</h2>
EOL
    
    # Count vulnerabilities by type and severity
    local python_dep_count=0
    local python_code_count=0
    local container_count=0
    local mobile_ios_count=0
    local mobile_android_count=0
    local secrets_count=0
    
    # Python dependencies
    local python_dep_file="${OUTPUT_DIR}/python-dependencies-scan.json"
    if [ -f "$python_dep_file" ]; then
        python_dep_count=$(jq '.vulnerabilities | length' "$python_dep_file" 2>/dev/null || echo "0")
    fi
    
    # Python code
    local python_code_file="${OUTPUT_DIR}/python-code-scan.json"
    if [ -f "$python_code_file" ]; then
        python_code_count=$(jq '.results | length' "$python_code_file" 2>/dev/null || echo "0")
    fi
    
    # Container
    local container_file="${OUTPUT_DIR}/container-scan.json"
    if [ -f "$container_file" ]; then
        container_count=$(jq '.Results[] | .Vulnerabilities | length' "$container_file" 2>/dev/null | awk '{sum+=$1} END {print sum}')
        if [ -z "$container_count" ] || [ "$container_count" == "null" ]; then
            container_count=0
        fi
    fi
    
    # Mobile iOS
    local mobile_ios_file="${OUTPUT_DIR}/mobile-ios-scan.json"
    if [ -f "$mobile_ios_file" ]; then
        mobile_ios_count=$(jq '.results | length' "$mobile_ios_file" 2>/dev/null || echo "0")
    fi
    
    # Mobile Android
    local mobile_android_file="${OUTPUT_DIR}/mobile-android-scan.json"
    if [ -f "$mobile_android_file" ]; then
        mobile_android_count=$(jq '.results | length' "$mobile_android_file" 2>/dev/null || echo "0")
    fi
    
    # Secrets
    local secrets_file="${OUTPUT_DIR}/secrets-scan.json"
    if [ -f "$secrets_file" ]; then
        secrets_count=$(jq '. | length' "$secrets_file" 2>/dev/null || echo "0")
    fi
    
    # Calculate total
    local total_count=$((python_dep_count + python_code_count + container_count + mobile_ios_count + mobile_android_count + secrets_count))
    
    # Add summary to report
    cat >> "$report_file" << EOL
            <p><strong>Total findings:</strong> $total_count</p>
            <ul>
                <li>Python dependencies: $python_dep_count</li>
                <li>Python code: $python_code_count</li>
                <li>Container images: $container_count</li>
                <li>iOS code: $mobile_ios_count</li>
                <li>Android code: $mobile_android_count</li>
                <li>Secrets: $secrets_count</li>
            </ul>
        </div>
EOL
    
    # Add Python dependencies section if available
    if [ -f "$python_dep_file" ] && [ "$python_dep_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>Python Dependencies</h2>
        <table>
            <tr>
                <th>Package</th>
                <th>Vulnerability</th>
                <th>Severity</th>
                <th>Advisory</th>
            </tr>
EOL
        
        jq -r '.vulnerabilities[] | "<tr class=\"\(.severity)\"><td>\(.package_name) \(.vulnerable_spec)</td><td>\(.vulnerability)</td><td>\(.severity)</td><td>\(.advisory)</td></tr>"' "$python_dep_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add Python code section if available
    if [ -f "$python_code_file" ] && [ "$python_code_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>Python Code</h2>
        <table>
            <tr>
                <th>Issue</th>
                <th>Severity</th>
                <th>Confidence</th>
                <th>Location</th>
            </tr>
EOL
        
        jq -r '.results[] | "<tr class=\"\(.issue_severity | ascii_downcase)\"><td>\(.issue_text)</td><td>\(.issue_severity)</td><td>\(.issue_confidence)</td><td>\(.filename):\(.line_number)</td></tr>"' "$python_code_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add Container section if available
    if [ -f "$container_file" ] && [ "$container_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>Container Images</h2>
        <table>
            <tr>
                <th>Package</th>
                <th>Vulnerability</th>
                <th>Severity</th>
                <th>Installed Version</th>
                <th>Fixed Version</th>
            </tr>
EOL
        
        jq -r '.Results[] | .Vulnerabilities[] | "<tr class=\"\(.Severity | ascii_downcase)\"><td>\(.PkgName)</td><td>\(.VulnerabilityID)</td><td>\(.Severity)</td><td>\(.InstalledVersion)</td><td>\(.FixedVersion // "Not available")</td></tr>"' "$container_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add Mobile iOS section if available
    if [ -f "$mobile_ios_file" ] && [ "$mobile_ios_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>iOS Application</h2>
        <table>
            <tr>
                <th>Issue</th>
                <th>Severity</th>
                <th>OWASP Category</th>
                <th>Location</th>
            </tr>
EOL
        
        jq -r '.results[] | "<tr class=\"\(.severity)\"><td>\(.description)</td><td>\(.severity)</td><td>\(.owasp || "N/A")</td><td>\(.file):\(.line)</td></tr>"' "$mobile_ios_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add Mobile Android section if available
    if [ -f "$mobile_android_file" ] && [ "$mobile_android_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>Android Application</h2>
        <table>
            <tr>
                <th>Issue</th>
                <th>Severity</th>
                <th>OWASP Category</th>
                <th>Location</th>
            </tr>
EOL
        
        jq -r '.results[] | "<tr class=\"\(.severity)\"><td>\(.description)</td><td>\(.severity)</td><td>\(.owasp || "N/A")</td><td>\(.file):\(.line)</td></tr>"' "$mobile_android_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add Secrets section if available
    if [ -f "$secrets_file" ] && [ "$secrets_count" -gt 0 ]; then
        cat >> "$report_file" << EOL
        <h2>Secrets</h2>
        <table>
            <tr>
                <th>Type</th>
                <th>Description</th>
                <th>File</th>
                <th>Line</th>
            </tr>
EOL
        
        jq -r '.[] | "<tr class=\"critical\"><td>\(.RuleID)</td><td>\(.Description)</td><td>\(.File)</td><td>\(.StartLine)</td></tr>"' "$secrets_file" 2>/dev/null >> "$report_file"
        
        cat >> "$report_file" << EOL
        </table>
EOL
    fi
    
    # Add recommendations and close HTML
    cat >> "$report_file" << EOL
        <h2>Recommendations</h2>
        <ul>
            <li>Review and address all critical and high severity findings before deployment</li>
            <li>Update vulnerable dependencies to their latest secure versions</li>
            <li>Implement secure coding practices to avoid common security issues</li>
            <li>Regularly scan for vulnerabilities and security issues</li>
            <li>Ensure all secrets are stored in a secure secrets management system, not in code</li>
        </ul>
    </div>
</body>
</html>
EOL
    
    log "SUCCESS" "Security report generated: $report_file"
    
    if [ "$total_count" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Checks if any critical vulnerabilities were found
check_critical() {
    log "INFO" "Checking for critical vulnerabilities..."
    
    local critical_count=0
    
    # Python dependencies
    local python_dep_file="${OUTPUT_DIR}/python-dependencies-scan.json"
    if [ -f "$python_dep_file" ]; then
        local python_critical=$(jq -r '.vulnerabilities[] | select(.severity == "critical") | .severity' "$python_dep_file" 2>/dev/null | wc -l)
        critical_count=$((critical_count + python_critical))
    fi
    
    # Python code
    local python_code_file="${OUTPUT_DIR}/python-code-scan.json"
    if [ -f "$python_code_file" ]; then
        local code_high=$(jq -r '.results[] | select(.issue_severity == "HIGH") | .issue_severity' "$python_code_file" 2>/dev/null | wc -l)
        critical_count=$((critical_count + code_high))
    fi
    
    # Container
    local container_file="${OUTPUT_DIR}/container-scan.json"
    if [ -f "$container_file" ]; then
        local container_critical=$(jq -r '.Results[] | .Vulnerabilities[] | select(.Severity == "CRITICAL") | .Severity' "$container_file" 2>/dev/null | wc -l)
        critical_count=$((critical_count + container_critical))
    fi
    
    # Mobile iOS
    local mobile_ios_file="${OUTPUT_DIR}/mobile-ios-scan.json"
    if [ -f "$mobile_ios_file" ]; then
        local ios_high=$(jq -r '.results[] | select(.severity == "high" or .severity == "critical") | .severity' "$mobile_ios_file" 2>/dev/null | wc -l)
        critical_count=$((critical_count + ios_high))
    fi
    
    # Mobile Android
    local mobile_android_file="${OUTPUT_DIR}/mobile-android-scan.json"
    if [ -f "$mobile_android_file" ]; then
        local android_high=$(jq -r '.results[] | select(.severity == "high" or .severity == "critical") | .severity' "$mobile_android_file" 2>/dev/null | wc -l)
        critical_count=$((critical_count + android_high))
    fi
    
    # Secrets (all secrets are considered critical)
    local secrets_file="${OUTPUT_DIR}/secrets-scan.json"
    if [ -f "$secrets_file" ]; then
        local secrets_count=$(jq '. | length' "$secrets_file" 2>/dev/null || echo "0")
        critical_count=$((critical_count + secrets_count))
    fi
    
    if [ "$critical_count" -gt 0 ]; then
        log "ERROR" "Found $critical_count critical or high severity security issues"
        return 1
    else
        log "SUCCESS" "No critical or high severity security issues found"
        return 0
    fi
}

# Print help information
show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo
    echo "A comprehensive security scanning script for the Amira Wellness application."
    echo
    echo "Options:"
    echo "  --scan-python         Scan Python code and dependencies"
    echo "  --scan-container      Scan container images"
    echo "  --scan-mobile         Scan mobile application code"
    echo "  --scan-secrets        Scan for secrets in the repository"
    echo "  --generate-report     Generate consolidated security report"
    echo "  --check-critical      Check for critical vulnerabilities"
    echo "  --severity LEVEL      Set minimum severity threshold (LOW, MEDIUM, HIGH, CRITICAL)"
    echo "  --output-dir DIR      Directory for scan output files"
    echo "  --help                Display this help message"
    echo
    echo "Environment variables:"
    echo "  SECURITY_SCAN_SEVERITY       Minimum severity threshold"
    echo "  SECURITY_SCAN_OUTPUT_DIR     Output directory"
    echo "  SECURITY_SCAN_SKIP_PYTHON    Set to 1 to skip Python scanning"
    echo "  SECURITY_SCAN_SKIP_CONTAINER Set to 1 to skip container scanning"
    echo "  SECURITY_SCAN_SKIP_MOBILE    Set to 1 to skip mobile scanning"
    echo "  SECURITY_SCAN_SKIP_SECRETS   Set to 1 to skip secrets scanning"
}

# Main function
main() {
    local do_python=0
    local do_container=0
    local do_mobile=0
    local do_secrets=0
    local do_report=0
    local do_critical=0
    local container_image="amira-api:latest"
    local exit_code=0
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --scan-python)
                do_python=1
                shift
                ;;
            --scan-container)
                do_container=1
                shift
                ;;
            --scan-mobile)
                do_mobile=1
                shift
                ;;
            --scan-secrets)
                do_secrets=1
                shift
                ;;
            --generate-report)
                do_report=1
                shift
                ;;
            --check-critical)
                do_critical=1
                shift
                ;;
            --severity)
                if [ -n "$2" ]; then
                    SEVERITY_THRESHOLD="$2"
                    shift 2
                else
                    log "ERROR" "Missing argument for --severity"
                    show_help
                    return 1
                fi
                ;;
            --output-dir)
                if [ -n "$2" ]; then
                    OUTPUT_DIR="$2"
                    shift 2
                else
                    log "ERROR" "Missing argument for --output-dir"
                    show_help
                    return 1
                fi
                ;;
            --help)
                show_help
                return 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                return 1
                ;;
        esac
    done
    
    # If no specific scan is requested, do all of them
    if [ "$do_python" -eq 0 ] && [ "$do_container" -eq 0 ] && [ "$do_mobile" -eq 0 ] && 
       [ "$do_secrets" -eq 0 ] && [ "$do_report" -eq 0 ] && [ "$do_critical" -eq 0 ]; then
        do_python=1
        do_container=1
        do_mobile=1
        do_secrets=1
        do_report=1
    fi
    
    # Apply environment variable overrides
    if [ "${SECURITY_SCAN_SKIP_PYTHON}" = "1" ]; then
        do_python=0
    fi
    
    if [ "${SECURITY_SCAN_SKIP_CONTAINER}" = "1" ]; then
        do_container=0
    fi
    
    if [ "${SECURITY_SCAN_SKIP_MOBILE}" = "1" ]; then
        do_mobile=0
    fi
    
    if [ "${SECURITY_SCAN_SKIP_SECRETS}" = "1" ]; then
        do_secrets=0
    fi
    
    # Check dependencies
    check_dependencies
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Setup environment
    setup_environment
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Run Python scans
    if [ "$do_python" -eq 1 ]; then
        local python_backend_dir="${REPO_ROOT}/backend"
        local requirements_file="${python_backend_dir}/requirements.txt"
        
        if [ -f "$requirements_file" ]; then
            scan_python_dependencies "$requirements_file"
            local scan_result=$?
            [ $scan_result -ne 0 ] && exit_code=1
        else
            log "WARNING" "Python requirements file not found: $requirements_file"
        fi
        
        if [ -d "$python_backend_dir" ]; then
            scan_python_code "$python_backend_dir"
            local scan_result=$?
            [ $scan_result -ne 0 ] && exit_code=1
        else
            log "WARNING" "Python source directory not found: $python_backend_dir"
        fi
    fi
    
    # Run container scan
    if [ "$do_container" -eq 1 ]; then
        scan_container_image "$container_image"
        local scan_result=$?
        [ $scan_result -ne 0 ] && exit_code=1
    fi
    
    # Run mobile scans
    if [ "$do_mobile" -eq 1 ]; then
        local ios_dir="${REPO_ROOT}/ios"
        local android_dir="${REPO_ROOT}/android"
        
        if [ -d "$ios_dir" ]; then
            scan_mobile_code "ios" "$ios_dir"
            local scan_result=$?
            [ $scan_result -ne 0 ] && exit_code=1
        else
            log "WARNING" "iOS source directory not found: $ios_dir"
        fi
        
        if [ -d "$android_dir" ]; then
            scan_mobile_code "android" "$android_dir"
            local scan_result=$?
            [ $scan_result -ne 0 ] && exit_code=1
        else
            log "WARNING" "Android source directory not found: $android_dir"
        fi
    fi
    
    # Run secrets scan
    if [ "$do_secrets" -eq 1 ]; then
        scan_secrets "$REPO_ROOT"
        local scan_result=$?
        [ $scan_result -ne 0 ] && exit_code=1
    fi
    
    # Generate consolidated report
    if [ "$do_report" -eq 1 ]; then
        generate_report
    fi
    
    # Check for critical vulnerabilities
    if [ "$do_critical" -eq 1 ]; then
        check_critical
        local scan_result=$?
        [ $scan_result -ne 0 ] && exit_code=1
    fi
    
    log "INFO" "Security scan completed at $(date)"
    
    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "All security scans completed successfully!"
    else
        log "ERROR" "Security issues were found. Please review the reports in: $OUTPUT_DIR"
    fi
    
    return $exit_code
}

# Run main function with command line arguments
main "$@"
exit $?