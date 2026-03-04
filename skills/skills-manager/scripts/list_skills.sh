#!/bin/bash
# List all skills in the central repository

CENTRAL_REPO="/Users/yes365/Run/NoCode/skills"

echo "=== Skills in Central Repository ==="
ls -1 "$CENTRAL_REPO" | grep -v ".DS_Store" | sort

echo ""
echo "Total: $(ls -1 "$CENTRAL_REPO" | grep -v ".DS_Store" | wc -l) skills"
