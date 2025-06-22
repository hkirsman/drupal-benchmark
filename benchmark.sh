#!/bin/bash

################################################################################
#
# Configuration
#
# - API_URL: The full URL to the API endpoint in your deployed Next.js app.
# - SUBMISSION_SECRET: A simple password that the script sends to your API.
#   This secret must also be set in your Next.js app's environment variables.
#   The secret is loaded from .ddev/.env file (automatically loaded by DDEV).
#
################################################################################

API_URL="https://drupal-benchmark.vercel.app/api/submit"
# Enable if developing locally.
# First run the next.js erver:
# cd next && ddev npm run dev
#API_URL="https://frontend.drupal-benchmark.ddev.site/api/submit"

# Check if SUBMISSION_SECRET is set
if [ -z "$SUBMISSION_SECRET" ]; then
  # Try to read from .ddev/.env file as fallback
  if [ -f ".ddev/.env" ]; then
    export $(grep -v '^#' .ddev/.env | xargs)
  fi

  # Check again after trying to load from file
  if [ -z "$SUBMISSION_SECRET" ]; then
    echo "Error: SUBMISSION_SECRET environment variable is not set." >&2
    echo "Please create a .ddev/.env file with:" >&2
    echo "SUBMISSION_SECRET=your_secret_here" >&2
    exit 1
  fi
fi

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

for tool in jq locust curl; do
  if ! command -v $tool &> /dev/null; then
      echo "Error: Required tool '$tool' is not installed. Please install it." >&2
      exit 1
  fi
done

# --- 2. Run the Benchmark ---

ENVIRONMENT=$1
TEMP_STATS_FILE=$(mktemp)
trap 'rm -f -- "$TEMP_STATS_FILE"' EXIT # Ensure temp file is deleted on exit

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

echo "Running Locust benchmark for 30 seconds..."
ULI="$login_url" locust --headless --users 1 --spawn-rate 1 --run-time 30 --stop-timeout 5 --json -H "$HOST_URL" > "$TEMP_STATS_FILE"
echo "Benchmark finished."
echo "--------------------------------------------------"

# --- 3. Gather Data and Send ---

gather_metadata() {
  os_name=$(uname -s)
  arch=$(uname -m)
  git_commit=$(git rev-parse --short HEAD)
  drupal_version=$($ENVIRONMENT drush status --field=drupal-version)

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
    --arg environment "$ENVIRONMENT" \
    --arg git_commit "$git_commit" \
    --arg drupal_version "$drupal_version" \
    --argjson system_info "$(jq -n --arg os "$os_name" --arg arch "$arch" --arg cpu "$cpu_info" --arg mem "${total_mem_gb}GB" '{os:$os, arch:$arch, cpu:$cpu, memory:$mem}')" \
    '{metadata: {environment:$environment, commit:$git_commit, drupal_version:$drupal_version, system:$system_info}}'
}

echo "Preparing data for submission..."
METADATA_JSON=$(gather_metadata)
# Create the final JSON structure expected by the API: {metadata: {...}, stats: [...]}
FINAL_JSON=$(jq -n --argjson metadata "$METADATA_JSON" --argjson stats "$(cat "$TEMP_STATS_FILE")" '$metadata + {stats: $stats}')

echo "Submitting benchmark data to the central dashboard..."
response_code=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUBMISSION_SECRET" \
  -d "$FINAL_JSON")

if [ "$response_code" -ge 200 ] && [ "$response_code" -lt 300 ]; then
  echo "Data submitted successfully! (Server responded with HTTP $response_code)"
else
  echo "Error: Failed to submit data. The server responded with HTTP status $response_code." >&2
  echo "You can view the data payload that was not sent:" >&2
  echo "$FINAL_JSON" >&2
fi

echo "--------------------------------------------------"
