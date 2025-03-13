#!/bin/bash


SCRIPT_DIR="./scripts"
. "$SCRIPT_DIR/sync-custom-addons.sh"

sync_custom_modules

echo "Refresh addons completed successfully!"