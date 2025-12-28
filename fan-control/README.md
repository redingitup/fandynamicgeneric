<<<<<<< HEAD
# Fan Control for Dell PowerEdge R730xd

Automated fan speed management based on system temperatures.

## Installation

1. Edit fandynamic.conf in the folder
2. Change IDRAC_IP, IDRAC_USER, IDRAC_PASS to match your server
3. Run: sudo cp fandynamic.conf /etc/
4. Run: sudo systemctl start fandynamic.service

## License

MIT License
=======
[fan-control-README.md](https://github.com/user-attachments/files/24360477/fan-control-README.md)
# Dell PowerEdge R730XD Dynamic Fan Control

Dynamic fan controller for Dell PowerEdge R730XD using iDRAC/IPMI and a simple temperature → PWM curve.

- **Server:** Dell PowerEdge R730XD
- **iDRAC:** IPMI over LAN
- **Temp sensor:** Board sensor `0Eh` (automatically parsed)
- **Configuration:** Edit git file BEFORE copying (no corruption!)
- **Auto-restart:** Automatically restarts if failsafe triggers
- **Curve (board temp):**
  - ≤45°C → 10%
  - 46–50°C → 30%
  - 51–55°C → 50%
  - ≥60°C → 100% / AUTO failsafe

> **WARNING**: Use at your own risk. Always monitor temperatures after enabling manual fan control.

---

## 📖 Table of Contents

- **[⚠️ Quick Start](#quick-start)** - Get running in 3 steps
- **[📋 Prerequisites](#prerequisites)** - What you need before installing
- **[⚙️ Configuration](#configuration-file-guide)** - How to configure the daemon
- **[📊 Monitoring](#monitoring-commands)** - How to watch temps and fans
- **[🎛️ Management](#manage-daemon)** - Start, stop, restart, view logs
- **[🔧 Customization](#customize-temperature-curve)** - Adjust temperature thresholds
- **[🛑 Removal](#complete-removal)** - How to uninstall completely
- **[📚 Documentation](#how-it-works)** - How it all works
- **[❓ Troubleshooting](#troubleshooting)** - Common issues and fixes

---

## ⚠️ Quick Start

### Step 1: Clone Repository
```bash
cd ~
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric/fan-control
```

### Step 2: Edit Configuration BEFORE Installing
```bash
nano ../fandynamic.conf
```

**Change ONLY these 3 lines to match YOUR server:**
```bash
IDRAC_IP="192.168.40.120"      # ← Change to YOUR iDRAC IP
IDRAC_USER="root"              # ← Change to YOUR username
IDRAC_PASS="calvin"            # ← Change to YOUR password
```

**Save:** Ctrl+O → Ctrl+X

### Step 3: Copy Files & Start Daemon
```bash
sudo cp ../fandynamic.conf /etc/
sudo cp fandynamic-stable.sh /root/
sudo chmod +x /root/fandynamic-stable.sh
sudo cp fandynamic.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable fandynamic.service
sudo systemctl start fandynamic.service
sudo systemctl status fandynamic.service
```

**✅ Done!** Check logs:
```bash
sudo tail -f /var/log/fandynamic.log
```

---

## 📋 Prerequisites

Before installing, ensure **ipmitool** is installed:

```bash
sudo apt-get update
sudo apt-get install ipmitool
which ipmitool
```

---

## ⚙️ Configuration File Guide

Edit **`fandynamic.conf`** in the git repo before copying.

| Variable | What It Is | Default | Required? |
|----------|-----------|---------|-----------|
| **IDRAC_IP** | Your server's iDRAC IP | `192.168.40.120` | ✅ YES |
| **IDRAC_USER** | iDRAC username | `root` | ✅ YES |
| **IDRAC_PASS** | iDRAC password | `calvin` | ✅ YES |
| **TEMP_LOW** | Threshold for 10%→30% jump | `45` | ❌ Optional |
| **TEMP_MID** | Threshold for 30%→50% jump | `50` | ❌ Optional |
| **TEMP_HIGH** | Threshold for 50%→100% jump | `55` | ❌ Optional |
| **TEMP_FAILSAFE** | Return to AUTO failsafe | `60` | ❌ Optional |
| **CHECK_INTERVAL** | Check temp every X seconds | `60` | ❌ Optional |
| **SENSOR_ID** | iDRAC sensor ID | `0Eh` | ❌ Optional |

---

## 📊 Monitoring Commands

### Quick Temperature & Fan Check
```bash
source /etc/fandynamic.conf && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep -v " ns " && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan 2>/dev/null | grep "RPM"
```

### Setup Permanent `temps` Alias
```bash
nano ~/.bashrc
```

Add this line at the end:
```bash
alias temps='source /etc/fandynamic.conf && echo "=== TEMPERATURES ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep -v " ns " && echo "" && echo "=== FAN SPEEDS ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan 2>/dev/null | grep "RPM"'
```

Save and reload:
```bash
source ~/.bashrc
temps
```

---

## 🎛️ Manage Daemon

```bash
# Check status
sudo systemctl status fandynamic.service

# View logs
sudo tail -f /var/log/fandynamic.log

# Restart daemon
sudo systemctl restart fandynamic.service

# Start daemon
sudo systemctl start fandynamic.service
```

---

## ⛔ Stop Daemon (Fans go AUTO)

**Important:** Due to auto-restart, stopping requires 3 steps:

```bash
# Step 1: Disable auto-restart
sudo systemctl disable fandynamic.service

# Step 2: Stop the daemon
sudo systemctl stop fandynamic.service

# Step 3: Return fans to AUTO
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x01
```

When ready to resume:
```bash
sudo systemctl enable fandynamic.service
sudo systemctl start fandynamic.service
```

---

## 🔧 Customize Temperature Curve

Edit `/etc/fandynamic.conf`:

```bash
sudo nano /etc/fandynamic.conf
```

**Example: More aggressive cooling**
```bash
TEMP_LOW=40      # Jump to 30% earlier
TEMP_MID=48      # Jump to 50% earlier
TEMP_HIGH=52     # Jump to 100% earlier
TEMP_FAILSAFE=58 # Failsafe at lower temp
```

Restart:
```bash
sudo systemctl restart fandynamic.service
```

---

## 🛑 Complete Removal

Remove all daemon files and revert to iDRAC AUTO:

```bash
# Step 1: Stop and disable
sudo systemctl stop fandynamic.service
sudo systemctl disable fandynamic.service

# Step 2: Remove systemd service
sudo rm -f /etc/systemd/system/fandynamic.service

# Step 3: Remove script and config
sudo rm -f /root/fandynamic-stable.sh
sudo rm -f /etc/fandynamic.conf

# Step 4: Remove log file
sudo rm -f /var/log/fandynamic.log

# Step 5: Reload systemd
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Step 6: Return to iDRAC AUTO
sudo ipmitool -I lanplus -H "192.168.40.120" -U "root" -P "calvin" raw 0x30 0x30 0x01 0x01

# Step 7: Remove git repo
rm -rf ~/fandynamicgeneric
```

**✅ Completely removed!**

---

## 📚 How It Works

1. **Systemd** starts daemon at boot
2. **Script reads** `/etc/fandynamic.conf` for settings
3. **Reads** board temp (sensor 0Eh) every 60 seconds
4. **Maps** temp → PWM using configured curve
5. **Only changes** fans if PWM differs (prevents ramping)
6. **≥60°C** → Returns to iDRAC AUTO failsafe
7. **Waits 120s** for cooling, then restarts (if enabled)
8. **Logs** everything to `/var/log/fandynamic.log`

---

## Temperature Curve

| Board Temp | Fan Speed | PWM Value |
|-----------|-----------|-----------|
| ≤45°C | 10% | 0x0A |
| 46–50°C | 30% | 0x1E |
| 51–55°C | 50% | 0x32 |
| ≥60°C | AUTO | - |

---

## ❓ Troubleshooting

### Daemon won't start
```bash
sudo journalctl -u fandynamic -n 50
```

### Config not found
```bash
sudo cp fandynamic.conf /etc/
ls -la /etc/fandynamic.conf
```

### Can't connect to iDRAC
```bash
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" chassis status
```

### Fans not changing
```bash
sudo tail -20 /var/log/fandynamic.log
```

### Daemon keeps restarting
Check if temp is above failsafe:
```bash
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature | grep "0Eh"
```

To disable auto-restart:
```bash
sudo nano /etc/fandynamic.conf
# Change: RESTART_ON_AUTO="false"
sudo systemctl restart fandynamic.service
```

---

## License

MIT License
>>>>>>> 66f4e0df646470097001e9f6616643036f71127f
