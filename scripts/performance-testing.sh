#!/bin/bash

# performance-testing.sh - Comprehensive performance testing for Amira Wellness
# 
# This script runs various performance tests including load tests, stress tests,
# and endurance tests against the Amira Wellness backend API and database to ensure
# the application meets performance requirements under different load conditions.

# Global variables
BACKEND_DIR="src/backend"
DOCKER_COMPOSE_FILE="infrastructure/docker/docker-compose.yml"
OUTPUT_DIR="performance-reports"
DEFAULT_USERS=50
DEFAULT_DURATION=60
DEFAULT_RAMP_UP=30
DEFAULT_ENDPOINT="/api/v1/health"
DEFAULT_TEST_TYPE="load"
DEFAULT_THRESHOLD_RESPONSE_TIME=500  # milliseconds
DEFAULT_THRESHOLD_ERROR_RATE=1       # percentage

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print usage information
function print_usage() {
  echo -e "${BOLD}Usage:${NC} $0 [options]"
  echo
  echo -e "${BOLD}Options:${NC}"
  echo "  -t, --test-type TYPE      Test type to run: load, stress, endurance, spike, api, db, voice, all"
  echo "                            Default: $DEFAULT_TEST_TYPE"
  echo "  -e, --endpoint URL        API endpoint to test"
  echo "                            Default: $DEFAULT_ENDPOINT"
  echo "  -u, --users NUM           Number of concurrent users"
  echo "                            Default: $DEFAULT_USERS"
  echo "  -d, --duration SECONDS    Test duration in seconds"
  echo "                            Default: $DEFAULT_DURATION"
  echo "  -r, --ramp-up SECONDS     Ramp-up period in seconds"
  echo "                            Default: $DEFAULT_RAMP_UP"
  echo "  -m, --max-users NUM       Maximum number of users for stress test"
  echo "  -s, --step-size NUM       User increment step size for stress test"
  echo "  -p, --step-duration SEC   Duration of each step in stress test"
  echo "  -b, --base-users NUM      Base number of users for spike test"
  echo "  -S, --spike-users NUM     Spike number of users for spike test"
  echo "  -F, --file-size NUM       File size in KB for voice upload test"
  echo "  -c, --connections NUM     Concurrent connections for DB test"
  echo "  --response-time NUM       Response time threshold in ms"
  echo "                            Default: $DEFAULT_THRESHOLD_RESPONSE_TIME"
  echo "  --error-rate NUM          Error rate threshold in percentage"
  echo "                            Default: $DEFAULT_THRESHOLD_ERROR_RATE"
  echo "  -k, --keep                Keep containers running after tests"
  echo "  -o, --output DIR          Output directory for test results"
  echo "                            Default: $OUTPUT_DIR"
  echo "  -h, --help                Display this help message"
  echo
  echo -e "${BOLD}Test Types:${NC}"
  echo "  load       - Load test with constant number of users"
  echo "  stress     - Stress test with increasing load to find breaking point"
  echo "  endurance  - Long-running test to verify system stability"
  echo "  spike      - Test system response to sudden traffic spikes"
  echo "  api        - Test performance of all critical API endpoints"
  echo "  db         - Test database performance under load"
  echo "  voice      - Test voice journal upload functionality"
  echo "  all        - Run all test types sequentially"
  echo
  echo -e "${BOLD}Examples:${NC}"
  echo "  # Run a basic load test with default parameters"
  echo "  $0 --test-type load"
  echo
  echo "  # Run a stress test with custom parameters"
  echo "  $0 -t stress -e /api/v1/journals -u 10 -m 200 -s 10 -p 30"
  echo
  echo "  # Run an endurance test for 30 minutes"
  echo "  $0 -t endurance -u 100 -d 1800"
  echo
}

# Check if required dependencies are installed
function check_dependencies() {
  local missing_deps=0
  
  echo -e "${BLUE}Checking dependencies...${NC}"
  
  # Check for common tools
  for cmd in docker docker-compose python pip jq; do
    if ! command -v $cmd &> /dev/null; then
      echo -e "${YELLOW}Warning: $cmd is not installed${NC}"
      missing_deps=$((missing_deps + 1))
    fi
  done
  
  # Check for performance testing tools
  if ! command -v k6 &> /dev/null; then
    echo -e "${YELLOW}Warning: k6 is not installed${NC}"
    echo -e "  Install instructions: https://k6.io/docs/getting-started/installation/"
    missing_deps=$((missing_deps + 1))
  fi
  
  if ! command -v ab &> /dev/null; then
    echo -e "${YELLOW}Warning: Apache Benchmark (ab) is not installed${NC}"
    echo -e "  Install with: sudo apt-get install apache2-utils"
    missing_deps=$((missing_deps + 1))
  fi
  
  if ! command -v wrk &> /dev/null; then
    echo -e "${YELLOW}Warning: wrk is not installed${NC}"
    echo -e "  Install instructions: https://github.com/wg/wrk/wiki/Installing-wrk"
    missing_deps=$((missing_deps + 1))
  fi
  
  # Critical dependencies check
  if ! command -v docker &> /dev/null || ! command -v k6 &> /dev/null; then
    echo -e "${RED}Error: Critical dependencies (docker, k6) are missing${NC}"
    return 1
  fi
  
  if [ $missing_deps -gt 0 ]; then
    echo -e "${YELLOW}Missing $missing_deps optional dependencies. Some tests may not run.${NC}"
  else
    echo -e "${GREEN}All dependencies are installed.${NC}"
  fi
  
  return 0
}

# Set up the testing environment with Docker containers
function setup_environment() {
  echo -e "${BLUE}Setting up testing environment...${NC}"
  
  # Check if Docker is running
  if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    return 1
  fi
  
  # Check if containers are already running
  if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
    echo -e "${GREEN}Containers are already running${NC}"
  else
    echo -e "Starting containers with docker-compose..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error: Failed to start containers${NC}"
      return 1
    fi
  fi
  
  # Wait for services to be healthy
  echo -e "Waiting for services to be ready..."
  for i in {1..30}; do
    if curl -s http://localhost:8000/api/v1/health | grep -q "ok"; then
      echo -e "${GREEN}Services are ready${NC}"
      break
    fi
    
    if [ $i -eq 30 ]; then
      echo -e "${RED}Error: Services did not become ready in time${NC}"
      return 1
    fi
    
    echo -n "."
    sleep 2
  done
  
  # Create test output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"
  
  return 0
}

# Clean up the testing environment
function teardown_environment() {
  local keep_containers=$1
  
  echo -e "${BLUE}Cleaning up testing environment...${NC}"
  
  if [ "$keep_containers" != "true" ]; then
    echo -e "Stopping and removing containers..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}Warning: Failed to stop containers${NC}"
    else
      echo -e "${GREEN}Containers stopped and removed${NC}"
    fi
  else
    echo -e "${YELLOW}Keeping containers running as requested${NC}"
  fi
  
  # Clean up any temporary files
  echo -e "Cleaning up temporary files..."
  find /tmp -name "amira-perf-test-*" -type f -mmin +60 -delete 2>/dev/null
  
  return 0
}

# Run a load test against the specified endpoint
function run_load_test() {
  local endpoint=$1
  local users=$2
  local duration=$3
  local ramp_up=$4
  local test_output_dir="$OUTPUT_DIR/load-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running load test against $endpoint with $users users for ${duration}s (${ramp_up}s ramp-up)...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Create k6 script file
  local k6_script=$(cat <<EOF
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '${ramp_up}s', target: ${users} }, // Ramp up
    { duration: '${duration}s', target: ${users} }, // Stay at target load
    { duration: '10s', target: 0 },       // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<${DEFAULT_THRESHOLD_RESPONSE_TIME}'], // 95% of requests should be below threshold
    errors: ['rate<${DEFAULT_THRESHOLD_ERROR_RATE/100}'],             // Error rate should be below threshold
  },
};

