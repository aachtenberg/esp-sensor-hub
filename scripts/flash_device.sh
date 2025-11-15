#!/bin/bash
# Flash ESP device (ESP8266 or ESP32) with specific location name
# Usage: ./flash_device.sh "Device Location" [board_type]
# board_type: esp8266 or esp32 (default: esp32)

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCATION="${1:-}"
BOARD="${2:-esp32}"

# Validate board type
if [ "$BOARD" != "esp8266" ] && [ "$BOARD" != "esp32" ]; then
    echo "❌ Invalid board type: $BOARD"
    echo "Valid options: esp8266, esp32"
    exit 1
fi

if [ -z "$LOCATION" ]; then
    echo "Usage: $0 'Device Location' [board_type]"
    echo ""
    echo "Examples:"
    echo "  $0 'Big Garage' esp32"
    echo "  $0 'Bedroom' esp8266"
    echo "  $0 'Living Room'  # defaults to esp32"
    echo ""
    exit 1
fi

# Map board type to PlatformIO environment
if [ "$BOARD" = "esp8266" ]; then
    ENV="esp8266"
else
    ENV="esp32dev"
fi

echo "================================"
echo "ESP Temperature Sensor"
echo "Device Flasher with Location"
echo "================================"
echo ""
echo "Device Location: $LOCATION"
echo "Board Type: $BOARD"
echo "Environment: $ENV"
echo ""

# Update device_config.h with location
echo "Updating device configuration..."
sed -i "s/static const char\* DEVICE_LOCATION = \".*\"/static const char* DEVICE_LOCATION = \"$LOCATION\"/" "$PROJECT_DIR/include/device_config.h"

# Update device_config.h with board type
sed -i "s/static const char\* DEVICE_BOARD = \".*\"/static const char* DEVICE_BOARD = \"$BOARD\"/" "$PROJECT_DIR/include/device_config.h"

if grep -q "DEVICE_LOCATION = \"$LOCATION\"" "$PROJECT_DIR/include/device_config.h"; then
    echo "✅ Configuration updated: DEVICE_LOCATION = \"$LOCATION\""
    echo "✅ Configuration updated: DEVICE_BOARD = \"$BOARD\""
else
    echo "❌ Failed to update configuration"
    exit 1
fi

echo ""
echo "================================"
echo "Building firmware..."
echo "================================"
cd "$PROJECT_DIR"
platformio run -e "$ENV" 2>&1 | tail -5

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "================================"
echo "Checking for device..."
echo "================================"

PORTS=($(ls /dev/ttyUSB* 2>/dev/null))

if [ ${#PORTS[@]} -eq 0 ]; then
    echo "❌ No USB device found!"
    echo "Connect ESP device and try again"
    exit 1
fi

if [ ${#PORTS[@]} -eq 1 ]; then
    PORT="${PORTS[0]}"
    echo "✅ Found device: $PORT"
else
    echo "Found multiple devices:"
    for i in "${!PORTS[@]}"; do
        echo "  $((i+1)). ${PORTS[$i]}"
    done
    echo ""
    read -p "Select device number: " num
    PORT="${PORTS[$((num-1))]}"
fi

echo ""
echo "================================"
echo "Uploading firmware..."
echo "Device: $LOCATION ($BOARD)"
echo "Port: $PORT"
echo "================================"
platformio run --target upload -e "$ENV" --upload-port "$PORT" 2>&1 | tail -10

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Device flashed with location: $LOCATION ($BOARD)"
    echo ""
    read -p "Monitor serial output? (y/n): " monitor
    if [ "$monitor" = "y" ]; then
        echo ""
        echo "Opening serial monitor (Ctrl+C to exit)..."
        sleep 2
        platformio device monitor -p "$PORT" -b 115200
    fi
else
    echo ""
    echo "❌ Upload failed"
    exit 1
fi
