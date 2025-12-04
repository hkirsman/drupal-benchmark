#!/bin/bash

# Benchmark the Drupal site.

# Lock the Locust image name and version to ensure stability.
LOCUST_IMAGE="locustio/locust:2.42.6"

# Ensure the first parameter is either "ddev" or "lando".
if [[ $# -lt 1 || ( "$1" != "ddev" && "$1" != "lando" ) ]]; then
  echo "Error: First parameter must be either 'ddev' or 'lando'."
  exit 1
fi

ENVIRONMENT=$1

if ! command -v docker &> /dev/null; then
    echo "Error: Required tool 'docker' is not installed." >&2
    exit 1
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
  --users 1 \
  --spawn-rate 1 \
  --run-time 30 \
  --stop-timeout 5 \
  --only-summary \
  -H "$HOST_URL"
