#!/bin/bash

setup_logging() {
    if ! directory_exists /var/log/midoo; then
        echo "Creating log directory..."
        sudo mkdir -p /var/log/midoo
        sudo chown -R midoo:midoo /var/log/midoo
    else
        echo "Log directory already exists."
    fi
}