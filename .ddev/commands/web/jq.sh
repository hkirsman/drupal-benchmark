#!/usr/bin/env bash

## Description: Runs jq commands (jq is a lightweight and portable command-line JSON processor).
## Usage: jq [jq-arguments]
## Example: "ddev jq . file.json"

if ! command -v jq &> /dev/null; then
  echo "jq is not installed in this container." >&2
  exit 1
fi

jq "$@"
