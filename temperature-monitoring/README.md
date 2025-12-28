# Temperature Monitoring with Discord Alerts

Real-time CPU and HBA330 temperature monitoring with Discord instant alerts.

- **Server:** Dell PowerEdge R730XD
- **Monitoring:** CPU, Board, and HBA330 temperatures
- **Alerts:** Discord notifications when thresholds exceeded
- **Logging:** All alerts logged to `/var/log/temp-monitor.log`
- **Thresholds:** Warning at 50°C, Critical at 60°C

> **Note:** Discord alerts are optional. Script works standalone for logging only.

---

## 📖 Quick Start

### Step 1: Install

```bash
cd ~/fandynamicgeneric/temperature-monitoring
sudo bash install.sh
```

### Step 2: Configure (Optional - for Discord Alerts)

```bash
sudo nano /usr/local/bin/fan-temp-monitor-discord.sh
```

Edit these lines:
```bash
IDRAC_IP="192.168.40.120"         # Your iDRAC IP
IDRAC_USER="root"                 # Your iDRAC username
IDRAC_PASS="calvin"               # Your iDRAC password
DISCORD_WEBHOOK="YOUR_WEBHOOK_URL" # Leave empty if not using Discord
ENABLE_DISCORD_ALERTS="false"     # Set to "true" to enable Discord
```

### Step 3: Test

```bash
/usr/local/bin/fan-temp-monitor-discord.sh
```

You should see:
```
2025-01-29 14:30:45 - ===== Temperature Monitoring Started =====
2025-01-29 14:30:45 - iDRAC IP: 192.168.40.120
...
2025-01-29 14:30:47 - CPU: 42°C | Board: 38°C | HBA: 35°C
2025-01-29 14:30:47 - ===== Check Complete =====
```

---

## 📋 Discord Setup (Optional)

### Create Discord Webhook

1. Go to Discord server settings → **Integrations** → **Webhooks**
2. Click **New Webhook**
3. Name it: `Temperature Alerts`
4. Select channel: `#server-alerts` (or create new)
5. Click **Copy Webhook URL**

### Add Webhook to Script

```bash
sudo nano /usr/local/bin/fan-temp-monitor-discord.sh
```

Find this line:
```bash
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
```

Change to:
```bash
DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"
```

Enable Discord:
```bash
ENABLE_DISCORD_ALERTS="true"
```

Save: `Ctrl+O` → `Ctrl+X`

Test:
```bash
/usr/local/bin/fan-temp-monitor-discord.sh
```

You should see alert in Discord! 🎉

---

## ⚙️ Configuration Options

| Variable | Default | What It Does |
|----------|---------|--------------|
| `IDRAC_IP` | `192.168.40.120` | Your iDRAC IP address |
| `IDRAC_USER` | `root` | iDRAC username |
| `IDRAC_PASS` | `calvin` | iDRAC password |
| `DISCORD_WEBHOOK` | (empty) | Your Discord webhook URL |
| `ENABLE_DISCORD_ALERTS` | `false` | Enable/disable Discord alerts |
| `TEMP_WARNING` | `50` | Warning temperature threshold (°C) |
| `TEMP_CRITICAL` | `60` | Critical temperature threshold (°C) |

---

## 🚀 Run as Cron Job (Automatic Checks)

Check temperatures every 5 minutes:

```bash
crontab -e
```

Add this line:
```bash
*/5 * * * * /usr/local/bin/fan-temp-monitor-discord.sh >> /var/log/temp-monitor.log 2>&1
```

Save: `Ctrl+O` → `Ctrl+X`

---

## 📊 View Logs

```bash
# Last 20 lines
tail -20 /var/log/temp-monitor.log

# Follow in real-time
tail -f /var/log/temp-monitor.log

# Search for alerts
grep "WARNING\|CRITICAL" /var/log/temp-monitor.log
```

---

## 🆘 Troubleshooting

### Can't connect to iDRAC

```bash
# Test connection
ipmitool -I lanplus -H 192.168.40.120 -U root -P calvin chassis status
```

If it fails:
- Check iDRAC IP is correct
- Check username/password
- Check network connectivity

### No temperatures showing

```bash
# Check sensors available
ipmitool -I lanplus -H 192.168.40.120 -U root -P calvin sdr type Temperature
```

### Discord webhook not working

1. Verify webhook URL is correct
2. Check `ENABLE_DISCORD_ALERTS="true"`
3. Check curl is installed: `which curl`
4. Test webhook manually: `curl -X POST https://your-webhook-url -H 'Content-Type: application/json' -d '{"content":"test"}'`

---

## 📦 Requirements

- **ipmitool** installed: `sudo apt-get install ipmitool`
- **curl** installed: `sudo apt-get install curl` (for Discord alerts)
- **iDRAC access** with IP, username, password
- **Discord account** (optional, for alerts)

---

## 🛑 Uninstall

```bash
sudo rm -f /usr/local/bin/fan-temp-monitor-discord.sh
sudo rm -f /var/log/temp-monitor.log

# Remove from cron if added
crontab -e
# Delete the line you added
```

---

## License

MIT License