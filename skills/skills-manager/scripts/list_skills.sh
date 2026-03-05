#!/bin/bash
# List all skills in the central repository.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config

echo "=== Skills in Central Repository ==="
ls -1 "$CENTRAL_REPO" | grep -v ".DS_Store" | sort

echo ""
echo "Total: $(ls -1 "$CENTRAL_REPO" | grep -v ".DS_Store" | wc -l) skills"
