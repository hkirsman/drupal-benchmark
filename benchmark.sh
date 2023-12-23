#!/bin/bash

# Benchmark Drupal site.

set -xeuo pipefail

# Get login URL and remove \r fron the end.
login_url="$(lando drush uli)"
login_url="${login_url//[$'\r']}"

# Log in and output cookies to stdout.
drupal_session_cookie=$(curl \
  --insecure \
  --max-redirs 5 \
  --cookie-jar - \
  "$login_url" | grep -Eo 'SSESS[a-z0-9]+\s[a-zA-Z0-9%-]+')

# Replace space with = to make it acceptable parameter for ab tool.
drupal_session_cookie=$(sed 's/\s/=/g' <<< "$drupal_session_cookie")

# In some OS's \s does not match tabs so let's try and catch that here.
drupal_session_cookie=$(sed 's/\t/=/g' <<< "$drupal_session_cookie")

# Run ab tests.
ab -C ${drupal_session_cookie} -n 50 -l "$1"
