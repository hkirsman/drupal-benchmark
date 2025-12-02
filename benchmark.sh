#!/bin/bash

# Benchmark the Drupal site.

# Lock the Locust image name and version to ensure stability.
LOCUST_IMAGE="locustio/locust:2.42.6"

# Ensure the first parameter is either "ddev" or "lando".
if [[ $# -lt 1 || ( "$1" != "ddev" && "$1" != "lando" ) ]]; then
  echo "Error: First parameter must be either 'ddev' or 'lando'."
  exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: Required tool 'docker' is not installed." >&2
    exit 1
fi

# Get the Drupal login URL with drush.
login_url="$($1 drush uli)"

# Determine host based on environment
if [[ "$1" == "ddev" ]]; then
  HOST_URL="https://drupal-benchmark.ddev.site"
elif [[ "$1" == "lando" ]]; then
  HOST_URL="https://drupal-benchmark.lndo.site"
fi

echo "Running Locust benchmark using Docker image: $LOCUST_IMAGE"

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
