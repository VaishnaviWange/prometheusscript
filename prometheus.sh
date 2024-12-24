#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (use sudo)"
    exit 1
fi

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 1: Create a Prometheus user and directories
echo "Creating Prometheus user and directories..."
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Step 2: Download and extract Prometheus
PROM_VERSION="2.47.0"  # Update to the latest version if needed
echo "Downloading Prometheus version $PROM_VERSION..."
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz -O prometheus.tar.gz

echo "Extracting Prometheus..."
tar -xvf prometheus.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64 || exit 1

# Step 3: Move Prometheus binaries and files
echo "Moving Prometheus binaries and configuration files..."
sudo mv prometheus /usr/local/bin/
sudo mv promtool /usr/local/bin/
sudo mv consoles /etc/prometheus/
sudo mv console_libraries /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/

# Step 4: Set ownership permissions
echo "Setting permissions..."
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Step 5: Create a systemd service file
echo "Creating Prometheus systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service > /dev/null
[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries
