#!/bin/bash

# Benchmark the Drupal site.

# Ensure the first parameter is either "ddev" or "lando".
if [[ $# -lt 1 || ( "$1" != "ddev" && "$1" != "lando" ) ]]; then
  echo "Error: First parameter must be either 'ddev' or 'lando'."
  exit 1
fi

# Get the Drupal login URL with drush.
login_url="$($1 drush uli)"

# Run load tests with Locust.
if [[ "$1" == "ddev" ]]; then
  ULI="$login_url" locust --headless --users 1 --spawn-rate 1 --run-time 30 --stop-timeout 5 --only-summary -H https://drupal-benchmark.ddev.site
elif [[ "$1" == "lando" ]]; then
  ULI="$login_url" locust --headless --users 1 --spawn-rate 1 --run-time 30 --stop-timeout 5 --only-summary -H https://drupal-benchmark.lndo.site
fi
