#!/bin/bash

setup_odoo_source() {
    cd /opt/midoo
    if ! directory_exists /opt/midoo/odoo; then
        echo "Cloning the Odoo 17 source code..."
        sudo git clone --depth 1 --branch 17.0 https://www.github.com/odoo/odoo ./odoo
    else
        echo "Odoo source code directory already exists. Updating..."
        cd /opt/midoo/odoo
        sudo -H -u midoo git pull origin 17.0
    fi
    sudo chown -R midoo:midoo /opt/midoo
}

setup_virtualenv() {
    if ! directory_exists /opt/midoo/venv; then
        cd /opt/midoo
        sudo -H -u midoo python3.11 -m venv venv 
    fi
    source /opt/midoo/venv/bin/activate
}

install_python_dependencies() {
    cd /opt/midoo/odoo
    sudo -H -u midoo bash -c "
        source /opt/midoo/venv/bin/activate &&
        pip install --upgrade pip wheel &&
        pip install --upgrade 'Cython' 'setuptools' &&
        pip install --no-cache-dir -r /opt/midoo/odoo/requirements.txt --prefer-binary
    "
}

install_wkhtmltopdf() {
    if ! command -v wkhtmltopdf &>/dev/null; then
        echo "Installing Wkhtmltopdf dependencies..."
        sudo apt-get install -y fontconfig libxext6 libxrender1 xfonts-75dpi xfonts-base

        echo "Installing Wkhtmltopdf..."
        wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
        sudo dpkg -i wkhtmltox_0.12.6-1.focal_amd64.deb || true
        sudo apt-get -f install -y  

        echo "Creating symbolic links..."
        sudo ln -sf /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
        sudo ln -sf /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage
    else
        echo "Wkhtmltopdf is already installed. Skipping."
    fi
}

setup_midoo_service() {
    if ! service_exists midoo; then
        echo "Configuring Midoo systemd service..."
        cat <<EOF | sudo tee /etc/systemd/system/midoo.service
[Unit]
Description=Midoo
Requires=network.target
After=network.target

[Service]
Type=simple
SyslogIdentifier=midoo
PermissionsStartOnly=true
User=midoo
Group=midoo
ExecStart=/opt/midoo/venv/bin/python /opt/midoo/odoo/odoo-bin -c /etc/midoo.conf
WorkingDirectory=/opt/midoo/odoo
Restart=always
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    fi
}


create_midoo_config() {
    echo "Creating Midoo configuration file..."
    cat <<EOF | sudo tee /etc/midoo.conf
[options]
admin_passwd = $ADMIN_PASSWORD
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_name = $DB_NAME
db_password = $DB_PASSWORD
dbfilter = $DB_NAME
list_db = False
addons_path = /opt/midoo/odoo/addons,/opt/midoo/custom-apps
logfile = /var/log/midoo/midoo.log
logrotate = True
proxy_mode = True
EOF
}