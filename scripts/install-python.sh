#!/bin/bash

install_python3_11() {
    if command -v python3.11 &>/dev/null; then
        echo "Python 3.11 is already installed. Skipping installation."
        return
    fi

    echo "Python 3.11 not found. Installing..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
    echo "Python 3.11 installation completed."
}