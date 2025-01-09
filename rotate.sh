#!/bin/bash

# Log file for debugging
LOG_FILE="/tmp/screen-rotation.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to rotate screen and adjust input devices
rotate_screen() {
    ORIENTATION=$1
    log_message "Rotating screen to $ORIENTATION"
    
    case $ORIENTATION in
        normal)
            xrandr --output eDP-1 --rotate normal
            for device in "Wacom Pen and multitouch sensor Finger" "SynPS/2 Synaptics TouchPad" "Wacom Pen and multitouch sensor Pen Pen (0x9ecce51e)"; do
                xinput set-prop "$device" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
            done
            ;;
        right)
            xrandr --output eDP-1 --rotate right
            for device in "Wacom Pen and multitouch sensor Finger" "SynPS/2 Synaptics TouchPad" "Wacom Pen and multitouch sensor Pen Pen (0x9ecce51e)"; do
                xinput set-prop "$device" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
            done
            ;;
        left)
            xrandr --output eDP-1 --rotate left
            for device in "Wacom Pen and multitouch sensor Finger" "SynPS/2 Synaptics TouchPad" "Wacom Pen and multitouch sensor Pen Pen (0x9ecce51e)"; do
                xinput set-prop "$device" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
            done
            ;;
        inverted)
            xrandr --output eDP-1 --rotate inverted
            for device in "Wacom Pen and multitouch sensor Finger" "SynPS/2 Synaptics TouchPad" "Wacom Pen and multitouch sensor Pen Pen (0x9ecce51e)"; do
                xinput set-prop "$device" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
            done
            ;;
    esac
}

# Monitor orientation changes using iio-sensor-proxy
monitor_orientation() {
    log_message "Starting monitor-sensor..."
    
    # Kill any existing monitor-sensor processes
    pkill -f monitor-sensor
    
    # Ensure iio-sensor-proxy is running
    if ! pidof iio-sensor-proxy >/dev/null; then
        log_message "Starting iio-sensor-proxy service..."
        systemctl start iio-sensor-proxy
    fi
    
    # Wait for service to fully start
    sleep 2
    
    # Start monitoring with proper error handling
    while true; do
        monitor-sensor 2>> "$LOG_FILE" | while read -r line; do
            log_message "Sensor output: $line"
            if [[ $line == *"Accelerometer orientation changed:"* ]]; then
                orientation=$(echo "$line" | awk -F': ' '{print $2}')
                case $orientation in
                    "normal")
                        rotate_screen normal
                        ;;
                    "right-up")
                        rotate_screen right
                        ;;
                    "left-up")
                        rotate_screen left
                        ;;
                    "bottom-up")
                        rotate_screen inverted
                        ;;
                esac
            fi
        done
        
        # If monitor-sensor exits, log and restart after a brief delay
        log_message "monitor-sensor stopped, restarting in 2 seconds..."
        sleep 2
    done
}

# Cleanup function
cleanup() {
    log_message "Cleaning up..."
    pkill -f monitor-sensor
    exit 0
}

# Set up trap for clean exit
trap cleanup SIGINT SIGTERM

# Start monitoring orientation changes
monitor_orientation
