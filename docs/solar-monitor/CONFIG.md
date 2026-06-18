# Solar Monitor Configuration

## Overview

ESP32-S3 firmware (Freenove ESP32-S3-WROOM) for monitoring Victron solar equipment via VE.Direct protocol. Data flows: device → MQTT broker → Telegraf → TimescaleDB. See [solar-monitor/README.md](../../solar-monitor/README.md) for hardware setup.

## Required Files

### secrets.h Setup
Create `solar-monitor/include/secrets.h` (see `secrets.h.example` for the template):
```cpp
#ifndef SECRETS_H
#define SECRETS_H

// MQTT broker (Telegraf consumes from here)
static const char* MQTT_BROKER   = "192.168.0.167";
static const int   MQTT_PORT     = 1883;
static const char* MQTT_USER     = "";
static const char* MQTT_PASSWORD = "";

// OTA firmware update password (ArduinoOTA)
static const char* OTA_PASSWORD  = "change-this";

#endif
```

WiFi credentials are not in secrets.h — they're managed at runtime via WiFiManager (double-reset within 3 s of boot → captive portal at `SolarMonitor-Setup`).

## Build & Flash

### Initial USB Flash
```bash
cd solar-monitor
pio run -e esp32-s3-devkitc-1 -t upload --upload-port /dev/ttyUSB0
```
> Flashing uses the CH343 UART port (typically `/dev/ttyUSB0`); the native USB-Serial/JTAG port (`/dev/ttyACM*`) carries the runtime serial monitor. The ROM bootloader always uses UART0, so CH343 flashing works regardless of the `ARDUINO_USB_CDC_ON_BOOT=1` console setting.

### OTA Updates
After the first USB flash, subsequent updates can happen over WiFi. The `[env:ota]` environment inherits the base env and swaps `upload_protocol`.

```bash
cd solar-monitor
source ../.env
pio run -e ota -t upload --upload-port "$SOLAR_MONITOR_IP"
```

The device IP is not pinned in `platformio.ini` (matches the sibling firmwares) — it comes from `SOLAR_MONITOR_IP` in the gitignored `.env`, passed via `--upload-port`. `OTA_PASSWORD` is likewise read from `.env` (consumed by `--auth=${sysenv.OTA_PASSWORD}`). `upload_flags` keeps `--host_port=8266` — a host-environment WSL2 firewall setting (not a device address) — so the espota reverse connection isn't blocked by Windows Firewall under mirrored networking.

## Hardware Connections

### VE.Direct Wiring
Connect Victron equipment to the ESP32-S3 via VE.Direct cables (RX-only, 19200 baud, 3.3V TTL):
- SmartShunt TX → GPIO 16 (UART2 RX)
- MPPT Controller 1 TX → GPIO 17 (UART1 RX)
- MPPT Controller 2 TX → GPIO 18 (UART0 RX; console moved to native USB to free UART0)

### OLED Display (Optional)
- SDA → GPIO 21
- SCL → GPIO 9
- VCC → 3.3V
- GND → GND

## MQTT Topics

All topics use the `esp-sensor-hub/<sanitized-device-name>/` prefix (spaces → hyphens) to match the sibling temperature-sensor namespace. Telegraf's single `esp-sensor-hub/+/+` subscription covers every device in the fleet.

For this device: `esp-sensor-hub/Solar-Monitor-Garage/*`

| Topic | Retain | Payload | Notes |
|-------|--------|---------|-------|
| `.../battery` | no | SmartShunt snapshot (JSON) | Published only when SmartShunt frame is valid |
| `.../solar` | no | `{mppt1: {...}, mppt2: {...}}` (JSON) | Both MPPTs in one document; missing entries omitted when invalid |
| `.../status` | **yes** | Device health (JSON) | Retained so late subscribers see current state |
| `.../events` | no | Event log (JSON) | Boot, WiFi reconnect, sensor errors, OTA lifecycle |

Publish cadence: battery/solar/status every 30 s. Events are published as they occur.

### Example: `battery`
```json
{
  "device": "Solar-Monitor-Garage",
  "chip_id": "30E10C90A994",
  "timestamp": 180,
  "voltage": 13.25,
  "current": -2.34,
  "soc": 85.0,
  "time_remaining": 240,
  "consumed_ah": 15.2,
  "alarm": false,
  "relay": false,
  "min_voltage": 11.90,
  "max_voltage": 14.40,
  "charge_cycles": 42,
  "deepest_discharge": 21.5,
  "last_discharge": 8.2
}
```

