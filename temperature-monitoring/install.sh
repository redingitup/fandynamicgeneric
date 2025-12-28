#!/bin/bash

# Temperature Monitoring Installation Script
# Installs the Discord temperature alert script

echo "Installing Temperature Monitoring with Discord Alerts..."
echo ""

# Check if ipmitool is installed
if ! command -v ipmitool &> /dev/null; then
    echo "ERROR: ipmitool not found!"
    echo "Install it with: sudo apt-get install ipmitool"
    exit 1
fi

echo "✓ ipmitool found"
echo ""

# Copy script to system
sudo cp fan-temp-monitor-discord.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/fan-temp-monitor-discord.sh

echo "✓ Script installed to /usr/local/bin/fan-temp-monitor-discord.sh"
echo ""
echo "Next steps:"
echo "1. Edit the script: sudo nano /usr/local/bin/fan-temp-monitor-discord.sh"
echo "2. Set IDRAC_IP, IDRAC_USER, IDRAC_PASS"
echo "3. Add your Discord webhook URL (if using Discord alerts)"
echo "4. Set ENABLE_DISCORD_ALERTS=true"
echo "5. Test: /usr/local/bin/fan-temp-monitor-discord.sh"
echo ""
echo "For detailed setup, see README.md"