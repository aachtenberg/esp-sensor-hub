# Multi-Board ESP Temperature Sensor Setup

This project now supports both **ESP8266** and **ESP32** devices on the same codebase!

## Supported Boards

- **ESP8266** (NodeMCU v2, D1 Mini, etc.) - `esp8266`
- **ESP32** (ESP-WROOM-32, DevKit, etc.) - `esp32`

## Quick Start: Flashing Devices

### ESP32 Device
```bash
./flash_device.sh "Big Garage" esp32
./flash_device.sh "Bedroom" esp32
```

### ESP8266 Device
```bash
./flash_device.sh "Small Garage" esp8266
./flash_device.sh "Pump House" esp8266
```

### Default (ESP32)
If no board type specified, defaults to ESP32:
```bash
./flash_device.sh "Living Room"  # defaults to esp32
```

## Device Configuration

Each device gets configured in `include/device_config.h`:

```cpp
static const char* DEVICE_LOCATION = "Device Name";  // Set by flash script
static const char* DEVICE_BOARD = "esp32";            // Set by flash script
```

The flash script automatically updates both values before building and uploading.

## What's Different Between Boards?

The firmware automatically adapts based on the board type:

| Feature | ESP8266 | ESP32 |
|---------|---------|-------|
| WiFi | Single band 2.4GHz | Single band 2.4GHz |
| Async Web Server | ESPAsyncTCP | AsyncTCP |
| HTTP Client | ESP8266HTTPClient | HTTPClient |
| WiFi Sleep Mode | `setSleepMode()` | `setSleep()` |
| GPIO Pins | D0-D8 | GPIO0-39 |
| RAM | 160KB | 320KB |
| Flash | Typically 4MB | Typically 4MB+ |

## GPIO Configuration

The default **GPIO 4** (D2 on ESP8266) is used for the DS18B20 sensor:

### ESP8266 (NodeMCU v2)
- D2 (GPIO 4) → DS18B20 Data
- GND → DS18B20 Ground
- 3V3 → DS18B20 VCC

### ESP32 (ESP-WROOM-32)
- GPIO 4 → DS18B20 Data
- GND → DS18B20 Ground
- 3V3 → DS18B20 VCC

To use a different GPIO, edit `src/main.cpp`:
```cpp
#define ONE_WIRE_BUS 4  // Change this number
```

Then rebuild and flash.

## Multi-Device Setup Example

```bash
# Flash an ESP32 device for the garage
./flash_device.sh "Big Garage" esp32

# Flash an ESP8266 device for the pump house
./flash_device.sh "Pump House" esp8266

# Flash another ESP32 for the bedroom
./flash_device.sh "Bedroom" esp32
```

Each device will:
- Get its own location name in logs and metrics
- Send data to AWS Lambda/CloudWatch with device identification
- Report temperature to InfluxDB with proper tags
- Work with Home Assistant using the location name

## Troubleshooting

### Build Fails for ESP8266
- Make sure you're using `esp8266` board type: `./flash_device.sh "Device" esp8266`
- Check that you're using a compatible board (NodeMCU v2, D1 Mini, etc.)

### Build Fails for ESP32
- Make sure you're using `esp32` board type: `./flash_device.sh "Device" esp32`
- Verify the ESP32 DevKit is the correct variant (some boards have different pinouts)

### Device Won't Upload
- Check USB connection and port: `ls /dev/ttyUSB*`
- Try holding BOOT button on ESP during upload
- For ESP8266, try holding GPIO0 to GND during upload

### WiFi Connection Issues
- Verify SSID and password in `include/secrets.h`
- Check signal strength - move device closer to router
- Try static IP configuration in `include/secrets.h`

## Advanced: Custom Board Configuration

If you need to support a different ESP variant, add a new environment to `platformio.ini`:

```ini
[env:esp32-s3]
platform = espressif32
board = esp32-s3-devkitc-1
framework = arduino
; ... same lib_deps as esp32dev
```

Then flash with:
```bash
./flash_device.sh "Device Name" esp32  # Modify script to support esp32-s3
```

## PlatformIO Environments Available

- `esp32dev` - ESP32 DevKit (default for esp32)
- `esp8266` - ESP8266 NodeMCU v2 (default for esp8266)

Build only (without uploading):
```bash
pio run -e esp32dev
pio run -e esp8266
```

Monitor serial (if device is connected):
```bash
pio device monitor -b 115200
```
