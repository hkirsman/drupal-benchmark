#!/bin/bash

# Benchmark Drupal site performance across different pages and configurations.
# Records total execution time and individual test durations.
#
# Usage: ./benchmark.sh <ddev|lando> [concurrent] [requests] [urls_file]
#   concurrent: Number of concurrent requests (default: 10)
#   requests: Total number of requests (default: 500)
#   urls_file: Path to file containing URLs to test (default: urls.txt)

set -euo pipefail

# Default values
CONCURRENT=10
REQUESTS=2000
URLS_FILE="urls.txt"
TIMEOUT=30
OUTPUT_DIR="benchmark_results_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_dependencies() {
    local deps=("ab" "curl" "bc")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required dependency '$dep' is not installed."
            exit 1
        fi
    done
}

create_default_urls() {
    if [[ ! -f "$URLS_FILE" ]]; then
        cat > "$URLS_FILE" << EOL
/admin/modules
/admin/config
/admin/content
/node/add
/admin/people
EOL
        log_info "Created default URLs file: $URLS_FILE"
    fi
}

# Validate input parameters
if [[ $# -lt 1 || ( "$1" != "ddev" && "$1" != "lando" ) ]]; then
    log_error "First parameter must be either 'ddev' or 'lando'."
    echo "Usage: $0 <ddev|lando> [concurrent] [requests] [urls_file]"
    exit 1
fi

PLATFORM="$1"
[[ $# -ge 2 ]] && CONCURRENT="$2"
[[ $# -ge 3 ]] && REQUESTS="$3"
[[ $# -ge 4 ]] && URLS_FILE="$4"

# Check dependencies and create output directory
check_dependencies
mkdir -p "$OUTPUT_DIR"

# Create default URLs file if it doesn't exist
create_default_urls

# Get base URL based on platform
BASE_URL="https://drupal-benchmark.$([[ $PLATFORM == "ddev" ]] && echo "ddev.site" || echo "lndo.site")"

# Get login URL and clean it
log_info "Getting login URL..."
login_url="$($PLATFORM drush uli)"
login_url="${login_url//[$'\r\n']}"

# Get session cookie
log_info "Obtaining session cookie..."
drupal_session_cookie=$(curl \
    --insecure \
    --max-redirs 5 \
    --silent \
    --cookie-jar - \
    "$login_url" | grep -Eo 'SSESS[a-z0-9]+[[:space:]][a-zA-Z0-9%-]+' || true)

if [[ -z "$drupal_session_cookie" ]]; then
    log_error "Failed to obtain session cookie"
    exit 1
fi

# Format cookie for ab
drupal_session_cookie="${drupal_session_cookie//[[:space:]]/=}"

# Start timing
START_TIME=$(date +%s)

# Create summary file
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
echo "Benchmark Summary - $(date)" > "$SUMMARY_FILE"
echo "Platform: $PLATFORM" >> "$SUMMARY_FILE"
echo "Concurrent Users: $CONCURRENT" >> "$SUMMARY_FILE"
echo "Requests per URL: $REQUESTS" >> "$SUMMARY_FILE"
echo "----------------------------------------" >> "$SUMMARY_FILE"

# Run benchmarks for each URL
while IFS= read -r url_path || [[ -n "$url_path" ]]; do
    # Skip empty lines and comments
    [[ -z "$url_path" || "$url_path" =~ ^# ]] && continue

    full_url="${BASE_URL}${url_path}"
    output_file="$OUTPUT_DIR/$(echo "$url_path" | sed 's/\//_/g').txt"

    log_info "Benchmarking $full_url..."

    if ! ab -C "$drupal_session_cookie" \
          -c "$CONCURRENT" \
          -n "$REQUESTS" \
          -l \
          -r \
          -s "$TIMEOUT" \
          -v 2 \
          "$full_url" > "$output_file" 2>&1; then
        log_error "Benchmark failed for $url_path"
        echo "FAILED: $url_path" >> "$SUMMARY_FILE"
        continue
    fi

    # Extract and save key metrics
    rps=$(grep "Requests per second" "$output_file" | awk '{print $4}')
    mean_time=$(grep "Time per request" "$output_file" | head -n 1 | awk '{print $4}')
    failed=$(grep "Failed requests" "$output_file" | awk '{print $3}')

    echo "URL: $url_path" >> "$SUMMARY_FILE"
    echo "  Requests per second: $rps" >> "$SUMMARY_FILE"
    echo "  Mean time per request: $mean_time ms" >> "$SUMMARY_FILE"
    echo "  Failed requests: $failed" >> "$SUMMARY_FILE"
    echo "----------------------------------------" >> "$SUMMARY_FILE"
done < "$URLS_FILE"

# Calculate total duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Add duration to summary
echo -e "\nTotal Execution Time: ${MINUTES}m ${SECONDS}s" >> "$SUMMARY_FILE"

log_info "Benchmark complete! Results saved in: $OUTPUT_DIR"
log_info "Summary available in: $SUMMARY_FILE"
log_info "Total execution time: ${MINUTES}m ${SECONDS}s"
