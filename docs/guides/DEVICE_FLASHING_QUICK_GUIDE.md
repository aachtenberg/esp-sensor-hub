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

Choose location names for your devices:
- Big Garage ✅ (already set)
- Bedroom
- Living Room
- Kitchen
- Basement
- Attic
- Office
- Front Porch

**Note:** Home Assistant integration requires separate setup to read from InfluxDB.

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

## Home Assistant Integration (Optional)

**Note:** This requires separate Home Assistant setup. The device sends data to InfluxDB, and HA can read from there.

### Recommended: InfluxDB Integration
Configure Home Assistant to query InfluxDB for temperature data from your device locations.

See SETUP.md for detailed Home Assistant configuration instructions.

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
- Wait 2-3 minutes after flashing for data to appear in InfluxDB
- **Configure Home Assistant InfluxDB integration** (see SETUP.md)
- Verify device is sending data (check serial monitor)
- Restart Home Assistant after integration setup

---

## Next: Home Assistant Setup (Optional)

After all devices are flashed and sending data to InfluxDB:

1. Configure Home Assistant InfluxDB integration (see SETUP.md)
2. Create sensors for each device location
3. Add temperature entities to your dashboard
4. Set up automations and alerts as needed

```yaml
# Example configuration after HA-InfluxDB setup
homeassistant:
  customize:
    sensor.big_garage_temperature:
      friendly_name: Big Garage
      icon: mdi:thermometer
```

