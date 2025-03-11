#!/bin/bash

# Exit on error
set -e

# Check if all required parameters are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <db_host> <db_port> <db_user> <db_password> <admin_password> <db_name>"
    exit 1
fi

# Assign command-line arguments to variables
DB_HOST=$1
DB_PORT=$2
DB_USER=$3
DB_PASSWORD=$4
ADMIN_PASSWORD=$5
DB_NAME=$6

user_exists() {
    id -u "$1" >/dev/null 2>&1
}

# Function to check if a directory exists
directory_exists() {
    [ -d "$1" ]
}

# Function to check if a systemd service exists
service_exists() {
    systemctl list-unit-files --full | grep -q "^$1.service"
}


SCRIPT_DIR="./scripts"
. "$SCRIPT_DIR/apt-dependencies.sh"
. "$SCRIPT_DIR/install-python.sh"
. "$SCRIPT_DIR/create-user.sh"
. "$SCRIPT_DIR/configure-logging.sh"
. "$SCRIPT_DIR/install-odoo.sh"
. "$SCRIPT_DIR/sync-custom-addons.sh"
. "$SCRIPT_DIR/setup-db.sh"
. "$SCRIPT_DIR/start-service.sh"


# Functions to be called in order.
install_dependencies
install_python3_11
create_midoo_user
setup_logging
setup_odoo_source
setup_virtualenv
install_python_dependencies
install_wkhtmltopdf
setup_midoo_service
create_midoo_config
sync_custom_modules
sync_custom_modules
sync_custom_modules
create_db_and_install_base_modules
start_odoo_service

echo "Midoo installation completed successfully!"