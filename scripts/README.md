# Build & Flash Scripts

Helper scripts for building and flashing ESP devices.

## Device Inventory Database Update

### Update PostgreSQL Database

Updates device information from `DEVICE_INVENTORY.md` to PostgreSQL database on raspberrypi2:

```bash
cd /home/aachten/PlatformIO/esp12f_ds18b20_temp_sensor/scripts

# Install dependencies (once)
pip3 install psycopg2-binary

# Update database with device info
python3 update_devices.py
```

**What it does:**
- Reads `../DEVICE_INVENTORY.md`
- Parses all device information
- Updates PostgreSQL database on raspberrypi2
- Creates `devices` and `device_groups` tables automatically

**Database location:** raspberrypi2 (YOUR_DB_HOST), database: `camera_db`

## Build Systems

### PlatformIO (Temperature Sensor & Solar Monitor)

```bash
cd temperature-sensor
pio run -e esp8266 --target upload --upload-port /dev/ttyUSB0
pio run -e esp32dev --target upload --upload-port /dev/ttyUSB0

cd solar-monitor
pio run --target upload --upload-port /dev/ttyUSB0
```

### Arduino CLI (Surveillance Camera)

```bash
cd surveillance-arduino
./COMPILE.sh              # ESP32-CAM
./COMPILE_ESP32S3.sh      # ESP32-S3

# Upload
./bin/arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32cam ESP32CAM_Surveillance
./bin/arduino-cli upload -p /dev/ttyACM0 --fqbn esp32:esp32:esp32s3 ESP32CAM_Surveillance
```

## Device Configuration

All devices use **WiFiManager captive portal** for configuration:

1. Flash device using appropriate build system
2. Device creates AP (e.g., `ESP-Setup`)
3. Connect to AP and open captive portal
4. Configure WiFi credentials and device name
5. Settings persist in flash/NVS across reboots

## Board Support

| Board | Project | Port | Build System | FQBN | Build Flags |
|-------|---------|------|--------------|------|-------------|
| ESP8266 (NodeMCU) | Temperature Sensor | `/dev/ttyUSB*` | PlatformIO | `esp8266` | `OLED_ENABLED=0, BATTERY_POWERED, API_ENDPOINTS_ONLY, CPU_FREQ_MHZ=80, WIFI_PS_MODE=WIFI_LIGHT_SLEEP` |
| ESP32 (WROOM) | Temperature Sensor / Solar Monitor | `/dev/ttyUSB*` | PlatformIO | `esp32dev` | `OLED_ENABLED=1, API_ENDPOINTS_ONLY, CPU_FREQ_MHZ=80, WIFI_PS_MODE=WIFI_PS_MIN_MODEM` |
| ESP32-CAM (AI-Thinker) | Surveillance | `/dev/ttyUSB*` | Arduino CLI | `esp32:esp32:esp32cam` | Camera=1, Motion=1, Webserver=1, MQTT=1 |
| ESP32-S3 (Freenove) | Surveillance | `/dev/ttyACM*` | Arduino CLI | `esp32:esp32:esp32s3` | Camera=1, Motion=1, Webserver=1, MQTT=1 |

**PlatformIO Build Flags:**
- **ESP8266 Temperature:** `OLED_ENABLED=0, BATTERY_POWERED, API_ENDPOINTS_ONLY, CPU_FREQ_MHZ=80, WIFI_PS_MODE=WIFI_LIGHT_SLEEP`
- **ESP32 Temperature:** `OLED_ENABLED=1, API_ENDPOINTS_ONLY, CPU_FREQ_MHZ=80, WIFI_PS_MODE=WIFI_PS_MIN_MODEM`
- **ESP32-S3 Temperature:** `CPU_FREQ_MHZ=80, WIFI_PS_MODE=WIFI_PS_MIN_MODEM` (OLED auto-detected)
- **ESP32 Solar Monitor:** `CORE_DEBUG_LEVEL=0, ARDUINO_ESP32_DEV`

**Arduino CLI Build Flags:**
- Surveillance projects use Arduino IDE build system with camera libraries and motion detection enabled by default

## WSL2 USB Support

For Windows users with WSL2:

```powershell
# Windows PowerShell (as Administrator)
usbipd list
usbipd bind --busid 2-11
usbipd attach --wsl --busid 2-11
```

Then use the device normally in WSL2 terminal.