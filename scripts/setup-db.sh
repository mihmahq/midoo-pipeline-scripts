#!/bin/bash

create_db_and_install_base_modules() {
    echo "Creating the new database..."
    export PGPASSWORD="$DB_PASSWORD"

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME TEMPLATE midoo_base_cm_template;"

    if [ $? -eq 0 ]; then
        echo "Database '$DB_NAME' created successfully."
    else
        echo "Failed to create database '$DB_NAME'."
     fi

    unset PGPASSWORD
}