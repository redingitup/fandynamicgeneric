#!/bin/bash

################################################################################
# Fan Dynamic Generic - Discord Temperature Alerts
# Real-time system temperature monitoring with Discord notifications
# Works with: Dell PowerEdge R730xd, R740xd, and other servers
################################################################################

# Configuration
TEMP_THRESHOLD=75               # Alert threshold in Celsius (adjust per your system)
DISCORD_WEBHOOK_URL=""          # Set this to your Discord webhook URL
ENABLE_DISCORD_ALERTS=false     # Set to true to enable Discord alerts
CHECK_CPU_TEMP=true             # Check CPU temperature
CHECK_HBA_TEMP=true             # Check HBA330 temperature (if present)
STORCLI="/opt/MegaRAID/storcli/storcli64"

################################################################################
# Helper Functions
################################################################################

log_message() {
    local level=$1
    local message=$2
    logger -t fan-monitor "$message"
}

get_cpu_temp() {
    # Try multiple methods to get CPU temperature
    
    # Method 1: lm-sensors
    if command -v sensors &> /dev/null; then
        local temp=$(sensors 2>/dev/null | grep "Core 0" | head -1 | awk '{print $3}' | tr -d '+°C')
        if [ -n "$temp" ] && [ "$temp" != "" ]; then
            echo "$temp"
            return 0
        fi
    fi
    
    # Method 2: IPMI
    if command -v ipmitool &> /dev/null; then
        local temp=$(ipmitool sdr type temperature 2>/dev/null | head -1 | awk '{print $NF}' | tr -d 'C')
        if [ -n "$temp" ] && [ "$temp" != "" ]; then
            echo "$temp"
            return 0
        fi
    fi
    
    # Method 3: /sys/class/thermal
    if [ -d /sys/class/thermal ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)}')
        if [ -n "$temp" ] && [ "$temp" != "" ]; then
            echo "$temp"
            return 0
        fi
    fi
    
    echo ""
}

get_hba_temp() {
    if [ ! -x "$STORCLI" ]; then
        echo ""
        return 1
    fi
    
    local temp=$("${STORCLI}" /c0 show temperature 2>/dev/null | grep "ROC temperature" | awk '{print $NF}')
    echo "$temp"
}

send_discord_alert() {
    local alert_type=$1
    local current_temp=$2
    local threshold=$3
    local component=$4
    
    if [ "$ENABLE_DISCORD_ALERTS" != "true" ] || [ -z "$DISCORD_WEBHOOK_URL" ]; then
        return 0
    fi
    
    # Calculate how much over threshold
    local over_threshold=$((${current_temp%.*} - threshold))
    local color=16711680  # Red
    
    if [ $over_threshold -lt 0 ]; then
        over_threshold=0
        color=255127  # Green
    fi
    
    # Create Discord embed JSON
    local payload=$(cat <<EOF
{
  "content": "🌡️ **$component Temperature Alert**",
  "embeds": [
    {
      "title": "Temperature Threshold Exceeded",
      "description": "$component temperature monitoring alert",
      "color": $color,
      "fields": [
        {
          "name": "Current Temperature",
          "value": "${current_temp}°C",
          "inline": true
        },
        {
          "name": "Threshold",
          "value": "${threshold}°C",
          "inline": true
        },
        {
          "name": "Over Limit By",
          "value": "${over_threshold}°C",
          "inline": true
        },
        {
          "name": "Server",
          "value": "$(hostname)",
          "inline": false
        },
        {
          "name": "Time",
          "value": "$(date '+%Y-%m-%d %H:%M:%S')",
          "inline": false
        }
      ],
      "footer": {
        "text": "Fan Dynamic Generic - Temperature Monitor"
      }
    }
  ]
}
EOF
)
    
    # Send to Discord
    curl -X POST "$DISCORD_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        > /dev/null 2>&1
}

send_email_alert() {
    local current_temp=$1
    local threshold=$2
    local component=$3
    
    if ! command -v mail &> /dev/null; then
        return 1
    fi
    
    echo "ALERT: $component temperature is ${current_temp}°C (threshold: ${threshold}°C) on $(hostname)" | \
        mail -s "🌡️ Temperature Alert: $component" root
}

################################################################################
# Main Monitoring Logic
################################################################################

# Check CPU Temperature
if [ "$CHECK_CPU_TEMP" = "true" ]; then
    CPU_TEMP=$(get_cpu_temp)
    
    if [ -n "$CPU_TEMP" ]; then
        log_message "INFO" "CPU temperature: ${CPU_TEMP}°C"
        
        if [ "${CPU_TEMP%.*}" -gt "$TEMP_THRESHOLD" ]; then
            log_message "CRITICAL" "CPU temperature ${CPU_TEMP}°C exceeds threshold ${TEMP_THRESHOLD}°C"
            send_email_alert "$CPU_TEMP" "$TEMP_THRESHOLD" "CPU"
            send_discord_alert "high_temp" "$CPU_TEMP" "$TEMP_THRESHOLD" "CPU"
        fi
    fi
fi

# Check HBA Temperature
if [ "$CHECK_HBA_TEMP" = "true" ]; then
    HBA_TEMP=$(get_hba_temp)
    
    if [ -n "$HBA_TEMP" ]; then
        log_message "INFO" "HBA temperature: ${HBA_TEMP}°C"
        
        # HBA has lower threshold (55°C)
        HBA_THRESHOLD=55
        if [ "${HBA_TEMP%.*}" -gt "$HBA_THRESHOLD" ]; then
            log_message "CRITICAL" "HBA temperature ${HBA_TEMP}°C exceeds threshold ${HBA_THRESHOLD}°C"
            send_email_alert "$HBA_TEMP" "$HBA_THRESHOLD" "HBA330"
            send_discord_alert "high_temp" "$HBA_TEMP" "$HBA_THRESHOLD" "HBA330"
        fi
    fi
fi

exit 0
