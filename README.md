[README.md](https://github.com/user-attachments/files/24357698/README.12.md)
# Dell PowerEdge R730XD Dynamic Fan Control

Dynamic fan controller for Dell PowerEdge R730XD using iDRAC/IPMI and a simple temperature → PWM curve.

- **Server:** Dell PowerEdge R730XD
- **iDRAC:** IPMI over LAN
- **Temp sensor:** Board sensor `0Eh`
- **Configuration:** Edit git file BEFORE copying (no corruption!)
- **Auto-restart:** Automatically restarts if failsafe triggers
- **Curve (board temp):**
  - ≤45°C → 10%
  - 46–50°C → 30%
  - 51–55°C → 50%
  - ≥60°C → 100% / AUTO failsafe

> **WARNING**: Use at your own risk. Always monitor temperatures after enabling manual fan control.

---

## ⚠️ QUICK START (3 STEPS)

### Step 1: Clone Repository
```bash
cd ~
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric
```

### Step 2: Edit Configuration BEFORE Installing (⚠️ DO THIS FIRST!)
```bash
# Edit the config file in the repo BEFORE copying to system
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
# Copy the edited config and other files
sudo cp fandynamic.conf /etc/
sudo cp fandynamic-stable.sh /root/
sudo chmod +x /root/fandynamic-stable.sh
sudo cp systemd/fandynamic.service /etc/systemd/system/

# Start the daemon
sudo systemctl daemon-reload
sudo systemctl enable fandynamic.service
sudo systemctl start fandynamic.service
sudo systemctl status fandynamic.service
```

**✅ Done!** Fans now at 10% idle (≤45°C). Check logs:
```bash
sudo tail -f /var/log/fandynamic.log
```

---

## Prerequisites

Before installing, ensure **ipmitool** is installed:

```bash
sudo apt-get update
sudo apt-get install ipmitool
```

Verify:
```bash
which ipmitool
```

---

## Configuration File Guide

Edit **`fandynamic.conf`** in the git repo before copying. No script editing needed!

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
| **RESTART_ON_AUTO** | Auto-restart on failsafe | `true` | ❌ Optional |

### Finding Your iDRAC IP

```bash
# Method 1: Check your router's DHCP client list
# Look for "idrac" or "dell" in connected devices

# Method 2: Use ping (if you know the range)
ping 192.168.40.120

# Method 3: Check Proxmox iDRAC console directly (usually port 443)
# https://192.168.X.X
```

---

## Verify Fans Working

Check current temperature and fan speeds:

```bash
# Read from config file
source /etc/fandynamic.conf

# Show all fans
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan

# Show board temperature (0Eh)
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature | grep 0Eh
```

Check daemon logs:
```bash
sudo tail -f /var/log/fandynamic.log
```

Expected output:
```
2025-12-28 12:30:15 - ===== Dell R730XD Fan Control Daemon Started =====
2025-12-28 12:30:15 - iDRAC IP: 192.168.40.120
2025-12-28 12:30:15 - Check Interval: 60s
2025-12-28 12:30:45 - Board temp: 42°C → Fans: 10% (PWM: 0x0A)
```

---

## Manage Daemon

### Check Status
```bash
sudo systemctl status fandynamic.service
```

### View Live Logs
```bash
sudo tail -f /var/log/fandynamic.log
```

### Restart Daemon
```bash
sudo systemctl restart fandynamic.service
```

### Stop Daemon (Fans go AUTO)
```bash
sudo systemctl stop fandynamic.service
```

### Start Daemon Again
```bash
sudo systemctl start fandynamic.service
```

---

## Customize Temperature Curve

Edit the config file in `/etc/`:

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

**Then restart:**
```bash
sudo systemctl restart fandynamic.service
sudo tail -f /var/log/fandynamic.log
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

# Return to AUTO
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x01
```

---

## Complete Removal

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

# Step 7: Return to iDRAC AUTO mode (use hardcoded values)
sudo ipmitool -I lanplus -H "192.168.40.120" -U "root" -P "calvin" raw 0x30 0x30 0x01 0x01

# Step 8: Verify complete removal
echo "=== Verification ==="
echo "Config file:"
ls -la /etc/fandynamic.conf 2>&1 | grep -q "No such file" && echo "✅ Removed" || echo "❌ Still exists"

echo "Script file:"
ls -la /root/fandynamic-stable.sh 2>&1 | grep -q "No such file" && echo "✅ Removed" || echo "❌ Still exists"

echo "Service file:"
ls -la /etc/systemd/system/fandynamic.service 2>&1 | grep -q "No such file" && echo "✅ Removed" || echo "❌ Still exists"

echo "Systemd status:"
sudo systemctl status fandynamic.service 2>&1 | grep -q "Unit fandynamic.service could not be found" && echo "✅ Unregistered" || echo "❌ Still registered"
```

**✅ Completely removed!** Fans are now back to iDRAC AUTO control.

> **Important:** If your iDRAC IP/credentials are different from defaults, edit the ipmitool command in Step 7 before running it.

---

## Clean Reinstall After Removal

If you want to **clean reinstall from GitHub**:

```bash
# Remove the entire git repository folder
rm -rf ~/fandynamicgeneric

# Clone fresh from GitHub
cd ~
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric

# Edit config BEFORE copying (see Step 2 above)
nano fandynamic.conf

# Then copy and install
sudo cp fandynamic.conf /etc/
sudo cp fandynamic-stable.sh /root/
sudo chmod +x /root/fandynamic-stable.sh
sudo cp systemd/fandynamic.service /etc/systemd/system/

# Start daemon
sudo systemctl daemon-reload
sudo systemctl enable fandynamic.service
sudo systemctl start fandynamic.service
```

---

## How It Works

1. **Systemd** starts `/root/fandynamic-stable.sh` at boot
2. **Script reads** `/etc/fandynamic.conf` for all settings
3. **Script reads** board temp (sensor 0Eh) every 60 seconds
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

## Troubleshooting

### Daemon won't start
```bash
sudo journalctl -u fandynamic -n 50
```

### "fandynamic.conf not found" error
Make sure you copied the file:
```bash
sudo cp fandynamic.conf /etc/
ls -la /etc/fandynamic.conf
```

### Can't connect to iDRAC
Verify your settings:
```bash
source /etc/fandynamic.conf
echo "IP: $IDRAC_IP | User: $IDRAC_USER | Pass: $IDRAC_PASS"

# Test connection
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" chassis status
```

### Fans not changing speed
Check logs:
```bash
sudo tail -20 /var/log/fandynamic.log
```

Verify config is correct:
```bash
cat /etc/fandynamic.conf | grep -E "IDRAC|TEMP"
```

### Daemon keeps restarting
Check if temp is above failsafe:
```bash
source /etc/fandynamic.conf
sudo ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature | grep 0Eh
```

To disable auto-restart:
```bash
sudo nano /etc/fandynamic.conf
# Change: RESTART_ON_AUTO="false"
sudo systemctl restart fandynamic.service
```

---

## Requirements

- **Proxmox host** with SSH access
- **ipmitool** installed: `sudo apt-get install ipmitool`
- **iDRAC access** with credentials
- **iDRAC IP address** reachable from Proxmox host

---

## Files in This Repo

| File | Purpose | Edit Before Copy? |
|------|---------|------------------|
| `fandynamic.conf` | Configuration (IPs, temps, settings) | ✅ **YES** |
| `fandynamic-stable.sh` | Main daemon script | ❌ NO |
| `systemd/fandynamic.service` | Systemd unit file | ❌ NO |
| `README.md` | This file | ❌ NO |

---

## Reusability for Other R730XD Servers

**✅ YES - Fully reusable!**

For each new server:
1. Clone the repo
2. Edit `fandynamic.conf` with new iDRAC IP/credentials
3. Copy and install

---

## License

Use at your own risk. No warranty provided.
