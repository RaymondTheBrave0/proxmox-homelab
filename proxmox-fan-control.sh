#!/bin/bash
# Proxmox Fan Control Script with Dynamic Path Detection
# Safely controls Corsair case fans without touching GPU fan

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Wait for hardware to initialize
log_message "Waiting for hardware initialization..."
sleep 10

# Find the it87 hwmon device dynamically
IT87_HWMON=""
for hwmon in /sys/class/hwmon/hwmon*; do
    if [ -f "$hwmon/name" ]; then
        name=$(cat "$hwmon/name")
        if [[ "$name" == "it8792" ]] || [[ "$name" == "it87" ]]; then
            IT87_HWMON="$hwmon"
            log_message "Found IT87 controller at: $IT87_HWMON"
            break
        fi
    fi
done

if [ -z "$IT87_HWMON" ]; then
    log_message "ERROR: Could not find IT87 fan controller"
    exit 1
fi

# Function to set fan speed safely
set_fan_speed() {
    local pwm_num=$1
    local speed=$2
    local pwm_enable="${IT87_HWMON}/pwm${pwm_num}_enable"
    local pwm_value="${IT87_HWMON}/pwm${pwm_num}"
    
    if [ -f "$pwm_enable" ] && [ -f "$pwm_value" ]; then
        # Set to manual mode (1)
        echo 1 > "$pwm_enable" 2>/dev/null
        if [ $? -eq 0 ]; then
            # Set speed (0-255, where 255 is max)
            echo "$speed" > "$pwm_value" 2>/dev/null
            if [ $? -eq 0 ]; then
                log_message "PWM${pwm_num} set to ${speed}/255 ($(( speed * 100 / 255 ))%)"
            else
                log_message "WARNING: Could not set PWM${pwm_num} speed"
            fi
        else
            log_message "WARNING: Could not enable manual control for PWM${pwm_num}"
        fi
    else
        log_message "INFO: PWM${pwm_num} not available"
    fi
}

# Set case fans to quiet speeds
# PWM values: 0=off, 255=max speed
# 100/255 = ~39% speed (quiet operation)
log_message "Configuring case fan speeds..."

# Check which fans are actually connected
for i in 1 2 3; do
    fan_input="${IT87_HWMON}/fan${i}_input"
    if [ -f "$fan_input" ]; then
        rpm=$(cat "$fan_input" 2>/dev/null)
        if [ "$rpm" != "0" ]; then
            log_message "Fan${i} detected: ${rpm} RPM"
            set_fan_speed $i 100
        else
            log_message "Fan${i} not connected or 0 RPM"
        fi
    fi
done

# Display current temperatures
log_message "Current system temperatures:"
if command -v sensors >/dev/null 2>&1; then
    sensors | grep -E "(temp|°C)" | while read line; do
        log_message "  $line"
    done
fi

# IMPORTANT: Not touching GPU fan to avoid max speed issue
log_message "GPU fan control: Left at default (not modified to prevent max speed issue)"

log_message "Fan control configuration completed successfully"
