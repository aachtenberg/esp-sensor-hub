# Quick Device Flashing Guide

## Your Devices

| Device | Location | Status |
|--------|----------|--------|
| Device 1 | Big Garage | ✅ Already Flashed |
| Device 2 | [Location 2] | ⏳ Ready to Flash |
| Device 3 | [Location 3] | ⏳ Ready to Flash |

## Steps for Each Device

### Device 2: Flash with New Location

1. **Edit device config:**
   ```bash
   nano include/device_config.h
   ```

2. **Change location name:**
   ```cpp
   static const char* DEVICE_LOCATION = "Bedroom";  // ← Change this
   ```

3. **Save and build:**
   ```bash
   platformio run -e nodemcuv2
   ```

4. **Disconnect Device 1, connect Device 2**

5. **Upload:**
   ```bash
   platformio run --target upload -e nodemcuv2
   ```

6. **Verify:**
   ```bash
   platformio device monitor -p /dev/ttyUSB0 -b 115200
   ```
   
   Look for:
   ```
   Temperature C: X.XX
   InfluxDB write successful (204 No Content)
   ```

---

### Device 3: Flash with Third Location

Repeat the same process:

1. Edit `include/device_config.h` with your 3rd location
2. Save and build
3. Connect Device 3
4. Upload with `platformio run --target upload -e nodemcuv2`
5. Verify with serial monitor

---

## Locations to Use

Suggestions for your Home Assistant setup:
- Big Garage ✅ (already set)
- Bedroom
- Living Room
- Kitchen
- Basement
- Attic
- Office
- Front Porch

---

## Quick Commands

**List available ports:**
```bash
ls /dev/ttyUSB*
```

**Build without uploading:**
```bash
platformio run -e nodemcuv2
```

**Upload to specific port:**
```bash
platformio run --target upload -e nodemcuv2 --upload-port /dev/ttyUSB0
```

**Monitor device output:**
```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

---

## What Each Device Sends

Once flashed, each device automatically sends:

### To InfluxDB Cloud
```
temperature,sensor=ds18b20,device=Big_Garage tempC=25.88,tempF=78.57
```

### To AWS Lambda
```json
{
  "device": "Big Garage",
  "tempC": 25.88,
  "tempF": 78.57,
  "timestamp": 1234567890,
  ...
}
```

### Local Web Dashboard
```
http://192.168.0.XXX/
```

---

## Home Assistant Integration

Once all devices are flashing:

### Option 1: REST Sensors (Simple)
```yaml
sensor:
  - platform: rest
    resource: http://192.168.0.103/temperaturec
    name: "Big Garage Temp"
    unit_of_measurement: "°C"
```

### Option 2: InfluxDB Query (Recommended)
Use Home Assistant's InfluxDB integration to query your device locations.

---

## Troubleshooting

**Device not uploading?**
- Check port: `ls /dev/ttyUSB*`
- Try: `platformio run --target upload -e nodemcuv2 -v`

**Temperature shows 0 or error?**
- Check DS18B20 wiring
- Watch serial monitor for errors
- Verify pull-up resistor (4.7kΩ) on data line

**Can't see device in Home Assistant?**
- Wait 2-3 minutes after flashing
- Check InfluxDB integration is configured
- Verify device is sending data (serial monitor)
- Restart Home Assistant

---

## Next: Home Assistant Dashboard

After all devices are flashed, create a dashboard:

```yaml
# configuration.yaml
homeassistant:
  customize:
    sensor.big_garage_temperature:
      friendly_name: Big Garage
      icon: mdi:thermometer
    sensor.bedroom_temperature:
      friendly_name: Bedroom
      icon: mdi:thermometer
```

Then add to your UI dashboard:
```yaml
cards:
  - type: entities
    entities:
      - sensor.big_garage_temperature
      - sensor.bedroom_temperature
      - sensor.living_room_temperature
```

