#!/bin/bash

################################################################################
#
# Configuration
#
# - BENCHMARK_ENV: Set to "dev" for development mode, or leave unset for production.
#   These variables are loaded from .ddev/.env file (automatically loaded by DDEV).
#
# The script will automatically use local URLs when BENCHMARK_ENV=dev
# Otherwise, it uses production URLs by default.
#
################################################################################

# Lock the Locust image name and version to ensure stability.
LOCUST_IMAGE="locustio/locust:2.42.6"

# Load environment variables from .ddev/.env if it exists
if [ -f ".ddev/.env" ]; then
  export $(grep -v '^#' .ddev/.env | xargs)
fi

# Set URLs based on environment.
if [[ "$BENCHMARK_ENV" == "dev" ]]; then
  API_URL="${BENCHMARK_BASE_URL_DEV}/api/submit"
  CACHE_CLEAR_URL="${BENCHMARK_BASE_URL_DEV}/api/clear-cache"
  DASHBOARD_URL="${BENCHMARK_BASE_URL_DEV}"
  echo "🔧 Development mode enabled"
else
  API_URL="${BENCHMARK_BASE_URL_PROD}/api/submit"
  CACHE_CLEAR_URL="${BENCHMARK_BASE_URL_PROD}/api/clear-cache"
  DASHBOARD_URL="${BENCHMARK_BASE_URL_PROD}"
fi

echo "Using API endpoint: $API_URL"
echo "Using cache clear endpoint: $CACHE_CLEAR_URL"
echo "Dashboard URL: $DASHBOARD_URL"
echo ""

################################################################################
#
# Script Logic (No need to edit below this line)
#
################################################################################

# --- 1. Pre-flight Checks ---

set -e # Exit immediately if a command exits with a non-zero status.