### Example: `solar`
```json
{
  "device": "Solar-Monitor-Garage",
  "chip_id": "30E10C90A994",
  "timestamp": 180,
  "mppt1": {
    "pv_voltage": 18.65, "pv_power": 145, "battery_voltage": 13.25,
    "charge_current": 4.5, "charge_state": "BULK", "error_code": 0,
    "load_state": "ON", "load_current": 0.0,
    "yield_today": 2.34, "yield_yesterday": 3.12, "yield_total": 152.3,
    "max_power_today": 250, "max_power_yesterday": 275,
    "product_id": "0xA060", "serial_number": "HQ2145ABCDE"
  },
  "mppt2": { "...": "same shape" }
}
```

### Example: `status` (retained)
```json
{
  "device": "Solar-Monitor-Garage",
  "chip_id": "30E10C90A994",
  "timestamp": 180,
  "uptime_seconds": 179,
  "wifi_connected": true,
  "wifi_rssi": -54,
  "free_heap": 262812,
  "smartshunt_valid": true,
  "mppt1_valid": true,
  "mppt2_valid": true,
  "mqtt_publish_failures": 0,
  "wifi_forced_reconnects": 0
}
```

### Example: `events`
```json
{
  "device": "Solar-Monitor-Garage",
  "chip_id": "30E10C90A994",
  "event": "device_boot",
  "severity": "info",
  "timestamp": 2,
  "uptime_seconds": 2,
  "free_heap": 261192,
  "message": "Device started - Reset reason: Power On, Free heap: 261192 bytes"
}
```

Event types emitted: `device_boot`, `device_configured`, `wifi_connected`, `wifi_reconnect`, `wifi_forced_reconnect`, `sensor_error`, `ota_start`, `ota_complete`, `ota_error`, `device_restart`, `mqtt_dead_reboot`, `command_error`.

## Runtime Configuration

### WiFiManager Portal
1. Double-reset within 3 s of boot → device creates AP `SolarMonitor-Setup`
2. Connect, open http://192.168.4.1
3. Enter WiFi credentials and (optionally) update device name
4. On save, device reboots and auto-connects; MQTT topic base follows the new name

### Display
OLED cycles through Battery, Solar, Daily Stats, and System pages (5 s each).

## Monitoring

```bash
# Watch everything from this device
mosquitto_sub -h 192.168.0.167 -t 'esp-sensor-hub/Solar-Monitor-Garage/#' -v

# Just battery
mosquitto_sub -h 192.168.0.167 -t 'esp-sensor-hub/Solar-Monitor-Garage/battery' -v

# All devices in the fleet
mosquitto_sub -h 192.168.0.167 -t 'esp-sensor-hub/+/+' -v

# Retained status snapshot across fleet (exits immediately after retained dump)
mosquitto_sub -h 192.168.0.167 -t 'esp-sensor-hub/+/status' -v -W 2
```

## Troubleshooting

### No VE.Direct Data
- Verify VE.Direct cable pinout (yellow TX → ESP32-S3 RX, black GND, red 3.3V VCC)
- `status` topic fields `smartshunt_valid` / `mppt1_valid` / `mppt2_valid` tell you which channel is dead
- In VictronConnect, confirm the port is set to "VE.Direct" (not "Text" or disabled)
- Baud rate is fixed 19200 — not user-configurable on Victron side

### MQTT Not Publishing
- Check serial log: `[MQTT] Connecting to <broker>:1883 ...` → `[MQTT] Connected`
- If `Connect failed, state=N`, decode state: `-4` timeout, `-3` connection lost, `-2` connect failed, `5` bad credentials
- `mqtt_publish_failures` and `wifi_forced_reconnects` in the `status` payload are good health metrics
- Layered self-healing (see [README → WiFi / MQTT Self-Healing](README.md#wifi--mqtt-self-healing)): stale-connection re-MQTT at 120 s → forced WiFi re-association after 5 consecutive failures → full reboot after 15 min with no successful publish → task-watchdog reboot on a `loop()` deadlock

### OTA Failures
- `ota_error` event payload includes `Auth Failed`, `Begin Failed`, etc.
- Auth failed → password mismatch between `secrets.h` and `OTA_PASSWORD` env var used at upload time
- Begin/End Failed → flash partition or size issue (check app partition has headroom)
- First OTA attempt after boot can race with ongoing MQTT reconnect — retry