export default function() {
  const response = http.get('http://localhost:8000${endpoint}');
  
  // Check if response is successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If check fails, add to error rate
  errorRate.add(!success);
  
  // Random sleep between requests
  sleep(Math.random() * 3 + 1);
}
EOF
)

  # Write script to file
  local script_file="/tmp/amira-perf-test-load-$(date +%s).js"
  echo "$k6_script" > "$script_file"
  
  # Run k6 test
  k6 run --out json="$test_output_dir/raw_results.json" "$script_file" | tee "$test_output_dir/console_output.txt"
  local test_exit_code=${PIPESTATUS[0]}
  
  # Process results
  if [ -f "$test_output_dir/raw_results.json" ]; then
    # Extract key metrics using jq
    jq -r '.metrics' "$test_output_dir/raw_results.json" > "$test_output_dir/metrics.json"
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Load Test Summary" > "$summary_file"
    echo "================" >> "$summary_file"
    echo "Endpoint: $endpoint" >> "$summary_file"
    echo "Virtual Users: $users" >> "$summary_file"
    echo "Duration: $duration seconds" >> "$summary_file"
    echo "Ramp-up: $ramp_up seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    
    # Extract key metrics
    local http_req_duration_p95=$(jq -r '.http_req_duration.values."p(95)"' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs=$(jq -r '.http_reqs.values.count' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs_rate=$(jq -r '.http_reqs.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local error_rate=$(jq -r '.errors.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    
    # Format and add to summary
    echo "- Response Time (p95): $http_req_duration_p95 ms" >> "$summary_file"
    echo "- Total Requests: $http_reqs" >> "$summary_file"
    echo "- Request Rate: $http_reqs_rate req/s" >> "$summary_file"
    echo "- Error Rate: $(echo "$error_rate * 100" | bc -l | xargs printf "%.2f")%" >> "$summary_file"
    
    # Check against thresholds
    echo "" >> "$summary_file"
    echo "Thresholds:" >> "$summary_file"
    
    if (( $(echo "$http_req_duration_p95 < $DEFAULT_THRESHOLD_RESPONSE_TIME" | bc -l) )); then
      echo "- Response Time: PASS (${http_req_duration_p95}ms < ${DEFAULT_THRESHOLD_RESPONSE_TIME}ms)" >> "$summary_file"
    else
      echo "- Response Time: FAIL (${http_req_duration_p95}ms >= ${DEFAULT_THRESHOLD_RESPONSE_TIME}ms)" >> "$summary_file"
    fi
    
    local error_rate_percent=$(echo "$error_rate * 100" | bc -l)
    if (( $(echo "$error_rate_percent < $DEFAULT_THRESHOLD_ERROR_RATE" | bc -l) )); then
      echo "- Error Rate: PASS (${error_rate_percent}% < ${DEFAULT_THRESHOLD_ERROR_RATE}%)" >> "$summary_file"
    else
      echo "- Error Rate: FAIL (${error_rate_percent}% >= ${DEFAULT_THRESHOLD_ERROR_RATE}%)" >> "$summary_file"
    fi
    
    # Print summary to console
    echo -e "${BOLD}Test Results:${NC}"
    cat "$summary_file"
    
    # Create results file for validation
    echo "{\"p95_response_time\": $http_req_duration_p95, \"error_rate\": $error_rate_percent, \"requests_per_second\": $http_reqs_rate}" > "$test_output_dir/results.json"
  else
    echo -e "${RED}Error: No results file was generated${NC}"
    test_exit_code=1
  fi
  
  # Clean up script file
  rm -f "$script_file"
  
  echo -e "${BLUE}Load test completed. Results saved to: ${test_output_dir}${NC}"
  return $test_exit_code
}

# Run a stress test to find the breaking point of the system
function run_stress_test() {
  local endpoint=$1
  local start_users=$2
  local max_users=$3
  local step_size=$4
  local step_duration=$5
  local test_output_dir="$OUTPUT_DIR/stress-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running stress test against $endpoint from $start_users to $max_users users...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Calculate total duration and create stages array for k6
  local total_steps=$(( (max_users - start_users) / step_size ))
  local total_duration=$(( total_steps * step_duration ))
  
  # Create k6 script file with ramping users
  local k6_script=$(cat <<EOF
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: ${start_users} }, // Initial ramp-up
EOF
)

  # Add stages for each step
  local current_users=$start_users
  while (( current_users < max_users )); do
    current_users=$((current_users + step_size))
    k6_script+="    { duration: '${step_duration}s', target: ${current_users} },\n"
  done

  # Add final stage to keep at max users and ramp down
  k6_script+=$(cat <<EOF
    { duration: '60s', target: ${max_users} }, // Stay at max users
    { duration: '30s', target: 0 },           // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<${DEFAULT_THRESHOLD_RESPONSE_TIME}'], // 95% of requests should be below threshold
    errors: ['rate<${DEFAULT_THRESHOLD_ERROR_RATE/100}'],             // Error rate should be below threshold
  },
};

export default function() {
  const response = http.get('http://localhost:8000${endpoint}');
  
  // Check if response is successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If check fails, add to error rate
  errorRate.add(!success);
  
  // Random sleep between requests
  sleep(Math.random() * 2 + 0.5);
}
EOF
)

  # Write script to file
  local script_file="/tmp/amira-perf-test-stress-$(date +%s).js"
  echo -e "$k6_script" > "$script_file"
  
  # Run k6 test
  k6 run --out json="$test_output_dir/raw_results.json" "$script_file" | tee "$test_output_dir/console_output.txt"
  local test_exit_code=${PIPESTATUS[0]}
  
  # Process results
  if [ -f "$test_output_dir/raw_results.json" ]; then
    # Extract key metrics using jq
    jq -r '.metrics' "$test_output_dir/raw_results.json" > "$test_output_dir/metrics.json"
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Stress Test Summary" > "$summary_file"
    echo "===================" >> "$summary_file"
    echo "Endpoint: $endpoint" >> "$summary_file"
    echo "Start Users: $start_users" >> "$summary_file"
    echo "Max Users: $max_users" >> "$summary_file"
    echo "Step Size: $step_size users" >> "$summary_file"
    echo "Step Duration: $step_duration seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Analyze to find breaking point
    # For this we would need to parse the detailed metrics over time
    # This is a simplified version that just looks at the final results
    
    local http_req_duration_p95=$(jq -r '.http_req_duration.values."p(95)"' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs=$(jq -r '.http_reqs.values.count' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs_rate=$(jq -r '.http_reqs.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local error_rate=$(jq -r '.errors.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    
    # Try to determine breaking point from error rate
    # Note: In a real script, we would do more sophisticated analysis
    local breaking_point="Not detected"
    if (( $(echo "$error_rate > ${DEFAULT_THRESHOLD_ERROR_RATE}/100" | bc -l) )); then
      breaking_point="The system showed signs of stress, but exact breaking point requires detailed analysis."
    else
      breaking_point="The system handled the load up to $max_users users without exceeding error thresholds."
    fi
    
    echo "Breaking Point Analysis:" >> "$summary_file"
    echo "$breaking_point" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    echo "- Response Time (p95): $http_req_duration_p95 ms" >> "$summary_file"
    echo "- Total Requests: $http_reqs" >> "$summary_file"
    echo "- Request Rate: $http_reqs_rate req/s" >> "$summary_file"
    echo "- Error Rate: $(echo "$error_rate * 100" | bc -l | xargs printf "%.2f")%" >> "$summary_file"
    
    # Print summary to console
    echo -e "${BOLD}Test Results:${NC}"
    cat "$summary_file"
    
    # Create results file for validation
    echo "{\"p95_response_time\": $http_req_duration_p95, \"error_rate\": $(echo "$error_rate * 100" | bc -l), \"requests_per_second\": $http_reqs_rate, \"breaking_point\": \"$breaking_point\"}" > "$test_output_dir/results.json"
  else
    echo -e "${RED}Error: No results file was generated${NC}"
    test_exit_code=1
  fi
  
  # Clean up script file
  rm -f "$script_file"
  
  echo -e "${BLUE}Stress test completed. Results saved to: ${test_output_dir}${NC}"
  return $test_exit_code
}

# Run an endurance test to verify system stability over time
function run_endurance_test() {
  local endpoint=$1
  local users=$2
  local duration=$3
  local test_output_dir="$OUTPUT_DIR/endurance-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running endurance test against $endpoint with $users users for ${duration}s...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Create k6 script file
  local k6_script=$(cat <<EOF
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '60s', target: ${users} },     // Ramp up
    { duration: '${duration}s', target: ${users} }, // Stay at target load for extended period
    { duration: '30s', target: 0 },           // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<${DEFAULT_THRESHOLD_RESPONSE_TIME}'], // 95% of requests should be below threshold
    errors: ['rate<${DEFAULT_THRESHOLD_ERROR_RATE/100}'],             // Error rate should be below threshold
  },
};

export default function() {
  const response = http.get('http://localhost:8000${endpoint}');
  
  // Check if response is successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If check fails, add to error rate
  errorRate.add(!success);
  
  // Relatively consistent load
  sleep(1 + Math.random());
}
EOF
)

  # Write script to file
  local script_file="/tmp/amira-perf-test-endurance-$(date +%s).js"
  echo "$k6_script" > "$script_file"
  
  # Run k6 test
  k6 run --out json="$test_output_dir/raw_results.json" "$script_file" | tee "$test_output_dir/console_output.txt"
  local test_exit_code=${PIPESTATUS[0]}
  
  # Process results
  if [ -f "$test_output_dir/raw_results.json" ]; then
    # Extract key metrics using jq
    jq -r '.metrics' "$test_output_dir/raw_results.json" > "$test_output_dir/metrics.json"
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Endurance Test Summary" > "$summary_file"
    echo "======================" >> "$summary_file"
    echo "Endpoint: $endpoint" >> "$summary_file"
    echo "Virtual Users: $users" >> "$summary_file"
    echo "Duration: $duration seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    
    # Extract key metrics
    local http_req_duration_p95=$(jq -r '.http_req_duration.values."p(95)"' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_req_duration_max=$(jq -r '.http_req_duration.values.max' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs=$(jq -r '.http_reqs.values.count' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs_rate=$(jq -r '.http_reqs.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local error_rate=$(jq -r '.errors.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    
    # Format and add to summary
    echo "- Response Time (p95): $http_req_duration_p95 ms" >> "$summary_file"
    echo "- Response Time (max): $http_req_duration_max ms" >> "$summary_file"
    echo "- Total Requests: $http_reqs" >> "$summary_file"
    echo "- Request Rate: $http_reqs_rate req/s" >> "$summary_file"
    echo "- Error Rate: $(echo "$error_rate * 100" | bc -l | xargs printf "%.2f")%" >> "$summary_file"
    
    # Add stability analysis
    echo "" >> "$summary_file"
    echo "Stability Analysis:" >> "$summary_file"
    
    # Check for significant degradation (simplified analysis)
    if (( $(echo "$http_req_duration_max > $http_req_duration_p95 * 3" | bc -l) )); then
      echo "- Performance spikes detected (max response time is more than 3x p95)" >> "$summary_file"
      echo "- This may indicate stability issues during prolonged use" >> "$summary_file"
    else
      echo "- Performance remained stable throughout the test" >> "$summary_file"
      echo "- No significant degradation observed over time" >> "$summary_file"
    fi
    
    # Print summary to console
    echo -e "${BOLD}Test Results:${NC}"
    cat "$summary_file"
    
    # Create results file for validation
    echo "{\"p95_response_time\": $http_req_duration_p95, \"max_response_time\": $http_req_duration_max, \"error_rate\": $(echo "$error_rate * 100" | bc -l), \"requests_per_second\": $http_reqs_rate}" > "$test_output_dir/results.json"
  else
    echo -e "${RED}Error: No results file was generated${NC}"
    test_exit_code=1
  fi
  
  # Clean up script file
  rm -f "$script_file"
  
  echo -e "${BLUE}Endurance test completed. Results saved to: ${test_output_dir}${NC}"
  return $test_exit_code
}

# Run a spike test to verify system response to sudden traffic spikes
function run_spike_test() {
  local endpoint=$1
  local base_users=$2
  local spike_users=$3
  local duration=$4
  local test_output_dir="$OUTPUT_DIR/spike-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running spike test against $endpoint from $base_users to $spike_users users...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Create k6 script file
  local k6_script=$(cat <<EOF
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: ${base_users} },   // Baseline
    { duration: '10s', target: ${spike_users} },  // Spike
    { duration: '${duration}s', target: ${spike_users} }, // Hold spike
    { duration: '30s', target: ${base_users} },   // Recovery
    { duration: '60s', target: ${base_users} },   // Verify stability after spike
    { duration: '10s', target: 0 },              // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<${DEFAULT_THRESHOLD_RESPONSE_TIME}'], // 95% of requests should be below threshold
    errors: ['rate<${DEFAULT_THRESHOLD_ERROR_RATE/100}'],             // Error rate should be below threshold
  },
};

export default function() {
  const start = new Date();
  const response = http.get('http://localhost:8000${endpoint}');
  const end = new Date();
  const responseTime = end - start;
  
  // Check if response is successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If check fails, add to error rate
  errorRate.add(!success);
  
  // Minimal sleep to maximize load during spike
  sleep(0.1);
}
EOF
)

  # Write script to file
  local script_file="/tmp/amira-perf-test-spike-$(date +%s).js"
  echo "$k6_script" > "$script_file"
  
  # Run k6 test
  k6 run --out json="$test_output_dir/raw_results.json" "$script_file" | tee "$test_output_dir/console_output.txt"
  local test_exit_code=${PIPESTATUS[0]}
  
  # Process results
  if [ -f "$test_output_dir/raw_results.json" ]; then
    # Extract key metrics using jq
    jq -r '.metrics' "$test_output_dir/raw_results.json" > "$test_output_dir/metrics.json"
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Spike Test Summary" > "$summary_file"
    echo "=================" >> "$summary_file"
    echo "Endpoint: $endpoint" >> "$summary_file"
    echo "Base Users: $base_users" >> "$summary_file"
    echo "Spike Users: $spike_users" >> "$summary_file"
    echo "Spike Duration: $duration seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    
    # Extract key metrics
    local http_req_duration_p95=$(jq -r '.http_req_duration.values."p(95)"' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_req_duration_max=$(jq -r '.http_req_duration.values.max' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs=$(jq -r '.http_reqs.values.count' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs_rate=$(jq -r '.http_reqs.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local error_rate=$(jq -r '.errors.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    
    # Format and add to summary
    echo "- Response Time (p95): $http_req_duration_p95 ms" >> "$summary_file"
    echo "- Response Time (max): $http_req_duration_max ms" >> "$summary_file"
    echo "- Total Requests: $http_reqs" >> "$summary_file"
    echo "- Request Rate: $http_reqs_rate req/s" >> "$summary_file"
    echo "- Error Rate: $(echo "$error_rate * 100" | bc -l | xargs printf "%.2f")%" >> "$summary_file"
    
    # Add spike analysis
    echo "" >> "$summary_file"
    echo "Spike Response Analysis:" >> "$summary_file"
    
    # Check for high error rates during spike
    local error_rate_percent=$(echo "$error_rate * 100" | bc -l)
    if (( $(echo "$error_rate_percent > $DEFAULT_THRESHOLD_ERROR_RATE" | bc -l) )); then
      echo "- System showed elevated error rates during spike" >> "$summary_file"
      echo "- This indicates potential stability issues under sudden load increases" >> "$summary_file"
    else
      echo "- System handled the traffic spike without significant errors" >> "$summary_file"
    fi
    
    # Check response time
    if (( $(echo "$http_req_duration_max > $DEFAULT_THRESHOLD_RESPONSE_TIME * 2" | bc -l) )); then
      echo "- Maximum response time significantly exceeded threshold during spike" >> "$summary_file"
      echo "- This indicates performance degradation under sudden load" >> "$summary_file"
    else
      echo "- Response times remained within acceptable limits during spike" >> "$summary_file"
    fi
    
    # Print summary to console
    echo -e "${BOLD}Test Results:${NC}"
    cat "$summary_file"
    
    # Create results file for validation
    echo "{\"p95_response_time\": $http_req_duration_p95, \"max_response_time\": $http_req_duration_max, \"error_rate\": $error_rate_percent, \"requests_per_second\": $http_reqs_rate}" > "$test_output_dir/results.json"
  else
    echo -e "${RED}Error: No results file was generated${NC}"
    test_exit_code=1
  fi
  
  # Clean up script file
  rm -f "$script_file"
  
  echo -e "${BLUE}Spike test completed. Results saved to: ${test_output_dir}${NC}"
  return $test_exit_code
}

# Run performance tests against specific API endpoints
function run_api_endpoint_test() {
  local test_type=$1
  local users=$2
  local duration=$3
  local test_output_dir="$OUTPUT_DIR/api-endpoint-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running $test_type tests against critical API endpoints with $users users for ${duration}s...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Define critical API endpoints to test
  local endpoints=(
    "/api/v1/health"
    "/api/v1/auth/login"
    "/api/v1/journals"
    "/api/v1/emotions/check-in"
    "/api/v1/tools"
    "/api/v1/progress"
  )
  
  # Create summary file
  local summary_file="$test_output_dir/summary.txt"
  echo "API Endpoint Test Summary ($test_type)" > "$summary_file"
  echo "=================================" >> "$summary_file"
  echo "Users: $users" >> "$summary_file"
  echo "Duration: $duration seconds" >> "$summary_file"
  echo "" >> "$summary_file"
  echo "Results by Endpoint:" >> "$summary_file"
  
  # Results array for comparison
  local results_json="{"
  
  # Run tests for each endpoint
  local overall_exit_code=0
  for endpoint in "${endpoints[@]}"; do
    echo -e "\n${BLUE}Testing endpoint: $endpoint${NC}"
    
    # Run appropriate test type
    local endpoint_result_dir="$test_output_dir$(echo $endpoint | tr '/' '_')"
    local exit_code=0
    
    case "$test_type" in
      load)
        run_load_test "$endpoint" "$users" "$duration" "30"
        exit_code=$?
        ;;
      stress)
        run_stress_test "$endpoint" "$(($users / 5))" "$users" "$(($users / 10))" "30"
        exit_code=$?
        ;;
      endurance)
        run_endurance_test "$endpoint" "$users" "$duration"
        exit_code=$?
        ;;
      spike)
        run_spike_test "$endpoint" "$(($users / 5))" "$users" "30"
        exit_code=$?
        ;;
      *)
        echo -e "${RED}Error: Unknown test type $test_type${NC}"
        return 1
        ;;
    esac
    
    if [ $exit_code -ne 0 ]; then
      overall_exit_code=$exit_code
    fi
    
    # Get the latest results file
    local latest_result=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
    
    if [ -f "$latest_result" ]; then
      # Extract the endpoint name from path
      local endpoint_name=$(echo $endpoint | cut -d'/' -f3- | tr '/' '_')
      
      # Extract key metrics
      local p95_response_time=$(jq -r '.p95_response_time' "$latest_result")
      local error_rate=$(jq -r '.error_rate' "$latest_result")
      local requests_per_second=$(jq -r '.requests_per_second' "$latest_result")
      
      # Add to summary
      echo "" >> "$summary_file"
      echo "Endpoint: $endpoint" >> "$summary_file"
      echo "- Response Time (p95): $p95_response_time ms" >> "$summary_file"
      echo "- Error Rate: $error_rate%" >> "$summary_file"
      echo "- Request Rate: $requests_per_second req/s" >> "$summary_file"
      
      # Add to results JSON
      results_json+="\"$endpoint_name\": {\"p95_response_time\": $p95_response_time, \"error_rate\": $error_rate, \"requests_per_second\": $requests_per_second},"
    else
      echo -e "${YELLOW}Warning: No results file found for $endpoint${NC}"
      echo "" >> "$summary_file"
      echo "Endpoint: $endpoint" >> "$summary_file"
      echo "- No results available" >> "$summary_file"
      
      # Add null entry in results JSON
      results_json+="\"$endpoint_name\": null,"
    fi
  done
  
  # Finalize results JSON
  results_json=${results_json%,}  # Remove trailing comma
  results_json+="}"
  
  # Save results JSON
  echo "$results_json" > "$test_output_dir/results.json"
  
  # Add comparative analysis to summary
  echo "" >> "$summary_file"
  echo "Comparative Analysis:" >> "$summary_file"
  
  # Find slowest and fastest endpoints
  local slowest_endpoint=$(jq -r 'to_entries | map(select(.value != null)) | sort_by(.value.p95_response_time) | reverse | .[0].key' "$test_output_dir/results.json" 2>/dev/null)
  local fastest_endpoint=$(jq -r 'to_entries | map(select(.value != null)) | sort_by(.value.p95_response_time) | .[0].key' "$test_output_dir/results.json" 2>/dev/null)
  
  # Find highest and lowest error rates
  local highest_error_endpoint=$(jq -r 'to_entries | map(select(.value != null)) | sort_by(.value.error_rate) | reverse | .[0].key' "$test_output_dir/results.json" 2>/dev/null)
  local lowest_error_endpoint=$(jq -r 'to_entries | map(select(.value != null)) | sort_by(.value.error_rate) | .[0].key' "$test_output_dir/results.json" 2>/dev/null)
  
  if [ "$slowest_endpoint" != "null" ] && [ "$fastest_endpoint" != "null" ]; then
    local slowest_time=$(jq -r ".[\"$slowest_endpoint\"].p95_response_time" "$test_output_dir/results.json")
    local fastest_time=$(jq -r ".[\"$fastest_endpoint\"].p95_response_time" "$test_output_dir/results.json")
    
    echo "- Slowest endpoint: /$slowest_endpoint ($slowest_time ms)" >> "$summary_file"
    echo "- Fastest endpoint: /$fastest_endpoint ($fastest_time ms)" >> "$summary_file"
  fi
  
  if [ "$highest_error_endpoint" != "null" ] && [ "$lowest_error_endpoint" != "null" ]; then
    local highest_error=$(jq -r ".[\"$highest_error_endpoint\"].error_rate" "$test_output_dir/results.json")
    local lowest_error=$(jq -r ".[\"$lowest_error_endpoint\"].error_rate" "$test_output_dir/results.json")
    
    echo "- Highest error rate: /$highest_error_endpoint ($highest_error%)" >> "$summary_file"
    echo "- Lowest error rate: /$lowest_error_endpoint ($lowest_error%)" >> "$summary_file"
  fi
  
  # Print summary to console
  echo -e "${BOLD}API Endpoint Test Results:${NC}"
  cat "$summary_file"
  
  echo -e "${BLUE}API endpoint tests completed. Results saved to: ${test_output_dir}${NC}"
  return $overall_exit_code
}