# Ensure the first parameter is either "ddev" or "lando".
if [[ $# -lt 1 || ( "$1" != "ddev" && "$1" != "lando" ) ]]; then
  echo "Error: First parameter must be either 'ddev' or 'lando'." >&2
  echo "Usage: ./benchmark.sh ddev" >&2
  exit 1
fi

for tool in jq docker curl; do
  if ! command -v $tool &> /dev/null; then
      echo "Error: Required tool '$tool' is not installed. Please install it." >&2
      exit 1
  fi
done

# --- 2. Run the Benchmark ---

ENVIRONMENT=$1
TEMP_STATS_FILE=$(mktemp)
# Ensure temp file is deleted on exit.
trap 'rm -f -- "$TEMP_STATS_FILE"' EXIT

# Ask for computer model information early
echo ""
echo "Please enter your computer model (e.g., 'MacBook Pro 14”, Nov 2024', 'Lenovo ThinkPad S3-S440', 'Acer Aspire V 13'):"
echo "Press Enter to skip if you don't want to specify this."
read -r COMPUTER_MODEL
if [ -z "$COMPUTER_MODEL" ]; then
  COMPUTER_MODEL="Unknown"
fi

# Ask for additional context/comment
echo ""
echo "Optionally please enter any additional context or comments about this benchmark run:"
echo "Examples: 'on battery', 'Performance mode', 'many browser tabs open', 'fresh restart', 'SSD vs HDD', 'WiFi vs Ethernet'"
echo "Press Enter to skip if you don't want to add any comments."
read -r BENCHMARK_COMMENT
if [ -z "$BENCHMARK_COMMENT" ]; then
  BENCHMARK_COMMENT=""
fi

# Determine host URL based on environment.
if [[ "$ENVIRONMENT" == "ddev" ]]; then
  HOST_URL="https://drupal-benchmark.ddev.site"
elif [[ "$ENVIRONMENT" == "lando" ]]; then
  HOST_URL="https://drupal-benchmark.lndo.site"
fi

echo "Drupal Benchmark"
echo "--------------------------------------------------"

echo "Getting Drupal user login URL for environment: $ENVIRONMENT..."
login_url=$($ENVIRONMENT drush uli)
if [ -z "$login_url" ]; then
    echo "Error: Failed to get login URL from Drush. Is '$ENVIRONMENT' running?" >&2
    exit 1
fi

# Clear Drupal caches so the benchmark always includes the first uncached request.
echo "Clearing Drupal cache via Drush before running Locust..."
if ! $ENVIRONMENT drush cr; then
  echo "Error: Failed to clear Drupal cache. Aborting benchmark." >&2
  exit 1
fi

echo "Running Locust benchmark for 30 seconds using Docker ($LOCUST_IMAGE)..."

# Run Locust via Docker
# --network host: allows container to access the ddev/lando URLs on localhost
# -v $(pwd):/mnt/locust: mounts current folder to /mnt/locust in the container so it can find locustfile.py
docker run --rm \
  --network host \
  -v "$(pwd):/mnt/locust" \
  -e ULI="$login_url" \
  "$LOCUST_IMAGE" \
  -f /mnt/locust/locustfile.py \
  --headless \
  --only-summary \
  --users 1 \
  --spawn-rate 1 \
  --run-time 30 \
  --stop-timeout 5 \
  --json \
  -H "$HOST_URL" \
  > "$TEMP_STATS_FILE"

echo "Benchmark finished."
echo "--------------------------------------------------"

# --- 3. Gather Data and Send ---

gather_metadata() {
  os_name=$(uname -s)
  arch=$(uname -m)
  git_commit=$(git rev-parse --short HEAD)
  # Get benchmark version from composer.json; fallback to commit hash handled below
  benchmark_version=$(jq -r '.version // ""' composer.json 2>/dev/null)
  if [ -z "$benchmark_version" ] || [ "$benchmark_version" = "null" ]; then
    benchmark_version="$git_commit"
  fi
  drupal_version=$($ENVIRONMENT drush status --field=drupal-version)

  # Web server detection
  web_server="Unknown"
  if [[ "$ENVIRONMENT" == "ddev" ]]; then
    # Check which web server process is actually running in DDEV
    if $ENVIRONMENT exec ps -ef | grep "nginx" | grep -v grep > /dev/null 2>&1; then
      web_server="nginx"
    elif $ENVIRONMENT exec ps -ef | grep "apache2" | grep -v grep > /dev/null 2>&1; then
      web_server="apache"
    fi
  elif [[ "$ENVIRONMENT" == "lando" ]]; then
    # Check which web server process is actually running in Lando
    if $ENVIRONMENT ssh -s appserver_nginx -c "ps -ef" | grep "nginx" | grep -v grep > /dev/null 2>&1; then
      web_server="nginx"
    elif $ENVIRONMENT ssh -s appserver -c "ps -ef" | grep "apache2" | grep -v grep > /dev/null 2>&1; then
      web_server="apache"
    fi
  fi

  # DDEV/Lando version detection
  dev_tool_version="Unknown"
  if [[ "$ENVIRONMENT" == "ddev" ]]; then
    version_output=$(ddev --version 2>/dev/null | head -1)
    # Extract just the version number (e.g., "v1.24.4" from "ddev version v1.24.4")
    dev_tool_version=$(echo "$version_output" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
  elif [[ "$ENVIRONMENT" == "lando" ]]; then
    version_output=$(lando version 2>/dev/null | head -1)
    # Extract just the version number (e.g., "v3.10.0" from "lando v3.10.0")
    dev_tool_version=$(echo "$version_output" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
  fi

  # Combine environment and version
  environment_with_version="$ENVIRONMENT"
  if [[ "$dev_tool_version" != "Unknown" ]]; then
    environment_with_version="$ENVIRONMENT $dev_tool_version"
  fi

  # Improved Docker version detection
  if command -v docker &> /dev/null; then
    docker_version=$(docker --version | sed 's/Docker version //' | sed 's/,.*//')
  else
    docker_version=""
  fi

  # Database detection
  db_version_raw=$($ENVIRONMENT mysql --version 2>/dev/null | head -n 1)
  if [ -n "$db_version_raw" ]; then
    # Extract the distribution version (e.g., 10.3.39-MariaDB or 8.0.35)
    db_version=$(echo "$db_version_raw" | sed -n 's/.*Distrib \([0-9]\+\.[0-9]\+\.[0-9]\+[^,]*\).*/\1/p')
    if [ -z "$db_version" ]; then
      # Fallback: try to extract just the version number
      db_version=$(echo "$db_version_raw" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi

    # Determine database type from version string
    if echo "$db_version_raw" | grep -q "MariaDB"; then
      db_type="MariaDB"
    else
      db_type="MySQL"
    fi
  else
    db_type="Unknown"
    db_version="Unknown"
  fi

  # PHP version detection
  php_version_raw=$($ENVIRONMENT php --version 2>/dev/null | head -n 1)
  if [ -n "$php_version_raw" ]; then
    # Extract just the version number (e.g., 8.0.30)
    php_version=$(echo "$php_version_raw" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
  else
    php_version="Unknown"
  fi

  user_name=$(whoami)

  if [[ "$os_name" == "Darwin" ]]; then
    cpu_info=$(sysctl -n machdep.cpu.brand_string)
    total_mem_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
  elif [[ "$os_name" == "Linux" ]]; then
    cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//')
    total_mem_gb=$(( $(grep "MemTotal" /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
  else
    cpu_info="Unknown"
    total_mem_gb="Unknown"
  fi

  jq -n \
    --arg environment "$environment_with_version" \
    --arg user_name "$user_name" \
    --arg git_commit "$git_commit" \
    --arg benchmark_version "$benchmark_version" \
    --arg drupal_version "$drupal_version" \
    --arg docker_version "$docker_version" \
    --arg web_server "$web_server" \
    --arg db_type "$db_type" \
    --arg db_version "$db_version" \
    --arg php_version "$php_version" \
    --arg computer_model "$COMPUTER_MODEL" \
    --arg benchmark_comment "$BENCHMARK_COMMENT" \
    --argjson system_info "$(jq -n --arg os "$os_name" --arg arch "$arch" --arg cpu "$cpu_info" --arg mem "${total_mem_gb}GB" '{os:$os, arch:$arch, cpu:$cpu, memory:$mem}')" \
    '{metadata: {environment:$environment, user_name:$user_name, commit:$git_commit, benchmark_version:$benchmark_version, drupal_version:$drupal_version, docker_version:$docker_version, web_server:$web_server, database:{type:$db_type, version:$db_version}, php_version:$php_version, computer_model:$computer_model, comment:$benchmark_comment, system:$system_info}}'
}

echo "Preparing data for submission..."
METADATA_JSON=$(gather_metadata)
# Create the final JSON structure expected by the API: {metadata: {...}, stats: [...]}
FINAL_JSON=$(jq -n --argjson metadata "$METADATA_JSON" --argjson stats "$(cat "$TEMP_STATS_FILE")" '$metadata + {stats: $stats}')

echo "Submitting benchmark data to the central dashboard..."
# --insecure is needed for self-signed certificates of DDEV.
response_code=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$FINAL_JSON" \
  ${BENCHMARK_ENV:+--insecure})

if [ "$response_code" -ge 200 ] && [ "$response_code" -lt 300 ]; then
  echo "Data submitted successfully! (Server responded with HTTP $response_code)"

  # Clear the cache to ensure fresh data is displayed
  echo "Clearing cache to refresh dashboard..."
  cache_response_code=$(curl --silent --output /dev/null --write-out "%{http_code}" \
    -X POST "$CACHE_CLEAR_URL" \
    ${BENCHMARK_ENV:+--insecure})

  if [ "$cache_response_code" -eq 200 ]; then
    echo "Cache cleared successfully!"
  else
    echo "Warning: Cache clearing failed (HTTP $cache_response_code), but data was submitted successfully."
  fi

  echo ""
  echo "Check your results at: $DASHBOARD_URL"
else
  echo "Error: Failed to submit data. The server responded with HTTP status $response_code." >&2
  echo "You can view the data payload that was not sent:" >&2
  echo "$FINAL_JSON" >&2
fi

echo "--------------------------------------------------"
