# Multi-Device Temperature Sensor Flashing Guide

## Setup Overview

You have 3 ESP8266 devices that need to be flashed with different location names. Each device will send temperature data labeled with its location to Home Assistant, InfluxDB, and AWS.

## Locations

Configure each device with its location in `include/device_config.h`:

```
Device 1: Big Garage
Device 2: [Your location 2]
Device 3: [Your location 3]
```

## Flashing Process

### Step 1: Configure Device 1 (Big Garage)

Edit `include/device_config.h`:
```cpp
static const char* DEVICE_LOCATION = "Big Garage";
```

Build and upload:
```bash
cd /home/aachten/PlatformIO/esp12f_ds18b20_temp_sensor
platformio run --target upload -e nodemcuv2
```

### Step 2: Configure Device 2

Edit `include/device_config.h`:
```cpp
static const char* DEVICE_LOCATION = "Bedroom";  // Or your location
```

Disconnect Device 1, connect Device 2.

Upload:
```bash
platformio run --target upload -e nodemcuv2 --upload-port /dev/ttyUSB0
```

### Step 3: Configure Device 3

Edit `include/device_config.h`:
```cpp
static const char* DEVICE_LOCATION = "Living Room";  // Or your location
```

Disconnect Device 2, connect Device 3.

Upload:
```bash
platformio run --target upload -e nodemcuv2 --upload-port /dev/ttyUSB0
```

## Using the Multi-Flash Script

For a faster workflow, use the provided scripts:

### Bash Script (Interactive)
```bash
./flash_multiple.sh
```

Follow the prompts to:
1. Flash all devices or select specific ones
2. Connect/disconnect devices as prompted
3. The script shows progress for each device

### Python Script (Advanced)
```bash
./flash_multiple.py --all
```

## Verifying Flashing

After flashing each device:

1. **Check serial monitor:**
   ```bash
   platformio device monitor -p /dev/ttyUSB0 -b 115200
   ```

2. **Look for your location name in the output:**
   ```
   Device: Big Garage
   Temperature C: 25.88
   InfluxDB write successful (204 No Content)
   ```

3. **Check InfluxDB:**
   - Go to InfluxDB Cloud dashboard
   - Query: `SELECT * FROM temperature WHERE device="Big Garage"`

4. **Check Home Assistant:**
   - Your entity will appear in Home Assistant
   - Use as sensor in automations/dashboards

## Home Assistant Integration

Once devices are flashing and sending data to InfluxDB:

### Option A: REST sensor
```yaml
sensor:
  - platform: rest
    resource: http://192.168.0.103/temperaturec
    name: "Big Garage Temperature"
    unit_of_measurement: "°C"
```

### Option B: InfluxDB integration (Recommended)
```yaml
influxdb:
  host: us-east-1-1.aws.cloud2.influxdata.com
  port: 443
  ssl: true
  verify_ssl: true
  token: "YOUR_INFLUXDB_TOKEN"
  organization: "YOUR_ORG"
  bucket: "sensor_data"
```

Then query with template sensors:
```yaml
template:
  - sensor:
      - name: "Big Garage Temperature"
        unique_id: garage_temp
        unit_of_measurement: "°C"
        state: |
          {{ state_attr('sensor.garage_temperature', 'tempC') }}
```

## Device Details

Each device sends:
- **Temperature:** Celsius and Fahrenheit
- **Location Name:** From DEVICE_LOCATION in device_config.h
- **Device ID:** MAC address or custom ID
- **Timestamp:** Device uptime
- **Destinations:**
  - ✅ InfluxDB Cloud (time-series database)
  - ✅ AWS Lambda → CloudWatch Logs
  - ✅ Local web dashboard (http://192.168.X.X/)

## Troubleshooting

### Device not appearing in Home Assistant
- Verify device uploaded successfully (check serial output)
- Check Home Assistant logs: `Developer Tools > Logs`
- Verify InfluxDB integration is configured correctly
- Wait 1-2 minutes for first data point

### Temperature readings not updating
- Check device serial monitor: `platformio device monitor -p /dev/ttyUSB0 -b 115200`
- Verify WiFi connection (should see IP address during startup)
- Check InfluxDB token in secrets.h
- Verify device can reach InfluxDB (check firewall/network)

### Device showing old temperature
- Check device is actually sending new readings (serial monitor shows updates)
- InfluxDB might be showing cached data - refresh browser
- Verify device clock is correct (may affect timestamps)

## Next Steps

1. ✅ Flash all 3 devices with different locations
2. ✅ Verify in Home Assistant they appear with correct location names
3. ✅ Create Home Assistant dashboard showing all 3 locations
4. ✅ Set up automations (alerts if temperature too high, etc.)
5. ✅ Deploy Grafana to visualize temperature trends over time

