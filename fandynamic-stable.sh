#!/bin/bash

# Dell PowerEdge R730XD Dynamic Fan Control
# Reads configuration from /etc/fandynamic.conf
# No hardcoded values - fully configurable!
# Includes auto-restart on failsafe detection

set -e

# Close stdin immediately - no interactive input allowed
exec 0<&-

# Redirect all output to log file (prevents systemd from waiting for it)
LOG_FILE="/var/log/fandynamic.log"
exec 1>>"$LOG_FILE" 2>&1

# Load configuration from /etc/fandynamic.conf
if [ ! -f /etc/fandynamic.conf ]; then
    echo "ERROR: /etc/fandynamic.conf not found!"
    echo "Please copy fandynamic.conf to /etc/ and customize it."
    exit 1
fi

source /etc/fandynamic.conf

# Validate required settings
if [ -z "$IDRAC_IP" ] || [ -z "$IDRAC_USER" ] || [ -z "$IDRAC_PASS" ]; then
    echo "ERROR: IDRAC_IP, IDRAC_USER, or IDRAC_PASS not set in /etc/fandynamic.conf"
    exit 1
fi

# Set defaults if not specified
CHECK_INTERVAL=${CHECK_INTERVAL:-60}
TEMP_LOW=${TEMP_LOW:-45}
TEMP_MID=${TEMP_MID:-50}
TEMP_HIGH=${TEMP_HIGH:-55}
TEMP_FAILSAFE=${TEMP_FAILSAFE:-60}
SENSOR_ID=${SENSOR_ID:-0Eh}
RESTART_ON_AUTO=${RESTART_ON_AUTO:-true}
IPMITOOL_TIMEOUT=${IPMITOOL_TIMEOUT:-10}  # 10 second timeout for ipmitool

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "===== Dell R730XD Fan Control Daemon Started ====="
log "iDRAC IP: $IDRAC_IP"
log "Check Interval: ${CHECK_INTERVAL}s"
log "ipmitool Timeout: ${IPMITOOL_TIMEOUT}s"
log "Temperature Curve: $TEMP_LOW/$TEMP_MID/$TEMP_HIGH°C (failsafe: $TEMP_FAILSAFE°C)"
log "Auto-restart on AUTO: $RESTART_ON_AUTO"

# Initialize
LAST_PWM=""
LOOP_COUNT=0

# Trap signals for clean shutdown
trap 'log "Daemon interrupted, exiting cleanly..."; exit 0' SIGTERM SIGINT

# Main daemon loop
while true; do
    LOOP_COUNT=$((LOOP_COUNT + 1))

    # Get current board temperature with timeout
    BOARD_TEMP=$(timeout "$IPMITOOL_TIMEOUT" ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" sdr type Temperature 2>/dev/null | grep "$SENSOR_ID" | grep -oP '\d+(?=\s+degrees)' | head -1)

    if [ -z "$BOARD_TEMP" ]; then
        log "ERROR: Could not read board temperature from iDRAC (timeout after ${IPMITOOL_TIMEOUT}s)"
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # Determine target PWM based on temperature
    if [ "$BOARD_TEMP" -ge "$TEMP_FAILSAFE" ]; then
        log "FAILSAFE: Board temp $BOARD_TEMP°C >= $TEMP_FAILSAFE°C, returning to AUTO"
        timeout "$IPMITOOL_TIMEOUT" ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x01 || log "WARNING: ipmitool timeout during failsafe"

        # Auto-restart logic: Wait for cooling, then restart
        if [ "$RESTART_ON_AUTO" = "true" ]; then
            log "Waiting 120 seconds for temp to cool before restarting fan control daemon..."
            sleep 120
            log "Restarting fan control daemon..."
            exit 0  # Exit cleanly - systemd will restart it
        fi
    elif [ "$BOARD_TEMP" -le "$TEMP_LOW" ]; then
        TARGET_PWM="0x0A"  # 10%
    elif [ "$BOARD_TEMP" -le "$TEMP_MID" ]; then
        TARGET_PWM="0x1E"  # 30%
    elif [ "$BOARD_TEMP" -le "$TEMP_HIGH" ]; then
        TARGET_PWM="0x32"  # 50%
    else
        TARGET_PWM="0x64"  # 100%
    fi

    # Only change fans if PWM differs from last cycle (prevents ramping)
    if [ "$TARGET_PWM" != "$LAST_PWM" ]; then
        if [ "$TARGET_PWM" != "AUTO" ]; then
            PWM_PERCENT=$((16#${TARGET_PWM:2}))
            PWM_PERCENT=$((PWM_PERCENT * 100 / 255))
            log "Board temp: $BOARD_TEMP°C → Fans: $PWM_PERCENT% (PWM: $TARGET_PWM)"
            timeout "$IPMITOOL_TIMEOUT" ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x01 0x00 || log "WARNING: ipmitool timeout setting manual mode"
            timeout "$IPMITOOL_TIMEOUT" ipmitool -I lanplus -H "$IDRAC_IP" -U "$IDRAC_USER" -P "$IDRAC_PASS" raw 0x30 0x30 0x02 0xff "$TARGET_PWM" || log "WARNING: ipmitool timeout setting PWM"
        fi
        LAST_PWM="$TARGET_PWM"
    fi

    sleep "$CHECK_INTERVAL"
done
