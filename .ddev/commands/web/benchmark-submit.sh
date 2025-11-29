#!/usr/bin/env bash

## Description: Run codeception
## Usage: benchmark-submit
## Example: "ddev benchmark-submit"

set -euo pipefail
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/var/www/html/vendor/bin

# Run the benchmark-submit.sh script with ddev parameter
./benchmark-submit.sh ddev
