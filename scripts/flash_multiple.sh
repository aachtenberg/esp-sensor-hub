#!/bin/bash
# Flash multiple ESP8266 devices with the same firmware

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="${1:-nodemcuv2}"

echo "================================"
echo "Multi-Device ESP8266 Flasher"
echo "================================"
echo ""

# List available devices
echo "Available USB Serial Devices:"
ls -1 /dev/ttyUSB* 2>/dev/null || {
    echo "❌ No USB serial devices found!"
    exit 1
}

echo ""
echo "Options:"
echo "  1) Flash all devices (sequential)"
echo "  2) Flash specific device"
echo "  3) Exit"
echo ""
read -p "Choose option (1-3): " choice

case $choice in
    1)
        devices=($(ls -1 /dev/ttyUSB* 2>/dev/null))
        if [ ${#devices[@]} -eq 0 ]; then
            echo "❌ No devices found"
            exit 1
        fi
        
        echo ""
        echo "📋 Will flash ${#devices[@]} device(s):"
        for i in "${!devices[@]}"; do
            echo "  $((i+1)). ${devices[$i]}"
        done
        
        read -p "Proceed? (yes/no): " confirm
        [ "$confirm" != "yes" ] && exit 0
        
        for device in "${devices[@]}"; do
            echo ""
            echo "================================"
            echo "Flashing: $device"
            echo "================================"
            cd "$PROJECT_DIR"
            platformio run --target upload -e "$ENV" --upload-port "$device" 2>&1
            if [ $? -eq 0 ]; then
                echo "✅ $device flashed successfully"
                if [ "$device" != "${devices[-1]}" ]; then
                    read -p "Connect next device and press Enter..."
                fi
            else
                echo "❌ Failed to flash $device"
            fi
        done
        ;;
    2)
        read -p "Enter device port (e.g., /dev/ttyUSB0): " port
        if [ ! -e "$port" ]; then
            echo "❌ Device not found: $port"
            exit 1
        fi
        
        echo ""
        echo "================================"
        echo "Flashing: $port"
        echo "================================"
        cd "$PROJECT_DIR"
        platformio run --target upload -e "$ENV" --upload-port "$port" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully flashed $port"
        else
            echo "❌ Failed to flash $port"
            exit 1
        fi
        ;;
    3)
        echo "Exiting"
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "================================"
echo "✅ All devices flashed!"
echo "================================"
