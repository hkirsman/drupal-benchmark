#!/bin/bash

# Benchmark Drupal site.

set -xeuo pipefail
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:$HOME/.composer/vendor/bin"

cookie_file="cookies.txt"

# Get login URL and remove \r fron the end.
login_url="$(lando drush uli)"
login_url="${login_url//[$'\r']}"

# Log in and save cookie info to file.
curl \
  --insecure \
  --max-redirs 5 \
  --cookie-jar $cookie_file \
  ${login_url}

# Get SESS cookie from cookies.txt and remove the cookies.txt.
drupal_session_cookie="$(grep -Eo 'SSESS[a-z0-9]+\s[a-zA-Z0-9%-]+' $cookie_file)"
rm ${cookie_file}

# Replace space with = to make it acceptable parameter for ab tool.
drupal_session_cookie=$(sed 's/\s/=/g' <<< "$drupal_session_cookie")

# Run ab tests.
ab -C ${drupal_session_cookie} -n 50 -l https://drupal-project.lndo.site/admin/modules
