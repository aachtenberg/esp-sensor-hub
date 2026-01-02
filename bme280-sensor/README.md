# BME280 Environmental Sensor

Environmental monitoring sensor measuring temperature, humidity, and atmospheric pressure.

## Features

- **BME280 Sensor**: Measures temperature, humidity, pressure, and calculates altitude
- **WiFi Configuration**: WiFiManager portal for easy SSID/password configuration
- **MQTT Integration**: Publishes readings to MQTT broker
- **OTA Updates**: Over-the-air firmware updates via ArduinoOTA
- **Battery Support**: Optional battery voltage monitoring (ESP32)
- **Deep Sleep**: Battery-optimized deep sleep mode with configurable interval
- **Web Interface**: Simple HTML dashboard showing current readings
- **REST API**: JSON endpoint for programmatic access

## Hardware

### Required
- ESP32 development board (esp32dev)
- BME280 I2C environmental sensor module
- USB cable for power and programming

### Optional
- Battery (3.7V lithium-ion)
- SSD1306 OLED display (I2C)
- Voltage divider for battery monitoring (10K + 10K resistors)

### Pinout (ESP32)

```
BME280 I2C:
  SDA → GPIO 21 (I2C Data)
  SCL → GPIO 22 (I2C Clock)
  VCC → 3.3V
  GND → GND

Battery Monitor (Optional):
  Battery+ → 10K → GPIO 34 → 10K → GND
```

## Quick Start

### 1. Setup

```bash
cd bme280-sensor

# Copy secrets template
cp include/secrets.h.example include/secrets.h

# Edit secrets.h with your MQTT broker details
nano include/secrets.h
```

### 2. First Upload (USB)

```bash
# Initial upload via USB serial (for battery mode, disable display)
pio run -e esp32dev-battery-display-serial -t upload
```

### 3. WiFi Configuration

Device will create WiFi access point:
- SSID: `BME280 Sensor` (or custom device name)
- Open browser: `http://192.168.4.1`
- Select your WiFi network and enter password

### 4. Subsequent Uploads (OTA)

```bash
export PLATFORMIO_UPLOAD_FLAGS="--auth=YOUR_OTA_PASSWORD"
pio run -e esp32dev-battery -t upload --upload-port 192.168.X.X
```

## MQTT Topics

### Publish

- `esp-sensor-hub/{device-name}/readings` - Environmental data (temperature, humidity, pressure, altitude)
- `esp-sensor-hub/{device-name}/status` - Device health and metrics
- `esp-sensor-hub/{device-name}/events` - Device events (startup, errors, etc.)

### Subscribe

- `esp-sensor-hub/{device-name}/command` - Device control commands

### Example Payload (readings)

```json
{
  "device": "Kitchen-Sensor",
  "chip_id": "A0B1C2D3E4F5",
  "schema_version": 1,
  "timestamp": 1234567890,
  "temperature_c": 22.5,
  "humidity_rh": 45.2,
  "pressure_pa": 101325,
  "altitude_m": -45.2,
  "battery_percent": 85
}
```

## Configuration

### Device Name

```bash
# Change device name
mosquitto_pub -h BROKER -t "esp-sensor-hub/Kitchen-Sensor/command" -m "name New-Kitchen-Sensor"
```

### Deep Sleep (Battery Mode)

```bash
# Enable 60-second deep sleep interval
mosquitto_pub -h BROKER -t "esp-sensor-hub/Kitchen-Sensor/command" -m "deepsleep 60"

# Disable deep sleep
mosquitto_pub -h BROKER -t "esp-sensor-hub/Kitchen-Sensor/command" -m "deepsleep 0"
```

## Platforms

### esp32dev-battery
- ESP32 with minimal power consumption
- CPU at 80 MHz, WiFi power save enabled
- Suitable for 3.7V battery operation
- No OLED display

### esp32dev-battery-display
- ESP32 with OLED support
- Same power optimizations as battery mode
- OLED display optional at runtime
- Higher memory requirements

### esp32dev-battery-display-serial
- First-time USB programming
- Higher upload speed (460800 baud)
- Use before switching to OTA

### esp32dev
- Development mode, wired power
- No power optimizations
- Full speed (240 MHz available)

## Troubleshooting

### Sensor Not Detected

```bash
# Check I2C connectivity
pio device monitor

# Look for: "[SENSOR] BME280 initialized successfully"
# If failed, check SDA (GPIO 21) and SCL (GPIO 22) connections
```

### MQTT Not Connected

1. Verify broker address in `secrets.h`
2. Check WiFi connection: `mosquitto_pub -h BROKER -t "test" -m "hello"`
3. Monitor device: `pio device monitor`

### Missing Readings in MQTT

1. Check device is connected: `mosquitto_sub -h BROKER -t "esp-sensor-hub/+/status" -v`
2. Monitor WiFi signal: status topic shows RSSI
3. Check free heap: may need to reduce features if critical low

## Development

### Update Firmware Version

```bash
cd bme280-sensor
./update_version.sh --patch

# Then build and upload
pio run -e esp32dev-battery -t upload --upload-port 192.168.X.X
```

### Monitor Logs

```bash
pio device monitor -p /dev/ttyUSB0 -b 115200
```

### View All Sensor Data

```bash
mosquitto_sub -h BROKER -t "esp-sensor-hub/+/#" -v
```

## Libraries

- **Adafruit BME280**: Sensor driver
- **PubSubClient**: MQTT client
- **ArduinoJson**: JSON serialization
- **WiFiManager**: WiFi configuration portal
- **ArduinoOTA**: Over-the-air updates

## License

Same as esp-sensor-hub repository
