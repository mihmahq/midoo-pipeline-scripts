
#!/bin/bash

start_odoo_service() {
    if ! systemctl is-active --quiet midoo; then
        echo "Starting Midoo service..."
        sudo systemctl daemon-reload
        sudo systemctl enable --now midoo
    else
        echo "Midoo service is already running. Restarting..."
        sudo systemctl restart midoo
    fi
}