# Test database performance under load
function run_database_performance_test() {
  local concurrent_connections=$1
  local duration=$2
  local test_output_dir="$OUTPUT_DIR/database-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running database performance test with $concurrent_connections concurrent connections for ${duration}s...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Check if pgbench is available
  if ! command -v pgbench &> /dev/null; then
    echo -e "${YELLOW}Warning: pgbench is not installed. Using alternative approach.${NC}"
    
    # Use a custom approach with the existing database container
    echo "Creating custom database test script..."
    
    # Create a simple SQL test script
    local sql_script=$(cat <<EOF
-- Simple read query
SELECT * FROM users LIMIT 100;
-- Simple write query
INSERT INTO test_performance (test_key, test_value, created_at) 
VALUES ('test', 'value', NOW()) 
ON CONFLICT (test_key) 
DO UPDATE SET test_value = 'updated', updated_at = NOW();
-- Complex query
SELECT 
  u.id, 
  COUNT(j.id) as journal_count, 
  AVG(j.duration_seconds) as avg_duration
FROM 
  users u
LEFT JOIN 
  voice_journals j ON u.id = j.user_id
GROUP BY 
  u.id
ORDER BY 
  journal_count DESC
LIMIT 50;
EOF
)

    # Write script to file
    local sql_file="/tmp/amira-perf-test-db-$(date +%s).sql"
    echo "$sql_script" > "$sql_file"
    
    # Create a test table if it doesn't exist
    echo "Creating test table if it doesn't exist..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db psql -U postgres -d amira -c "
      CREATE TABLE IF NOT EXISTS test_performance (
        test_key VARCHAR(50) PRIMARY KEY,
        test_value TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP
      );
    "
    
    # Run the test using a simple bash script
    echo "Running database test..."
    
    # Start time
    local start_time=$(date +%s)
    
    # Run queries in parallel
    local successful_queries=0
    local failed_queries=0
    local total_time=0
    local max_time=0
    
    # Create a temporary file to store results
    local results_file="/tmp/amira-perf-test-db-results-$(date +%s).txt"
    touch "$results_file"
    
    # Run queries in parallel using background processes
    for ((i=0; i<$concurrent_connections; i++)); do
      (
        for ((j=0; j<$duration/2; j++)); do  # Divide by 2 to adjust for query execution time
          query_start=$(date +%s.%N)
          if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db psql -U postgres -d amira -f "$sql_file" > /dev/null 2>&1; then
            query_end=$(date +%s.%N)
            query_time=$(echo "$query_end - $query_start" | bc)
            echo "SUCCESS $query_time" >> "$results_file"
          else
            echo "FAIL" >> "$results_file"
          fi
          sleep 0.1  # Small pause between queries
        done
      ) &
    done
    
    # Wait for all background processes to finish
    wait
    
    # End time
    local end_time=$(date +%s)
    local total_test_time=$((end_time - start_time))
    
    # Process results
    successful_queries=$(grep "SUCCESS" "$results_file" | wc -l)
    failed_queries=$(grep "FAIL" "$results_file" | wc -l)
    
    # Calculate timings
    if [ $successful_queries -gt 0 ]; then
      total_time=$(grep "SUCCESS" "$results_file" | awk '{sum+=$2} END {print sum}')
      max_time=$(grep "SUCCESS" "$results_file" | awk '{if ($2>max) max=$2} END {print max}')
      avg_time=$(echo "scale=3; $total_time / $successful_queries" | bc)
    else
      avg_time="N/A"
      max_time="N/A"
    fi
    
    # Calculate queries per second
    local qps=0
    if [ $total_test_time -gt 0 ]; then
      qps=$(echo "scale=2; ($successful_queries + $failed_queries) / $total_test_time" | bc)
    fi
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Database Performance Test Summary" > "$summary_file"
    echo "================================" >> "$summary_file"
    echo "Concurrent connections: $concurrent_connections" >> "$summary_file"
    echo "Test duration: $total_test_time seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    echo "- Successful queries: $successful_queries" >> "$summary_file"
    echo "- Failed queries: $failed_queries" >> "$summary_file"
    echo "- Queries per second: $qps" >> "$summary_file"
    echo "- Average query time: $avg_time seconds" >> "$summary_file"
    echo "- Maximum query time: $max_time seconds" >> "$summary_file"
    
    # Create JSON results
    echo "{\"successful_queries\": $successful_queries, \"failed_queries\": $failed_queries, \"queries_per_second\": $qps, \"avg_query_time\": $avg_time, \"max_query_time\": $max_time}" > "$test_output_dir/results.json"
    
    # Clean up
    rm -f "$sql_file" "$results_file"
  else
    # Use pgbench for more accurate testing
    echo "Using pgbench for database testing..."
    
    # Create pgbench tables (may need to adjust based on your specific database setup)
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db pgbench -U postgres -d amira -i
    
    # Run pgbench test
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db pgbench -U postgres -d amira -c "$concurrent_connections" -T "$duration" -r > "$test_output_dir/pgbench_output.txt"
    
    # Process results
    if [ -f "$test_output_dir/pgbench_output.txt" ]; then
      # Extract key metrics
      local tps=$(grep "tps" "$test_output_dir/pgbench_output.txt" | awk '{print $3}')
      local latency=$(grep "latency" "$test_output_dir/pgbench_output.txt" | awk '{print $4}')
      
      # Generate summary
      local summary_file="$test_output_dir/summary.txt"
      echo "Database Performance Test Summary (pgbench)" > "$summary_file"
      echo "=========================================" >> "$summary_file"
      echo "Concurrent connections: $concurrent_connections" >> "$summary_file"
      echo "Test duration: $duration seconds" >> "$summary_file"
      echo "" >> "$summary_file"
      echo "Results:" >> "$summary_file"
      echo "- Transactions per second: $tps" >> "$summary_file"
      echo "- Average latency: $latency ms" >> "$summary_file"
      
      # Create JSON results
      echo "{\"transactions_per_second\": $tps, \"avg_latency\": $latency}" > "$test_output_dir/results.json"
    else
      echo -e "${RED}Error: pgbench output file not found${NC}"
      return 1
    fi
  fi
  
  # Print summary to console
  echo -e "${BOLD}Database Test Results:${NC}"
  cat "$summary_file"
  
  echo -e "${BLUE}Database performance test completed. Results saved to: ${test_output_dir}${NC}"
  return 0
}

