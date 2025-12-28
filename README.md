# README
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
- **[📦 Requirements](#requirements)** - System requirements
- **[📄 License](#license)** - License information

---

## ⚠️ Quick Start

### Step 1: Clone Repository
```bash
cd ~
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric
```

### Step 2: Edit Configuration BEFORE Installing (⚠️ DO THIS FIRST!)
```bash
nano fandynamic.conf
```

**Change ONLY these 3 lines to match YOUR server:**
```bash
IDRAC_IP="192.168.40.120"      # ← Change to YOUR iDRAC IP
IDRAC_USER="root"              # ← Change to YOUR username (if not "root")
IDRAC_PASS="calvin"            # ← Change to YOUR password (if not "calvin")
```

**Save:** `Ctrl+O` → `Ctrl+X`

### Step 3: Copy Files & Start Daemon
```bash
sudo cp fandynamic.conf /etc/
sudo cp fandynamic-stable.sh /root/
sudo chmod +x /root/fandynamic-stable.sh
sudo cp systemd/fandynamic.service /etc/systemd/system/

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
| **RESTART_ON_AUTO** | Auto-restart on failsafe | `true` | ❌ Optional |
| **IPMITOOL_TIMEOUT** | Max seconds to wait for ipmitool | `10` | ❌ Optional |

### Finding Your iDRAC IP
```bash
ping 192.168.40.120
# Or check your router's DHCP client list for "idrac" or "dell"
```

---

## 📊 Monitoring Commands

---

### TEMPORARY: One-Time Check (Single Command, No Setup)

**Use this right now without any setup:**
```bash
source /etc/fandynamic.conf && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep -v " ns " && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan 2>/dev/null | grep "RPM"
```

Shows temperatures and fan speeds. Good for quick checks.

---

### PERSISTENT: Alias `temps` (Survives Reboot - Add to ~/.bashrc)

**To make `temps` work forever (even after reboot):**

Edit your ~/.bashrc:
```bash
nano ~/.bashrc
```

Add this line at the end:
```bash
alias temps='source /etc/fandynamic.conf && echo "=== TEMPERATURES ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep -v " ns " && echo "" && echo "=== FAN SPEEDS ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan 2>/dev/null | grep "RPM"'
```

Save: `Ctrl+O` → `Ctrl+X`

Reload:
```bash
source ~/.bashrc
```

Now `temps` works forever in every new terminal! 🎉

**Output:**
```
=== TEMPERATURES ===
Inlet Temp       | 04h | ok | 7.1 | 20 degrees C
Exhaust Temp     | 01h | ok | 7.1 | 34 degrees C
Temp             | 0Eh | ok | 3.1 | 42 degrees C

=== FAN SPEEDS ===
Fan1 RPM         | 30h | ok | 7.1 | 3360 RPM
Fan2 RPM         | 31h | ok | 7.1 | 3360 RPM
...
```

---

### TEMPORARY: Live Monitoring (Auto-Refreshes Every 5 Seconds)

**Use this one-liner (no setup needed, exits with `Ctrl+C`):**
```bash
watch -n 5 'source /etc/fandynamic.conf && echo "=== TEMPERATURES ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep -v " ns " && echo "" && echo "=== FAN SPEEDS ===" && sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan 2>/dev/null | grep "RPM"'
```

- **Exit**: `Ctrl+C`
- **Refreshes**: Every 5 seconds automatically

---

### PERSISTENT: Alias `tempwatch` (Survives Reboot - Add to ~/.bashrc)

**To make live monitoring permanent:**

Edit:
```bash
nano ~/.bashrc
```

Add this line:
```bash
alias tempwatch='watch -n 5 "source /etc/fandynamic.conf && echo \"=== TEMPERATURES ===\" && sudo ipmitool -I lanplus -H \"\$IDRAC_IP\" -U \"\$IDRAC_USER\" -P \"\$IDRAC_PASS\" sdr type Temperature 2>/dev/null | grep -v \" ns \" && echo \"\" && echo \"=== FAN SPEEDS ===\" && sudo ipmitool -I lanplus -H \"\$IDRAC_IP\" -U \"\$IDRAC_USER\" -P \"\$IDRAC_PASS\" sdr type Fan 2>/dev/null | grep \"RPM\""'
```

Save and reload:
```bash
source ~/.bashrc
```

Now just type:
```bash
tempwatch
```

---

### Quick Comparison

| Command | Lasts Until | Best For |
|---------|-------------|----------|
| One-liner | One run | Quick one-time check |
| `temps` alias (bash) | Forever (reboot-safe) | Permanent quick checks |
| `watch` one-liner | Until `Ctrl+C` | Live monitoring once |
| `tempwatch` alias | Forever (reboot-safe) | Permanent live monitoring |

---

## 🎛️ Manage Daemon

```bash
# Check status
sudo systemctl status fandynamic.service

# View logs
sudo tail -f /var/log/fandynamic.log

# Restart daemon
sudo systemctl restart fandynamic.service

# Stop daemon (fans go AUTO)
sudo systemctl stop fandynamic.service

# Start daemon again
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

Then restart:
```bash
sudo systemctl restart fandynamic.service
```

---

## Auto-Restart on Failsafe

When temperature exceeds `TEMP_FAILSAFE`:
1. Daemon returns fans to iDRAC AUTO control
2. Waits 120 seconds for cooling
3. Cleanly exits
4. Systemd automatically restarts it
5. Fan control resumes

To **disable** auto-restart:
```bash
sudo nano /etc/fandynamic.conf
# Change: RESTART_ON_AUTO="false"
sudo systemctl restart fandynamic.service
```

---

## Disable & Revert to AUTO

Stop the daemon and return fans to iDRAC AUTO mode:

```bash
sudo systemctl stop fandynamic.service
sudo systemctl disable fandynamic.service

source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x01
```

---

## 🛑 Complete Removal

Remove all daemon files and revert to iDRAC AUTO control permanently:

```bash
# Step 1: Stop and disable daemon
sudo systemctl stop fandynamic.service
sudo systemctl disable fandynamic.service

# Step 2: Wait a moment for graceful shutdown
sleep 2

# Step 3: Remove systemd service file
sudo rm -f /etc/systemd/system/fandynamic.service

# Step 4: Remove script and config
sudo rm -f /root/fandynamic-stable.sh
sudo rm -f /etc/fandynamic.conf

# Step 5: Remove log file
sudo rm -f /var/log/fandynamic.log

# Step 6: Reload systemd to clear cache
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Step 7: Return to iDRAC AUTO mode
sudo ipmitool -I lanplus -H "192.168.40.120" -U "root" -P "calvin" raw 0x30 0x30 0x01 0x01

# Step 8: Remove git repository folder
rm -rf ~/fandynamicgeneric

# Step 9: Verify removal
echo "=== Verification ==="
ls -la /etc/fandynamic.conf 2>&1 | grep -q "No such file" && echo "✅ Config removed" || echo "❌ Config still exists"
ls -la /root/fandynamic-stable.sh 2>&1 | grep -q "No such file" && echo "✅ Script removed" || echo "❌ Script still exists"
ls -la ~/fandynamicgeneric 2>&1 | grep -q "No such file" && echo "✅ Git repo removed" || echo "❌ Git repo still exists"
```

**✅ Completely removed!** Fans are back to iDRAC AUTO control.

> **Note:** If your iDRAC IP/credentials are different from defaults, edit the ipmitool command in Step 7 before running it.

---

## 📚 How It Works

1. **Systemd** starts `/root/fandynamic-stable.sh` at boot
2. **Script reads** `/etc/fandynamic.conf` for all settings
3. **Script reads** board temp (sensor 0Eh) every 60 seconds with smart parsing
4. **Maps temp** → PWM using configured curve
5. **Only changes** fans if PWM differs (prevents ramping)
6. **≥60°C** → Automatically returns control to iDRAC AUTO failsafe
7. **Waits 120s** for cooling, then restarts daemon (if enabled)
8. **Logs everything** to `/var/log/fandynamic.log`

---

## Temperature Curve Details

| Board Temp | Fan Speed | PWM Value | Notes |
|-----------|-----------|-----------|-------|
| ≤45°C | 10% | 0x0A | LOCKED - no ramping |
| 46–50°C | 30% | 0x1E | One-time change |
| 51–55°C | 50% | 0x32 | One-time change |
| ≥60°C | AUTO | - | Failsafe |

---

## ❓ Troubleshooting

### Daemon won't start
```bash
sudo journalctl -u fandynamic -n 50
```

### "fandynamic.conf not found" error
```bash
sudo cp fandynamic.conf /etc/
ls -la /etc/fandynamic.conf
```

### Can't connect to iDRAC
```bash
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" chassis status
```

### Fans not changing speed
```bash
sudo tail -20 /var/log/fandynamic.log
cat /etc/fandynamic.conf | grep -E "IDRAC|TEMP|SENSOR"
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

## 📦 Requirements

- **Proxmox host** with SSH access
- **ipmitool** installed: `sudo apt-get install ipmitool`
- **iDRAC access** with credentials
- **iDRAC IP address** reachable from Proxmox host

---

## Files in This Repo

| File | Purpose |
|------|---------|
| `fandynamic.conf` | Configuration (edit before copying) |
| `fandynamic-stable.sh` | Main daemon script |
| `systemd/fandynamic.service` | Systemd unit file |
| `UPDATE_GUIDE.md` | v1.5 update guide and changelog |
| `README.md` | This file |

---

## Reusability for Other R730XD Servers

For each new server:
1. Clone the repo
2. Edit `fandynamic.conf` with new iDRAC IP/credentials
3. Copy and install

---

## Changelog

- **v1.5** - Fixed systemctl stop hanging; added timeout to ipmitool; added signal handlers; closed stdin
- **v1.4** - Simplified monitoring commands; removed complex alignment
- **v1.3** - Filtered disabled sensors (ns status) and limited output to 3 temperatures; reordered temps to Board/Inlet/Exhaust; improved alignment
- **v1.2** - Fixed temperature grep pattern for `Temp` vs `Board Temp` label variations; added sed to rename `Temp` to `Board Temp` in output
- **v1.1** - Fixed sensor `0Eh` parsing; added SENSOR_ID config; improved error handling
- **v1.0** - Initial release

---

## 📄 License

Use at your own risk. No warranty provided.
