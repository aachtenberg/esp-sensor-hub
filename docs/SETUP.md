# Multi-Device Temperature Sensor - Home Assistant Integration

## ✅ Setup Complete!

Your temperature sensor system is now configured for **multiple devices with location names**.

Each device will send data to:
- ✅ **InfluxDB Cloud** - Long-term storage & Grafana
- ✅ **AWS Lambda/CloudWatch** - Cloud logging
- ✅ **Home Assistant** - Dashboard via REST/InfluxDB

---

## 🚀 Quick Start: Flash Your Devices

### Device 1: Big Garage (Already Flashed ✅)
```bash
# No action needed - already running
```

### Device 2: Your Second Location
```bash
./flash_device.sh "Bedroom"
# Connect Device 2 via USB
# Script will automatically:
# 1. Update location name
# 2. Build firmware
# 3. Upload to device
# 4. Show serial monitor
```

### Device 3: Your Third Location
```bash
./flash_device.sh "Living Room"
# Connect Device 3 via USB
# Same automatic process
```

---

## 📍 Location Names to Use

Choose from these or add your own:
- ✅ Big Garage
- Bedroom
- Living Room
- Kitchen
- Basement
- Attic
- Office
- Front Porch
- Back Porch
- Garage
- Study

---

## 🏠 Home Assistant Configuration

### 1. Add InfluxDB Integration

In `configuration.yaml`:
```yaml
influxdb:
  api_version: 2
  ssl: true
  host: us-east-1-1.aws.cloud2.influxdata.com
  token: "YOUR_INFLUXDB_TOKEN"
  organization: "YOUR_ORG"
  bucket: "sensor_data"
```

### 2. Create Temperature Sensors

```yaml
template:
  - sensor:
      - name: "Big Garage Temperature"
        unique_id: big_garage_temp_c
        unit_of_measurement: "°C"
        device_class: temperature
        # Query InfluxDB for latest reading
```

### 3. Add to Dashboard

In Home Assistant UI:
1. Create new dashboard
2. Add "Entities" card
3. Select all temperature sensors
4. Customize cards with icons/colors

Result:
```
🌡️ Big Garage: 25.88°C
🌡️ Bedroom: 22.45°C
🌡️ Living Room: 23.12°C
```

---

## 📊 Device Data Flow

```
┌─────────────────────────────────────────────────────┐
│         ESP8266 Temperature Sensor                  │
│  (Device Location: "Big Garage", "Bedroom", etc.)   │
└──────────┬──────────────────────────────────────────┘
           │
    ┌──────┴──────┬──────────────┬──────────────┐
    │             │              │              │
    ▼             ▼              ▼              ▼
┌────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐
│InfluxDB│  │  Lambda  │  │CloudWatch│  │Web Server │
│ Cloud  │  │Function  │  │Logs      │  │ (Local)   │
│        │  │          │  │          │  │           │
└────────┘  └──────────┘  └──────────┘  └───────────┘
    │            │              │              │
    │            │              │              │
    ▼            ▼              ▼              ▼
┌──────────────────────────────────────────────────────┐
│             Home Assistant / Grafana                │
│  Display all 3 devices with location names          │
└──────────────────────────────────────────────────────┘
```

---

## 🔧 Files Created/Updated

### Configuration
- `include/device_config.h` - Location settings for each device
- `include/secrets.h` - WiFi, InfluxDB, AWS credentials

### Flashing Scripts
- `flash_device.sh` - **Easy one-liner device flashing** ⭐ USE THIS
- `flash_multiple.sh` - Flash all devices at once
- `flash_multiple.py` - Advanced multi-device manager

### Documentation
- `MULTI_DEVICE_SETUP.md` - Detailed multi-device guide
- `DEVICE_FLASHING_QUICK_GUIDE.md` - Quick reference
- `SETUP.md` - This file!

### Firmware
- `src/main.cpp` - Updated to use DEVICE_LOCATION

---

## 🎯 Workflow for Each Device

### Step 1: Prepare (1 minute)
```bash
cd /home/aachten/PlatformIO/esp12f_ds18b20_temp_sensor
```

### Step 2: Flash (2-3 minutes)
```bash
./flash_device.sh "Bedroom"
```

### Step 3: Verify (1 minute)
```bash
# Serial monitor opens automatically
# Look for:
# - WiFi connection message
# - "Temperature C: XX.XX"
# - "InfluxDB write successful (204 No Content)"
```

### Step 4: Done! 🎉
Device will now appear in Home Assistant with location name "Bedroom"

---

## 📱 View in Home Assistant

**Mobile App:**
1. Open Home Assistant mobile app
2. Go to Entities or Dashboard
3. Filter by "temperature"
4. See all 3 devices with location names

**Web Dashboard:**
1. Home Assistant URL (usually `http://your-server:8123`)
2. Create new dashboard
3. Add all temperature sensors
4. Group by location

---

## 🔍 Troubleshooting

### Device not appearing in Home Assistant
1. Check device uploaded (watch serial output)
2. Wait 2-3 minutes for first data point
3. Refresh Home Assistant
4. Check InfluxDB integration is enabled

### Temperature shows as "unavailable"
1. Verify InfluxDB token is correct
2. Check device can reach InfluxDB (WiFi working)
3. Watch serial monitor: `platformio device monitor -p /dev/ttyUSB0 -b 115200`

### Device keeps rebooting
1. Check power supply (adequate 5V)
2. Check DS18B20 wiring
3. Monitor console for error messages

### Slow updates in Home Assistant
1. InfluxDB has 30s update frequency - normal
2. Increase by editing Lambda frequency in code
3. Or query InfluxDB directly (faster)

---

## 📈 Next Steps

1. ✅ Flash all 3 devices with locations
2. ✅ Verify in Home Assistant
3. ⏳ Create Home Assistant dashboard
4. ⏳ Set up temperature alerts/automations
5. ⏳ Deploy Grafana for historical graphs
6. ⏳ Add humidity/pressure sensors if desired

---

## 💡 Example Automations in Home Assistant

### Alert if temperature too high
```yaml
automation:
  - alias: "High Temperature Alert"
    trigger:
      platform: numeric_state
      entity_id: sensor.big_garage_temperature
      above: 35  # 35°C threshold
    action:
      service: notify.mobile_app_iphone
      data:
        message: "Big Garage temperature is {{ states('sensor.big_garage_temperature') }}°C!"
```

### Climate control automation
```yaml
automation:
  - alias: "AC if too hot"
    trigger:
      platform: numeric_state
      entity_id: sensor.big_garage_temperature
      above: 28
    action:
      service: switch.turn_on
      target:
        entity_id: switch.garage_ac
```

---

## 📞 Support

**Issue with flashing?**
- Run: `platformio run --target upload -e nodemcuv2 -v` (verbose)
- Check: `ls /dev/ttyUSB*` (device present?)
- Try: Restart Arduino IDE or platformio

**Device won't connect to WiFi?**
- Check SSID/password in `include/secrets.h`
- Power cycle device
- Check WiFi strength at device location

**Data not appearing in Home Assistant?**
- Check InfluxDB integration enabled
- Verify token in `include/secrets.h`
- Query InfluxDB directly: https://us-east-1-1.aws.cloud2.influxdata.com/api/v1/query

---

## 🎓 Learning Resources

- InfluxDB: https://docs.influxdata.com/influxdb/cloud/
- Home Assistant: https://www.home-assistant.io/docs/
- Grafana: https://grafana.com/docs/grafana/latest/
- ESP8266: https://github.com/esp8266/Arduino

---

**Status:** ✅ Ready for multi-device deployment

Last updated: November 14, 2025