# Test performance of voice journal upload functionality
function run_voice_journal_upload_test() {
  local concurrent_uploads=$1
  local file_size_kb=$2
  local duration=$3
  local test_output_dir="$OUTPUT_DIR/voice-upload-test-$(date +%Y%m%d-%H%M%S)"
  
  echo -e "${BLUE}Running voice journal upload test with $concurrent_uploads concurrent uploads of ${file_size_kb}KB files for ${duration}s...${NC}"
  
  # Create output directory
  mkdir -p "$test_output_dir"
  
  # Create test audio file
  echo "Creating test audio file of $file_size_kb KB..."
  local test_file="/tmp/amira-perf-test-audio-$(date +%s).mp3"
  dd if=/dev/urandom of="$test_file" bs=1024 count="$file_size_kb" 2> /dev/null
  
  # Get authentication token (simplified, would need to be adjusted to your auth system)
  echo "Getting authentication token..."
  local auth_token="test-token"
  
  # Try to get a real token if possible
  if curl -s -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"password123"}' http://localhost:8000/api/v1/auth/login > /dev/null 2>&1; then
    auth_token=$(curl -s -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"password123"}' http://localhost:8000/api/v1/auth/login | jq -r '.token' 2>/dev/null || echo "test-token")
  fi
  
  # Create k6 script for upload test
  local k6_script=$(cat <<EOF
import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const uploadSpeed = new Rate('upload_speed');

// Load audio file
const audioFile = open('${test_file}', 'b');

// Set up test data
const endpoint = 'http://localhost:8000/api/v1/journals';
const authToken = '${auth_token}';

export const options = {
  stages: [
    { duration: '10s', target: ${concurrent_uploads} }, // Ramp up
    { duration: '${duration}s', target: ${concurrent_uploads} }, // Steady state
    { duration: '5s', target: 0 }, // Ramp down
  ],
  thresholds: {
    errors: ['rate<${DEFAULT_THRESHOLD_ERROR_RATE/100}'],
  },
};

export default function() {
  // Prepare FormData with audio file
  const data = {
    file: http.file(audioFile, 'test-audio.mp3', 'audio/mpeg'),
    pre_emotional_state: JSON.stringify({
      primary_emotion: 'CALM',
      intensity: 7
    }),
    post_emotional_state: JSON.stringify({
      primary_emotion: 'JOY',
      intensity: 8
    }),
    duration_seconds: 30,
    title: 'Performance Test Journal'
  };
  
  const headers = {
    'Authorization': \`Bearer \${authToken}\`
  };
  
  const start = new Date();
  const response = http.post(endpoint, data, { headers: headers });
  const end = new Date();
  const uploadTime = (end - start) / 1000; // in seconds
  const fileSize = ${file_size_kb}; // in KB
  const uploadSpeedKBps = fileSize / uploadTime;
  
  // Record upload speed
  uploadSpeed.add(uploadSpeedKBps);
  
  // Check if response is successful
  const success = check(response, {
    'status is 200 or 201': (r) => r.status === 200 || r.status === 201,
  });
  
  // If check fails, add to error rate
  errorRate.add(!success);
  
  // Pause between uploads
  sleep(1);
}
EOF
)

  # Write script to file
  local script_file="/tmp/amira-perf-test-upload-$(date +%s).js"
  echo "$k6_script" > "$script_file"
  
  # Run k6 test
  k6 run --out json="$test_output_dir/raw_results.json" "$script_file" | tee "$test_output_dir/console_output.txt"
  local test_exit_code=${PIPESTATUS[0]}
  
  # Process results
  if [ -f "$test_output_dir/raw_results.json" ]; then
    # Extract key metrics using jq
    jq -r '.metrics' "$test_output_dir/raw_results.json" > "$test_output_dir/metrics.json"
    
    # Generate summary
    local summary_file="$test_output_dir/summary.txt"
    echo "Voice Journal Upload Test Summary" > "$summary_file"
    echo "================================" >> "$summary_file"
    echo "Concurrent uploads: $concurrent_uploads" >> "$summary_file"
    echo "File size: $file_size_kb KB" >> "$summary_file"
    echo "Test duration: $duration seconds" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Results:" >> "$summary_file"
    
    # Extract key metrics
    local http_req_duration_p95=$(jq -r '.http_req_duration.values."p(95)"' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local http_reqs=$(jq -r '.http_reqs.values.count' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local error_rate=$(jq -r '.errors.values.rate' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    local upload_speed_avg=$(jq -r '.upload_speed.values.avg' "$test_output_dir/metrics.json" 2>/dev/null || echo "N/A")
    
    # Format and add to summary
    echo "- Upload time (p95): $http_req_duration_p95 ms" >> "$summary_file"
    echo "- Total uploads: $http_reqs" >> "$summary_file"
    echo "- Error rate: $(echo "$error_rate * 100" | bc -l | xargs printf "%.2f")%" >> "$summary_file"
    echo "- Average upload speed: $upload_speed_avg KB/s" >> "$summary_file"
    
    # Calculate theoretical maximum uploads
    local theoretical_max=$(echo "scale=2; $duration * $concurrent_uploads / ($http_req_duration_p95 / 1000)" | bc)
    echo "- Theoretical maximum uploads: $theoretical_max" >> "$summary_file"
    
    # Calculate efficiency
    local efficiency=$(echo "scale=2; $http_reqs / $theoretical_max * 100" | bc)
    echo "- Upload efficiency: $efficiency%" >> "$summary_file"
    
    # Create results file for validation
    echo "{\"p95_upload_time\": $http_req_duration_p95, \"error_rate\": $(echo "$error_rate * 100" | bc -l), \"upload_speed\": $upload_speed_avg, \"theoretical_max\": $theoretical_max, \"efficiency\": $efficiency}" > "$test_output_dir/results.json"
  else
    echo -e "${RED}Error: No results file was generated${NC}"
    test_exit_code=1
  fi
  
  # Clean up files
  rm -f "$test_file" "$script_file"
  
  # Print summary to console
  echo -e "${BOLD}Voice Journal Upload Test Results:${NC}"
  cat "$summary_file"
  
  echo -e "${BLUE}Voice journal upload test completed. Results saved to: ${test_output_dir}${NC}"
  return $test_exit_code
}

# Generate a consolidated performance report
function generate_report() {
  local report_file="$OUTPUT_DIR/consolidated-report-$(date +%Y%m%d-%H%M%S).html"
  
  echo -e "${BLUE}Generating consolidated performance report...${NC}"
  
  # Create HTML header
  cat > "$report_file" <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Amira Wellness - Performance Test Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      color: #333;
    }
    h1, h2, h3 {
      color: #2c3e50;
    }
    .section {
      margin-bottom: 30px;
      border: 1px solid #ddd;
      padding: 20px;
      border-radius: 5px;
    }
    .test-summary {
      margin-bottom: 15px;
      padding: 10px;
      background-color: #f8f9fa;
      border-left: 4px solid #007bff;
    }
    .pass {
      color: #28a745;
    }
    .fail {
      color: #dc3545;
    }
    .warning {
      color: #ffc107;
    }
    table {
      border-collapse: collapse;
      width: 100%;
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
  <h1>Amira Wellness - Performance Test Report</h1>
  <p><strong>Generated:</strong> $(date)</p>
  
  <div class="section">
    <h2>Executive Summary</h2>
    <p>This report summarizes the performance test results for the Amira Wellness application.</p>
EOF

  # Count total tests and failures
  local total_tests=$(find "$OUTPUT_DIR" -name "results.json" | wc -l)
  local passed_tests=$(find "$OUTPUT_DIR" -name "results.json" -exec grep -l "\"error_rate\": [0-9.]*" {} \; | xargs grep -l "\"p95_response_time\": [0-9.]*" | xargs cat | grep -v "\"error_rate\": [${DEFAULT_THRESHOLD_ERROR_RATE}.]" | grep -v "\"p95_response_time\": [${DEFAULT_THRESHOLD_RESPONSE_TIME}.]" | wc -l)
  local failed_tests=$((total_tests - passed_tests))
  
  # Add test summary to executive summary
  cat >> "$report_file" <<EOF
    <p><strong>Total Tests:</strong> $total_tests</p>
    <p><strong>Passed Tests:</strong> <span class="pass">$passed_tests</span></p>
    <p><strong>Failed Tests:</strong> <span class="fail">$failed_tests</span></p>
EOF

  # If we have failures, add a summary of failing tests
  if [ $failed_tests -gt 0 ]; then
    cat >> "$report_file" <<EOF
    <h3>Failed Tests</h3>
    <table>
      <tr>
        <th>Test Type</th>
        <th>Metric</th>
        <th>Threshold</th>
        <th>Actual</th>
      </tr>
EOF

    # Find and add failed tests
    for results_file in $(find "$OUTPUT_DIR" -name "results.json"); do
      # Get the test type from the parent directory
      local test_type=$(basename $(dirname "$results_file") | cut -d'-' -f1,2)
      
      # Check for response time failures
      local p95_response_time=$(jq -r '.p95_response_time // 0' "$results_file" 2>/dev/null)
      if (( $(echo "$p95_response_time > $DEFAULT_THRESHOLD_RESPONSE_TIME" | bc -l) )); then
        cat >> "$report_file" <<EOF
      <tr>
        <td>$test_type</td>
        <td>Response Time (p95)</td>
        <td>${DEFAULT_THRESHOLD_RESPONSE_TIME} ms</td>
        <td class="fail">$p95_response_time ms</td>
      </tr>
EOF
      fi
      
      # Check for error rate failures
      local error_rate=$(jq -r '.error_rate // 0' "$results_file" 2>/dev/null)
      if (( $(echo "$error_rate > $DEFAULT_THRESHOLD_ERROR_RATE" | bc -l) )); then
        cat >> "$report_file" <<EOF
      <tr>
        <td>$test_type</td>
        <td>Error Rate</td>
        <td>${DEFAULT_THRESHOLD_ERROR_RATE}%</td>
        <td class="fail">$error_rate%</td>
      </tr>
EOF
      fi
    done
    
    cat >> "$report_file" <<EOF
    </table>
EOF
  fi

  # Close executive summary section
  cat >> "$report_file" <<EOF
  </div>
EOF

  # Add detailed sections for each test type
  for test_type in "load-test" "stress-test" "endurance-test" "spike-test" "api-endpoint-test" "database-test" "voice-upload-test"; do
    # Find the latest test of this type
    local latest_dir=$(find "$OUTPUT_DIR" -name "${test_type}-*" -type d | sort | tail -n1)
    
    if [ -n "$latest_dir" ]; then
      # Extract test name
      local test_name=$(echo "$test_type" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
      
      cat >> "$report_file" <<EOF
  <div class="section">
    <h2>$test_name Results</h2>
EOF

      # Add summary if available
      if [ -f "$latest_dir/summary.txt" ]; then
        cat >> "$report_file" <<EOF
    <div class="test-summary">
      <pre>$(cat "$latest_dir/summary.txt")</pre>
    </div>
EOF
      fi

      # Add results table if available
      if [ -f "$latest_dir/results.json" ]; then
        cat >> "$report_file" <<EOF
    <h3>Key Metrics</h3>
    <table>
      <tr>
        <th>Metric</th>
        <th>Value</th>
        <th>Status</th>
      </tr>
EOF

        # Add response time
        local p95_response_time=$(jq -r '.p95_response_time // "N/A"' "$latest_dir/results.json" 2>/dev/null)
        if [ "$p95_response_time" != "N/A" ] && [ "$p95_response_time" != "null" ]; then
          local status="pass"
          local status_text="PASS"
          if (( $(echo "$p95_response_time > $DEFAULT_THRESHOLD_RESPONSE_TIME" | bc -l) )); then
            status="fail"
            status_text="FAIL"
          fi
          
          cat >> "$report_file" <<EOF
      <tr>
        <td>Response Time (p95)</td>
        <td>$p95_response_time ms</td>
        <td class="$status">$status_text</td>
      </tr>
EOF
        fi

        # Add error rate
        local error_rate=$(jq -r '.error_rate // "N/A"' "$latest_dir/results.json" 2>/dev/null)
        if [ "$error_rate" != "N/A" ] && [ "$error_rate" != "null" ]; then
          local status="pass"
          local status_text="PASS"
          if (( $(echo "$error_rate > $DEFAULT_THRESHOLD_ERROR_RATE" | bc -l) )); then
            status="fail"
            status_text="FAIL"
          fi
          
          cat >> "$report_file" <<EOF
      <tr>
        <td>Error Rate</td>
        <td>$error_rate%</td>
        <td class="$status">$status_text</td>
      </tr>
EOF
        fi

        # Add requests per second
        local requests_per_second=$(jq -r '.requests_per_second // "N/A"' "$latest_dir/results.json" 2>/dev/null)
        if [ "$requests_per_second" != "N/A" ] && [ "$requests_per_second" != "null" ]; then
          cat >> "$report_file" <<EOF
      <tr>
        <td>Requests Per Second</td>
        <td>$requests_per_second</td>
        <td>-</td>
      </tr>
EOF
        fi

        # Add test-specific metrics
        case "$test_type" in
          stress-test)
            local breaking_point=$(jq -r '.breaking_point // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$breaking_point" != "N/A" ] && [ "$breaking_point" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Breaking Point</td>
        <td colspan="2">$breaking_point</td>
      </tr>
EOF
            fi
            ;;
          endurance-test)
            local max_response_time=$(jq -r '.max_response_time // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$max_response_time" != "N/A" ] && [ "$max_response_time" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Max Response Time</td>
        <td>$max_response_time ms</td>
        <td>-</td>
      </tr>
EOF
            fi
            ;;
          database-test)
            local transactions_per_second=$(jq -r '.transactions_per_second // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$transactions_per_second" != "N/A" ] && [ "$transactions_per_second" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Transactions Per Second</td>
        <td>$transactions_per_second</td>
        <td>-</td>
      </tr>
EOF
            fi
            
            local avg_latency=$(jq -r '.avg_latency // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$avg_latency" != "N/A" ] && [ "$avg_latency" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Average Latency</td>
        <td>$avg_latency ms</td>
        <td>-</td>
      </tr>
EOF
            fi
            ;;
          voice-upload-test)
            local upload_speed=$(jq -r '.upload_speed // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$upload_speed" != "N/A" ] && [ "$upload_speed" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Upload Speed</td>
        <td>$upload_speed KB/s</td>
        <td>-</td>
      </tr>
EOF
            fi
            
            local efficiency=$(jq -r '.efficiency // "N/A"' "$latest_dir/results.json" 2>/dev/null)
            if [ "$efficiency" != "N/A" ] && [ "$efficiency" != "null" ]; then
              cat >> "$report_file" <<EOF
      <tr>
        <td>Upload Efficiency</td>
        <td>$efficiency%</td>
        <td>-</td>
      </tr>
EOF
            fi
            ;;
        esac

        cat >> "$report_file" <<EOF
    </table>
EOF
      fi

      cat >> "$report_file" <<EOF
  </div>
EOF
    fi
  done

  # Finalize HTML
  cat >> "$report_file" <<EOF
  <div class="section">
    <h2>Conclusion and Recommendations</h2>
    <p>Based on the performance test results, the following conclusions and recommendations can be made:</p>
    <ul>
EOF

  # Add general recommendations
  if [ $failed_tests -gt 0 ]; then
    cat >> "$report_file" <<EOF
      <li><span class="warning">Some performance tests failed to meet the defined thresholds. Review the failed tests and consider optimizations or capacity upgrades.</span></li>
EOF
  else
    cat >> "$report_file" <<EOF
      <li><span class="pass">All performance tests passed the defined thresholds. The application demonstrates good performance characteristics.</span></li>
EOF
  fi

  # Check for specific issues
  for results_file in $(find "$OUTPUT_DIR" -name "results.json"); do
    local test_type=$(basename $(dirname "$results_file") | cut -d'-' -f1,2)
    
    # High response time recommendations
    local p95_response_time=$(jq -r '.p95_response_time // 0' "$results_file" 2>/dev/null)
    if (( $(echo "$p95_response_time > $DEFAULT_THRESHOLD_RESPONSE_TIME" | bc -l) )); then
      cat >> "$report_file" <<EOF
      <li><span class="warning">Response times in $test_type tests exceed the threshold. Consider optimizing API endpoints, adding caching, or increasing server resources.</span></li>
EOF
    fi
    
    # High error rate recommendations
    local error_rate=$(jq -r '.error_rate // 0' "$results_file" 2>/dev/null)
    if (( $(echo "$error_rate > $DEFAULT_THRESHOLD_ERROR_RATE" | bc -l) )); then
      cat >> "$report_file" <<EOF
      <li><span class="warning">Error rates in $test_type tests exceed the threshold. Investigate error causes, improve error handling, and consider retry mechanisms.</span></li>
EOF
    fi
  done

  # Add general recommendations
  cat >> "$report_file" <<EOF
      <li>Consider implementing performance monitoring in the production environment to track actual user experience.</li>
      <li>Regularly repeat performance tests after significant application changes to ensure continued performance.</li>
      <li>Review resource scaling policies based on the stress and spike test results to ensure adequate capacity during traffic spikes.</li>
    </ul>
  </div>

  <div class="section">
    <h2>Test Environment</h2>
    <p><strong>Test Date:</strong> $(date)</p>
    <p><strong>Test Environment:</strong> Docker containers</p>
    <p><strong>Test Tool:</strong> k6, pgbench, custom scripts</p>
    <p><strong>Response Time Threshold:</strong> ${DEFAULT_THRESHOLD_RESPONSE_TIME} ms</p>
    <p><strong>Error Rate Threshold:</strong> ${DEFAULT_THRESHOLD_ERROR_RATE}%</p>
  </div>

</body>
</html>
EOF

  echo -e "${GREEN}Consolidated report generated: ${report_file}${NC}"
  return 0
}

# Validate test results against defined thresholds
function validate_results() {
  local results_file=$1
  local threshold_response_time=$2
  local threshold_error_rate=$3
  
  echo -e "${BLUE}Validating test results against thresholds...${NC}"
  
  if [ ! -f "$results_file" ]; then
    echo -e "${RED}Error: Results file not found: $results_file${NC}"
    return 1
  fi
  
  # Extract metrics
  local p95_response_time=$(jq -r '.p95_response_time // "N/A"' "$results_file" 2>/dev/null)
  local error_rate=$(jq -r '.error_rate // "N/A"' "$results_file" 2>/dev/null)
  
  # Check if metrics are available
  if [ "$p95_response_time" = "N/A" ] || [ "$p95_response_time" = "null" ]; then
    echo -e "${YELLOW}Warning: Response time metric not available in results file${NC}"
    p95_response_time=0
  fi
  
  if [ "$error_rate" = "N/A" ] || [ "$error_rate" = "null" ]; then
    echo -e "${YELLOW}Warning: Error rate metric not available in results file${NC}"
    error_rate=0
  fi
  
  # Validate response time
  local response_time_status="PASS"
  if (( $(echo "$p95_response_time > $threshold_response_time" | bc -l) )); then
    response_time_status="FAIL"
  fi
  
  # Validate error rate
  local error_rate_status="PASS"
  if (( $(echo "$error_rate > $threshold_error_rate" | bc -l) )); then
    error_rate_status="FAIL"
  fi
  
  # Print validation results
  echo -e "${BOLD}Validation Results:${NC}"
  echo -e "Response Time (p95): $p95_response_time ms - Threshold: $threshold_response_time ms - ${response_time_status == "PASS" ? "${GREEN}PASS${NC}" : "${RED}FAIL${NC}"}"
  echo -e "Error Rate: $error_rate% - Threshold: $threshold_error_rate% - ${error_rate_status == "PASS" ? "${GREEN}PASS${NC}" : "${RED}FAIL${NC}"}"
  
  # Return success if both validations pass
  if [ "$response_time_status" = "PASS" ] && [ "$error_rate_status" = "PASS" ]; then
    echo -e "${GREEN}Validation passed: All metrics are within defined thresholds${NC}"
    return 0
  else
    echo -e "${RED}Validation failed: One or more metrics exceed defined thresholds${NC}"
    return 1
  fi
}

# Main function that orchestrates the performance testing process
function main() {
  # Default values
  local test_type="$DEFAULT_TEST_TYPE"
  local endpoint="$DEFAULT_ENDPOINT"
  local users="$DEFAULT_USERS"
  local duration="$DEFAULT_DURATION"
  local ramp_up="$DEFAULT_RAMP_UP"
  local max_users=200
  local step_size=10
  local step_duration=30
  local base_users=10
  local spike_users=100
  local file_size=100
  local connections=10
  local threshold_response_time="$DEFAULT_THRESHOLD_RESPONSE_TIME"
  local threshold_error_rate="$DEFAULT_THRESHOLD_ERROR_RATE"
  local keep_containers=false
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -t|--test-type)
        test_type="$2"
        shift 2
        ;;
      -e|--endpoint)
        endpoint="$2"
        shift 2
        ;;
      -u|--users)
        users="$2"
        shift 2
        ;;
      -d|--duration)
        duration="$2"
        shift 2
        ;;
      -r|--ramp-up)
        ramp_up="$2"
        shift 2
        ;;
      -m|--max-users)
        max_users="$2"
        shift 2
        ;;
      -s|--step-size)
        step_size="$2"
        shift 2
        ;;
      -p|--step-duration)
        step_duration="$2"
        shift 2
        ;;
      -b|--base-users)
        base_users="$2"
        shift 2
        ;;
      -S|--spike-users)
        spike_users="$2"
        shift 2
        ;;
      -F|--file-size)
        file_size="$2"
        shift 2
        ;;
      -c|--connections)
        connections="$2"
        shift 2
        ;;
      --response-time)
        threshold_response_time="$2"
        shift 2
        ;;
      --error-rate)
        threshold_error_rate="$2"
        shift 2
        ;;
      -k|--keep)
        keep_containers=true
        shift
        ;;
      -o|--output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        echo -e "${RED}Error: Unknown option $1${NC}"
        print_usage
        exit 1
        ;;
    esac
  done
  
  # Check dependencies
  if ! check_dependencies; then
    echo -e "${RED}Error: Missing critical dependencies${NC}"
    exit 1
  fi
  
  # Create output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"
  
  # Setup environment
  if ! setup_environment; then
    echo -e "${RED}Error: Failed to set up test environment${NC}"
    exit 1
  fi
  
  # Track test status
  local test_status=0
  local latest_results=""
  
  # Run requested test type
  case "$test_type" in
    load)
      run_load_test "$endpoint" "$users" "$duration" "$ramp_up"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    stress)
      run_stress_test "$endpoint" "$users" "$max_users" "$step_size" "$step_duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    endurance)
      run_endurance_test "$endpoint" "$users" "$duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    spike)
      run_spike_test "$endpoint" "$base_users" "$spike_users" "$duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    api)
      run_api_endpoint_test "load" "$users" "$duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    db)
      run_database_performance_test "$connections" "$duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    voice)
      run_voice_journal_upload_test "$users" "$file_size" "$duration"
      test_status=$?
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    all)
      echo -e "${BLUE}Running all test types...${NC}"
      
      run_load_test "$endpoint" "$users" "$duration" "$ramp_up"
      local load_status=$?
      
      run_stress_test "$endpoint" "$users" "$max_users" "$step_size" "$step_duration"
      local stress_status=$?
      
      run_endurance_test "$endpoint" "$users" "$duration"
      local endurance_status=$?
      
      run_spike_test "$endpoint" "$base_users" "$spike_users" "$duration"
      local spike_status=$?
      
      run_api_endpoint_test "load" "$users" "$duration"
      local api_status=$?
      
      run_database_performance_test "$connections" "$duration"
      local db_status=$?
      
      run_voice_journal_upload_test "$users" "$file_size" "$duration"
      local voice_status=$?
      
      # Set overall status
      test_status=$(( load_status || stress_status || endurance_status || spike_status || api_status || db_status || voice_status ))
      
      # Use the latest results file for validation
      latest_results=$(find "$OUTPUT_DIR" -name "results.json" -type f -exec stat -c "%Y %n" {} \; | sort -nr | head -n1 | cut -d' ' -f2)
      ;;
    *)
      echo -e "${RED}Error: Unknown test type $test_type${NC}"
      print_usage
      exit 1
      ;;
  esac
  
  # Validate results if available
  if [ -n "$latest_results" ] && [ -f "$latest_results" ]; then
    validate_results "$latest_results" "$threshold_response_time" "$threshold_error_rate"
    local validation_status=$?
    
    if [ $validation_status -ne 0 ]; then
      test_status=1
    fi
  fi
  
  # Generate report
  generate_report
  
  # Teardown environment
  teardown_environment "$keep_containers"
  
  # Print final status
  if [ $test_status -eq 0 ]; then
    echo -e "${GREEN}Performance tests completed successfully${NC}"
  else
    echo -e "${YELLOW}Performance tests completed with issues${NC}"
  fi
  
  return $test_status
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Process arguments
  if [ $# -eq 0 ]; then
    print_usage
    exit 0
  fi
  
  # Run main function with all arguments
  main "$@"
  exit $?
fi