#!/bin/bash

echo "Installing Temperature Monitoring with Discord Alerts..."

# Copy script to system
sudo cp fan-temp-monitor-discord.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/fan-temp-monitor-discord.sh

echo "✓ Script installed"
echo ""
echo "For detailed setup, see README.md"
