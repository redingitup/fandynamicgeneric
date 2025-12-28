[README.md](https://github.com/user-attachments/files/24357556/README.8.md)
# Dell PowerEdge R730XD Dynamic Fan Control

Dynamic fan controller for Dell PowerEdge R730XD using iDRAC/IPMI and a simple temperature → PWM curve.

- **Server:** Dell PowerEdge R730XD
- **iDRAC:** IPMI over LAN
- **Temp sensor:** Board sensor `0Eh`
- **Configuration:** External `.conf` file (no script editing needed!)
- **Curve (board temp):**
  - ≤45°C → 10%
  - 46–50°C → 30%
  - 51–55°C → 50%
  - ≥60°C → 100% / AUTO failsafe

> **WARNING**: Use at your own risk. Always monitor temperatures after enabling manual fan control.

---

## ⚠️ QUICK START (3 STEPS)

### Step 1: Clone & Copy Files
```bash
cd ~
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric
cp fandynamic.conf /etc/
cp fandynamic-stable.sh /root/
chmod +x /root/fandynamic-stable.sh
cp systemd/fandynamic.service /etc/systemd/system/
```

### Step 2: Edit Configuration (⚠️ DO THIS!)
```bash
nano /etc/fandynamic.conf
```

**Edit ONLY these 3 lines:**
```bash
IDRAC_IP="192.168.40.120"      # ← Change to YOUR iDRAC IP
IDRAC_USER="root"              # ← Change to YOUR username (if not "root")
IDRAC_PASS="calvin"            # ← Change to YOUR password (if not "calvin")
```

**Save:** `Ctrl+O` → `Ctrl+X`

### Step 3: Start Daemon
```bash
systemctl daemon-reload
systemctl enable fandynamic.service
systemctl start fandynamic.service
systemctl status fandynamic.service
```

**✅ Done!** Fans now at 10% idle (≤45°C). Check logs:
```bash
tail -f /var/log/fandynamic.log
```

---

## Prerequisites

Before installing, ensure **ipmitool** is installed:

```bash
apt-get update
apt-get install ipmitool
```

Verify:
```bash
which ipmitool
```

---

## Configuration File Guide

The **`/etc/fandynamic.conf`** file is where you customize everything. No script editing needed!

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
ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Fan

# Show board temperature (0Eh)
ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature | grep 0Eh
```

Check daemon logs:
```bash
tail -f /var/log/fandynamic.log
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
systemctl status fandynamic.service
```

### View Live Logs
```bash
tail -f /var/log/fandynamic.log
```

### Restart Daemon
```bash
systemctl restart fandynamic.service
```

### Stop Daemon (Fans go AUTO)
```bash
systemctl stop fandynamic.service
```

---

## Customize Temperature Curve

Edit `/etc/fandynamic.conf` and change these values:

```bash
nano /etc/fandynamic.conf
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
systemctl restart fandynamic.service
tail -f /var/log/fandynamic.log
```

---

## Disable & Revert to AUTO

Return control to iDRAC AUTO mode:

```bash
systemctl stop fandynamic.service
systemctl disable fandynamic.service

# Return to AUTO
source /etc/fandynamic.conf
ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x01
```

---

## How It Works

1. **Systemd** starts `/root/fandynamic-stable.sh` at boot
2. **Script reads** `/etc/fandynamic.conf` for all settings
3. **Script reads** board temp (sensor 0Eh) every 60 seconds
4. **Maps temp** → PWM using configured curve
5. **Only changes** fans if PWM differs (prevents ramping)
6. **≥60°C** → Automatically returns control to iDRAC AUTO failsafe
7. **Logs everything** to `/var/log/fandynamic.log`

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
journalctl -u fandynamic -n 50
```

### "fandynamic.conf not found" error
Make sure you copied the file:
```bash
cp fandynamic.conf /etc/
ls -la /etc/fandynamic.conf
```

### Can't connect to iDRAC
Verify your settings:
```bash
source /etc/fandynamic.conf
echo "IP: $IDRAC_IP | User: $IDRAC_USER | Pass: $IDRAC_PASS"

# Test connection
ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" chassis status
```

### Fans not changing speed
Check logs:
```bash
tail -20 /var/log/fandynamic.log
```

Verify config is correct:
```bash
cat /etc/fandynamic.conf | grep -E "IDRAC|TEMP"
```

---

## Requirements

- **Proxmox host** with SSH access
- **ipmitool** installed: `apt-get install ipmitool`
- **iDRAC access** with credentials
- **iDRAC IP address** reachable from Proxmox host

---

## Files in This Repo

| File | Purpose | Needs Editing? |
|------|---------|----------------|
| `fandynamic.conf` | Configuration (IPs, temps, settings) | ✅ **YES** |
| `fandynamic-stable.sh` | Main daemon script | ❌ NO |
| `systemd/fandynamic.service` | Systemd unit file | ❌ NO |
| `README.md` | This file | ❌ NO |

---

## Reusability for Other R730XD Servers

**✅ YES - Fully reusable!**

Simply edit `/etc/fandynamic.conf` with different server settings. The script is generic and works on any R730XD.

**For another server, just:**
```bash
nano /etc/fandynamic.conf
# Change IDRAC_IP, IDRAC_USER, IDRAC_PASS
systemctl restart fandynamic.service
```

---

## License

Use at your own risk. No warranty provided.
