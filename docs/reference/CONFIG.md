# Configuration Reference

## Required Files

### secrets.h Setup
Create `temperature-sensor/include/secrets.h` (excluded from git):
```cpp
#ifndef SECRETS_H
#define SECRETS_H

// MQTT Configuration
static const char* MQTT_BROKER = "your.mqtt.broker.com";  // e.g., "mosquitto.local" or LAN hostname
static const int MQTT_PORT = 1883;
static const char* MQTT_USER = "";        // Empty if no authentication
static const char* MQTT_PASSWORD = "";    // Empty if no authentication

// WiFi Configuration (also set via WiFiManager portal)
static const char* WIFI_SSID = "";        // Leave empty to use portal
static const char* WIFI_PASSWORD = "";    // Leave empty to use portal

#endif
```

### WiFi Configuration
**WiFi credentials configured via WiFiManager portal - no compile-time setup needed!**

1. Device creates AP "ESP-Setup" (password: "configure") 
2. Connect to AP and open the WiFiManager captive portal (e.g., http://esp-setup.local)
3. Enter WiFi credentials and device name
4. Device saves config and connects automatically

## Deployment Commands

### Flash Single Device
```bash
# Temperature sensor
./scripts/flash_device.sh temp

# Solar monitor  
./scripts/flash_device.sh solar

# Surveillance camera
./scripts/flash_device.sh surveillance
```

### Flash Multiple Devices
```bash
# Temperature sensors
python3 scripts/flash_multiple.py --project temp

# Solar monitors
python3 scripts/flash_multiple.py --project solar
```

### Monitor Device
```bash
# Serial output
platformio device monitor -b 115200

# Web interface (after WiFi connection)
curl http://DEVICE_IP
```

## WSL2 USB Setup (Windows Users)

USB devices require Windows-side attachment using `usbipd`:

```powershell
# Run in Windows PowerShell as Administrator
usbipd list  # Find your device BUSID (e.g., 2-11)
usbipd bind --busid 2-11  # One-time share
usbipd attach --wsl --busid 2-11  # Connect to WSL
```

## Data Queries

### Monitor MQTT Temperature Stream
```bash
mosquitto_sub -h your.mqtt.broker.com -t "esp-sensor-hub/+/temperature" -v
```

### Monitor Device Status (Retained Messages)
```bash
mosquitto_sub -h your.mqtt.broker.com -t "esp-sensor-hub/+/status" -R -v
```

### Monitor Device Events
```bash
mosquitto_sub -h your.mqtt.broker.com -t "esp-sensor-hub/+/events" -v
```

### Example MQTT Payloads
**Temperature message**:
```json
{
  "device": "Small Garage",
  "chip_id": "3C61053ED814",
  "timestamp": 65,
  "celsius": 21.12,
  "fahrenheit": 70.03
}
```

**Status message** (retained, refreshed every 30s):
```json
{
  "device": "Small Garage",
  "chip_id": "3C61053ED814",
  "timestamp": 65,
  "uptime_seconds": 65,
  "wifi_connected": true,
  "wifi_rssi": -63,
  "free_heap": 239812,
  "sensor_healthy": true,
  "wifi_reconnects": 0,
  "sensor_read_failures": 0
}
```

### Query InfluxDB (Optional Bridge)
If Telegraf bridge is running to sync MQTT → InfluxDB v3:
```flux
from(bucket: "sensor_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> filter(fn: (r) => r.device == "Small Garage")
```

## Troubleshooting

### Device Won't Connect to MQTT
1. Check serial output for MQTT connection status
2. Verify broker IP and port in secrets.h (e.g., your.mqtt.broker.com:1883)
3. Confirm MQTT broker is running and accessible from network
4. Check device WiFi connection first (`[MQTT] Not connected, skipping publish`)

### Device Won't Connect to WiFi
1. Check serial output for WiFi status
2. Ensure correct SSID/password via WiFiManager portal
3. Device creates "ESP-Setup" AP for reconfiguration
4. Factory reset: hold reset during power-on

### MQTT Payloads Not Appearing
1. Verify device has WiFi connection (`wifi_connected: true` in status)
2. Check MQTT broker is receiving: `mosquitto_sub -h your.mqtt.broker.com -t "esp-sensor-hub/#" -v`
3. Monitor device serial for publish status: `[MQTT] Publishing to ... Publish successful`
4. Check heap memory isn't exhausted (`free_heap` in status message)

### MQTT Buffer Size Issues
**Symptom**: Device reports successful MQTT publishes but messages don't appear in broker

**Root Cause**: PubSubClient default buffer (128 bytes) too small for JSON payloads (~350+ bytes)

**Solution**: PlatformIO environments include increased buffer sizes:
- **ESP32**: `-D MQTT_MAX_PACKET_SIZE=2048` (increased from 512 for large payloads with battery monitoring)
- **ESP8266**: `-D MQTT_MAX_PACKET_SIZE=512` (sufficient for smaller payloads)

**Symptoms of Buffer Issues**:
- Device health shows `mqtt_publish_failures: 0` (no recorded failures)
- Status messages work but temperature messages missing
- Device appears connected but data not reaching broker

**Verification**: Check MQTT buffer size in platformio.ini build_flags for all environments

### High Memory Usage
1. Monitor `free_heap` value in status payload
2. If < 20KB, device may be unstable or dropping publishes
3. Reduce publish cadence or disable OLED display to free memory
4. Check for memory leaks: restart device and monitor heap over time

### OTA Upload Failures (WSL2/Windows)
**Symptom**: `pio run -t upload` fails with "No response from device" after authentication succeeds

**Root Cause**: Windows Firewall blocks ESP32 OTA port (3232) from WSL2

**Solution Options**:

1. **Temporary Fix (Recommended for testing)**:
   - Open Windows Security → Firewall & network protection
   - Turn off "Private network" firewall temporarily
   - Run OTA upload: `pio run -e esp32dev -t upload`
   - Re-enable firewall after upload completes

2. **Permanent Fix (Create Firewall Rule)**:
   - Open Windows Firewall with Advanced Security
   - Create new Inbound Rule:
     - Rule Type: Port
     - Protocol: TCP, Port: 3232
     - Action: Allow connection
     - Profile: Private (or all profiles)
     - Name: ESP32 OTA

**Verification**:
- Device shows "OTA:ready" in serial monitor
- Ping works: `ping DEVICE_IP`
- Port accessible after firewall disabled: `nc -zv DEVICE_IP 3232`

**PlatformIO Configuration** (already correct):
```ini
[env:esp32dev]
upload_protocol = espota
upload_port = DEVICE_IP
upload_flags = --auth=YOUR_OTA_PASSWORD --port=3232
```

### Firmware Version Tracking

**All devices include automatic firmware version tracking** for deployment management and OTA verification.

#### Version Format
```
MAJOR.MINOR.PATCH-buildYYYYMMDD
Example: 1.0.3-build20251222
```

#### MQTT Version Fields
All MQTT messages include `firmware_version`:
```json
{
  "device": "Temp Sensor",
  "firmware_version": "1.0.3-build20251222",
  "current_temp_c": 23.5,
  "event": "ota_start"
}
```

#### Version Update Process
```bash
# Update build timestamp before deployment
cd temperature-sensor
./update_version.sh

# Build and upload
pio run -e esp32dev -t upload
```

#### OTA Version Tracking
- **Before OTA**: Device reports current version
- **OTA Start**: Publishes `ota_start` event with current version  
- **OTA Complete**: Publishes `ota_complete` event with new version
- **After Reboot**: All messages show updated version

#### Manual Version Bumps
For major/minor/patch changes, edit `platformio.ini`:
```ini
-D FIRMWARE_VERSION_PATCH=3  # Increment for bug fixes
```

### Compilation Errors
1. Ensure `temperature-sensor/include/secrets.h` exists
2. Copy from `temperature-sensor/include/secrets.h.example` if needed
3. Verify MQTT_BROKER, MQTT_PORT, MQTT_USER, MQTT_PASSWORD are defined
4. Check PlatformIO environment matches board type (esp8266 vs esp32dev)

## ESP8266 API-Only Configuration

**ESP8266 temperature sensors can be configured for API-only operation** - no HTML web interface, optimized for USB-powered headless deployment.

### Configuration
ESP8266 environment automatically enables API-only mode:
```ini
[env:esp8266]
build_flags =
  -D API_ENDPOINTS_ONLY    # Disables HTML interface
  -D OLED_ENABLED=0        # No display support
  -D BATTERY_POWERED       # USB power optimization
```

### Available Endpoints
When `API_ENDPOINTS_ONLY` is defined, only these API endpoints are available:

- **GET `/temperaturec`** - Current temperature in Celsius (plain text)
- **GET `/temperaturef`** - Current temperature in Fahrenheit (plain text)  
- **GET `/health`** - Device health status (JSON)

**HTML interface (`/`) is disabled** - returns 404 Not Found

### Use Cases
- **Headless sensors**: USB-powered ESP8266 devices without displays
- **API integration**: Direct machine-to-machine communication
- **Resource optimization**: Reduced flash usage, faster boot
- **Security**: No web interface reduces attack surface

### Deployment
```bash
# Build ESP8266 API-only firmware
pio run -e esp8266

# Flash to device
pio run -e esp8266 -t upload --upload-port /dev/ttyUSB0
```

### MQTT Operation
ESP8266 devices operate identically to ESP32:
- Publish temperature readings every 30 seconds
- Publish status updates with device health
- Include firmware version in all messages
- Support OTA updates via MQTT commands

---

**Key Points**:
- ✅ Only MQTT broker details need compile-time configuration
- ✅ WiFi configured via WiFiManager captive portal (no hardcoded credentials)
- ✅ Device names set via portal, published in MQTT `device` field
- ✅ All data publishing visible in serial logs for debugging