#!/bin/bash
# Proxmox Fan Control Startup Script
# Sets fan speeds to quiet levels on boot

# Wait for hardware to initialize
sleep 10

# Set case fans to manual control and quiet speed
echo 1 > /sys/class/hwmon/hwmon8/pwm2_enable
echo 100 > /sys/class/hwmon/hwmon8/pwm2
echo 1 > /sys/class/hwmon/hwmon8/pwm3_enable  
echo 100 > /sys/class/hwmon/hwmon8/pwm3

# Set GPU fan to automatic mode
echo 2 > /sys/class/drm/card1/device/hwmon/hwmon6/pwm1_enable

echo "Fan controls configured successfully"
