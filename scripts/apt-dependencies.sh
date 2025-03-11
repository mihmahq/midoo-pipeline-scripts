#!/bin/bash

install_dependencies() {
    echo "Updating and upgrading the system..."
    sudo apt-get update && sudo apt-get upgrade -y
    echo "Installing required dependencies..."
    sudo apt-get install -y python3-pip python3-dev python3-venv libxml2-dev libxslt1-dev \
        zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev \
        libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev parallel \
        software-properties-common postgresql-client
}