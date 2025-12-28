[README-main.md](https://github.com/user-attachments/files/24360435/README-main.md)
# Fan Dynamic Generic

Comprehensive Dell PowerEdge R730xd server management tools for Proxmox VE.

## 📋 What's Included

### 🌀 [Fan Control](fan-control/README.md)
Automated fan speed management based on system temperatures.

### 🌡️ [Temperature Monitoring with Discord](temperature-monitoring/README.md)
Real-time CPU and HBA330 temperature monitoring with Discord alerts.

---

## Quick Start

### Option 1: Fan Control Only
```bash
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric/fan-control
sudo bash install.sh
```

### Option 2: Temperature Monitoring Only
```bash
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric/temperature-monitoring
sudo bash install.sh
```

### Option 3: Both Tools
```bash
git clone https://github.com/redingitup/fandynamicgeneric.git
cd fandynamicgeneric

# Install fan control
cd fan-control
sudo bash install.sh

# Then install temperature monitoring
cd ../temperature-monitoring
sudo bash install.sh
```

---

## Hardware Requirements

- Dell PowerEdge R730xd
- Proxmox VE or Debian/Ubuntu
- IPMI access or lm-sensors installed
- Optional: Dell HBA330 RAID controller

---

## Features by Tool

### 🌀 Fan Control
- ✅ Automatic fan speed adjustment
- ✅ Temperature-based scaling
- ✅ Prevent thermal throttling
- ✅ Configurable thresholds

### 🌡️ Temperature Monitoring
- ✅ Real-time CPU temperature tracking
- ✅ HBA330 controller monitoring
- ✅ Discord instant alerts
- ✅ Email notifications
- ✅ Syslog integration
- ✅ Customizable thresholds

---

## System Requirements

- **OS:** Proxmox VE, Debian 11+, Ubuntu 20.04+
- **Root access:** Required for installation
- **Sensors:** lm-sensors or IPMI
- **Optional:** Mail server for email alerts
- **Optional:** Discord server for alerts

---

## Detailed Setup

For complete setup instructions, see:
- [Fan Control Setup](fan-control/README.md)
- [Temperature Monitoring Setup](temperature-monitoring/README.md)

---

## Command Reference

### Fan Control
```bash
# Check fan status
fan-status

# View logs
tail -f /var/log/syslog | grep fan-control

# Uninstall
sudo bash /opt/fandynamic/uninstall.sh
```

### Temperature Monitoring
```bash
# Run manually
/usr/local/bin/fan-temp-monitor-discord.sh

# View logs
tail -f /var/log/syslog | grep fan-monitor

# Edit configuration
sudo nano /usr/local/bin/fan-temp-monitor-discord.sh
```

---

## Compatibility

| System | Fan Control | Temp Monitor |
|--------|-------------|--------------|
| R730xd | ✅ | ✅ |
| R740xd | ✅ | ✅ |
| R750xd | ✅ | ✅ |
| Proxmox VE 7.x | ✅ | ✅ |
| Proxmox VE 8.x | ✅ | ✅ |
| Debian 11+ | ✅ | ✅ |
| Ubuntu 20.04+ | ✅ | ✅ |

---

## License

MIT License - See LICENSE file

---

## Support

For issues or questions:
1. Check the tool-specific README
2. Review troubleshooting section
3. Check system logs

---

## Credits

- StorCLI by Broadcom
- Dell PowerEdge documentation
- Tested on Proxmox VE 8.x
