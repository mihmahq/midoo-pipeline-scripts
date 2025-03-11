#!/bin/bash

create_midoo_user() {
    if ! user_exists midoo; then
        echo "Creating a system user for Midoo..."
        sudo useradd -m -d /opt/midoo -U -r -s /bin/bash midoo
    else
        echo "System user 'midoo' already exists."
    fi
}