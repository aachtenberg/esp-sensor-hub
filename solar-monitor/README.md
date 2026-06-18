# ESP32-S3 Solar Monitor Firmware

PlatformIO firmware for ESP32-S3 solar monitoring using the Victron VE.Direct protocol. Publishes sensor data over MQTT (consumed by Telegraf → TimescaleDB) and supports OTA firmware updates.

## Hardware

| Component | Model | Connection |
|-----------|-------|------------|
| Microcontroller | Freenove ESP32-S3-WROOM | `board = esp32-s3-devkitc-1` |
| Battery Monitor | SmartShunt SHU050150050 | GPIO 16 (UART2 RX) |
| Charge Controller 1 | SmartSolar MPPT SCC110050210 | GPIO 17 (UART1 RX) |
| Charge Controller 2 | SmartSolar MPPT | GPIO 18 (UART0 RX) |
| OLED Display | SSD1306 128×64 I²C | SDA=GPIO 21, SCL=GPIO 9 |
| Power Supply | 12V→5V 3A converter | 5V pin |

> **Note:** All three VE.Direct inputs use hardware UARTs. UART0 is available for MPPT2 because the debug console runs on the ESP32-S3's native USB-Serial/JTAG controller (`ARDUINO_USB_CDC_ON_BOOT=1`, GPIO 19/20) instead of UART0. GPIO 22–25 don't exist on S3, so the pin map differs from the original ESP32-WROOM-32 layout.

## Quick Start

1. Copy `include/secrets.h.example` to `include/secrets.h`
2. Edit `secrets.h` with your MQTT broker and OTA password
3. First-time USB flash:
   ```bash
   pio run -e esp32-s3-devkitc-1 -t upload
   pio device monitor
   ```
   > The runtime serial console is on the **native USB-Serial/JTAG port** (enumerates as `/dev/ttyACM*`), not the CH343 UART port. Flashing over CH343 still works because the ROM bootloader always uses UART0.
4. **Configure WiFi**: double-reset within 3 s → connect to the `SolarMonitor-Setup` AP → open `http://192.168.4.1` → enter WiFi + device name
5. Subsequent updates go over the air:
   ```bash
   OTA_PASSWORD=<your-pw> pio run -e ota -t upload
   ```

## Reliability / Self-Healing

The firmware layers four recovery mechanisms (cheapest first) to survive the WiFi/TCP-stack wedges that previously required a manual power-cycle (see [docs/solar-monitor/README.md](../docs/solar-monitor/README.md#wifi--mqtt-self-healing)):

1. **Stale-connection re-MQTT** — if connected but no successful publish in 120 s, drop and re-establish the MQTT session.
2. **Forced WiFi re-association** after 5 consecutive MQTT failures (rate-limited) — recovers "associated but no backhaul" stalls that `setAutoReconnect` misses.
3. **MQTT-dead reboot** — if no successful publish lands for 15 min (after at least one this boot), reboot to clear a wedged stack.
4. **Task watchdog** (30 s) — reboots on a hard `loop()` deadlock; unsubscribed during OTA.

The root cause was also addressed: MPPT2 moved off bit-banged EspSoftwareSerial onto hardware UART0, removing a GPIO-ISR WiFi antagonist.

## MQTT Topics

All topics are namespaced under `esp-sensor-hub/<sanitized-device-name>/` (e.g. `esp-sensor-hub/Solar-Monitor-Garage/`). See [docs/solar-monitor/CONFIG.md](../docs/solar-monitor/CONFIG.md) for the full schema, retain flags, and payload examples.

| Topic | Retain | Payload |
|-------|--------|---------|
| `.../battery` | no  | SmartShunt snapshot |
| `.../solar`   | no  | Both MPPTs (nested objects) |
| `.../status`  | yes | Device health |
| `.../events`  | no  | Lifecycle events (boot, WiFi, OTA, sensor errors) |

## Local Web API

The device also serves JSON endpoints at its IP (useful for ad-hoc checks):

| Endpoint | Description |
|----------|-------------|
| `GET /` | HTML dashboard |
| `GET /api/battery` | SmartShunt data |
| `GET /api/solar` | Both MPPTs |
| `GET /api/system` | Combined status |

## Project Structure

```
solar-monitor/
├── src/
│   ├── main.cpp              # Main application (WiFi, MQTT, OTA, web server)
│   ├── display.{cpp,h}       # OLED driver (U8g2 SW-I2C)
│   ├── VictronSmartShunt.{cpp,h}  # SmartShunt VE.Direct parser
│   └── VictronMPPT.{cpp,h}   # MPPT VE.Direct parser
├── include/
│   └── secrets.h.example     # Template — copy to secrets.h (gitignored)
├── platformio.ini            # Two envs: esp32-s3-devkitc-1 (USB), ota (OTA)
└── README.md
```

## Documentation

See [docs/solar-monitor/](../docs/solar-monitor/) for the full wiring guide, VE.Direct protocol reference, bill of materials, and troubleshooting notes.
