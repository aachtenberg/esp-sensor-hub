# ESP32-S3 Solar Monitor

WiFi-enabled monitoring system for Victron Energy solar equipment using the Freenove ESP32-S3-WROOM.

**Status:** ✅ Implemented and deployed

## Table of Contents
1. [Overview](#overview)
2. [Hardware Configuration](#hardware-configuration)
3. [Wiring Instructions](#wiring-instructions)
4. [Pin Assignments](#pin-assignments)
5. [VE.Direct Protocol](#vedirect-protocol)
6. [MQTT Output and OTA Updates](#mqtt-output-and-ota-updates)
7. [API Endpoints](#api-endpoints)
8. [Quick Reference](#quick-reference)
9. [Troubleshooting](#troubleshooting)
10. [Integration with Backend](#integration-with-backend)

---

## Overview

### Features

- Real-time monitoring of Victron equipment via VE.Direct protocol
- Dual MPPT charge controller monitoring
- Battery state monitoring via SmartShunt
- OLED display (optional, can be disabled if hardware not connected)
- WiFi connectivity with WiFiManager (captive portal configuration)
- JSON API for third-party integrations
- Web dashboard
- MQTT publishing to the `esp-sensor-hub/<device>/` namespace (consumed by Telegraf → TimescaleDB)
- OTA firmware updates via ArduinoOTA (password-protected)

### Monitored Equipment

1. **SmartShunt SHU050150050** - Battery monitoring
   - Battery voltage, current, power
   - State of charge (SOC %)
   - Time to go (TTG minutes)
   - Historical discharge data

2. **SmartSolar MPPT 1 & 2** - Charge controllers
   - PV voltage and power
   - Charge current and state
   - Daily/total yield statistics
   - Error monitoring

---

## Hardware Configuration

### Components

| Component | Model | Notes |
|-----------|-------|-------|
| Microcontroller | Freenove ESP32-S3-WROOM | Dual UART + SoftwareSerial for 3 devices (`board = esp32-s3-devkitc-1`) |
| Battery Monitor | Victron SmartShunt SHU050150050 | 500A/50mV shunt |
| Charge Controller 1 | Victron SmartSolar MPPT SCC110050210 | 100V/50A |
| Charge Controller 2 | Victron SmartSolar MPPT SCC110050210 | 100V/50A |
| Display (optional) | SSD1306 OLED | 128x64 I2C display |
| Power Supply | 12V-to-5V converter | 3A waterproof micro-USB |

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Freenove ESP32-S3-WROOM                    │
│                                                         │
│  UART2 (SmartShunt):                                   │
│    GPIO 16 (RX) ←─── SmartShunt TX                    │
│                                                         │
│  UART1 (MPPT1):                                        │
│    GPIO 17 (RX) ←─── MPPT1 TX                         │
│                                                         │
│  SoftwareSerial (MPPT2):                               │
│    GPIO 18 (RX) ←─── MPPT2 TX                         │
│                                                         │
│  I2C (OLED - optional):                                │
│    GPIO 21 (SDA) ←──→ OLED SDA                        │
│    GPIO  9 (SCL) ←──→ OLED SCL                        │
│                                                         │
│  Power:                                                 │
│    5V  ←────────── 5V from 12V-to-5V converter         │
│    GND ──────────→ Common ground (VE.Direct black x3)   │
│                                                         │
│  Reserved (do not use):                                │
│    GPIO 19 / 20  → Native USB D-/D+                    │
│    GPIO 22-25    → Do not exist on ESP32-S3            │
└─────────────────────────────────────────────────────────┘
```

---

## Wiring Instructions

### VE.Direct Cable Pinout

VE.Direct uses a 4-pin connector with the following signals:

| Pin | Signal | Wire color (nominal) | Description |
|-----|--------|----------------------|-------------|
| 1   | GND    | Black                | Ground (required) |
| 2   | RX     | White ¹              | Host-to-device (unused for read-only monitoring) |
| 3   | TX     | Yellow ¹             | Device-to-host — **this is the one you wire to the ESP32 RX pin** |
| 4   | VCC    | Red                  | 3.3V supply (optional — the ESP32 has its own 3.3V rail) |

¹ **Wire colors are not reliable.** Victron (and especially third-party) VE.Direct cables have been produced with yellow↔white swapped. If the nominal pinout gives no data, swap the two signal wires and try again — this deployment's SmartShunt cable uses **white for TX**, while the MPPT cables use yellow. Empirical test trumps the legend.

**Important:** VE.Direct is 3.3V TTL — directly compatible with ESP32-S3, no level shifter needed.

### Step-by-Step Wiring

> In each step below, "TX signal wire" is nominally **yellow**, but on some cables it's **white** — see the [cable-pinout caveat](#vedirect-cable-pinout) above. If `<device>_valid` in the `/status` MQTT topic stays `false` after wiring, swap the two non-black/non-red wires and retry.

#### 1. Connect SmartShunt (UART2)
- SmartShunt VE.Direct TX signal → ESP32-S3 GPIO 16
- SmartShunt VE.Direct GND (black) → ESP32-S3 GND (required)
- SmartShunt VE.Direct VCC (red) → leave unconnected (ESP32-S3 has its own 3.3V)

#### 2. Connect MPPT1 (UART1)
- MPPT1 VE.Direct TX signal → ESP32-S3 GPIO 17
- MPPT1 VE.Direct GND (black) → ESP32-S3 GND (required)
- MPPT1 VE.Direct VCC (red) → leave unconnected

#### 3. Connect MPPT2 (SoftwareSerial)
- MPPT2 VE.Direct TX signal → ESP32-S3 GPIO 18
- MPPT2 VE.Direct GND (black) → ESP32-S3 GND (required)
- MPPT2 VE.Direct VCC (red) → leave unconnected

#### 4. Connect OLED Display (Optional)
- OLED SDA → ESP32-S3 GPIO 21
- OLED SCL → ESP32-S3 GPIO 9
- OLED VCC → ESP32-S3 3.3V
- OLED GND → ESP32-S3 GND

**Note:** Set `OLED_ENABLED = false` in code if OLED hardware is not connected to prevent crashes.

#### 5. Power the ESP32-S3
- 12V battery positive → inline fuse (5A) → 12V-to-5V converter input (+)
- 12V battery negative → 12V-to-5V converter input (-)
- Converter 5V output → ESP32-S3 5V pin
- Converter GND → ESP32-S3 GND

### Verification Checklist

Before powering on:
- [ ] Check all connections with multimeter (continuity)
- [ ] Verify no shorts between VCC and GND
- [ ] Confirm 12V-to-5V converter outputs ~5V
- [ ] Double-check GPIO pin assignments
- [ ] Verify common ground connections

---

## Pin Assignments

### ESP32-S3 GPIO Pin Configuration

| GPIO Pin | Function | Connection | Protocol |
|----------|----------|------------|----------|
| GPIO 16 | SmartShunt RX | UART2 RX | VE.Direct 19200 baud |
| GPIO 17 | MPPT1 RX | UART1 RX | VE.Direct 19200 baud |
| GPIO 18 | MPPT2 RX | SoftwareSerial RX | VE.Direct 19200 baud |
| GPIO 21 | OLED SDA | I2C Data | 100 kHz |
| GPIO 9  | OLED SCL | I2C Clock | 100 kHz (software/bit-banged, see note below) |
| GND | Common ground | — | All Victron devices' black wires + OLED GND |
| 5V | 5V power input | From converter | ESP32-S3 power |

> **Reserved on ESP32-S3 — do not reuse:** GPIO 19/20 are wired to the native USB D-/D+ lines. GPIO 22–25 don't exist on ESP32-S3 at all, which is why the OLED SCL moved off GPIO 22 and MPPT1 moved off GPIO 19 compared to the original ESP32-WROOM-32 pinout.

> **OLED uses U8g2's SW (bit-banged) I²C driver, not hardware I²C.** The `_HW_I2C` variant has a pathological slowdown on ESP32-S3 (30+ s blocking in `display.begin()`). Bit-banged I²C runs instantly and is perfectly adequate for a 128×64 SSD1306 refreshed once per second. See [src/display.cpp](../../solar-monitor/src/display.cpp).

---

## VE.Direct Protocol

### Protocol Specification

**Communication Parameters:**
- Baud rate: 19200
- Data bits: 8
- Parity: None
- Stop bits: 1
- Voltage: 3.3V TTL
- Direction: TX only (read-only monitoring)

**Data Format:**
- ASCII text-based
- Line format: `Key<TAB>Value<LF>`
- Block terminator: `Checksum<TAB><byte><LF>`
- Updates approximately every second

### Example Data Stream

```
V       13245
I       -5400
SOC     870
TTG     185
Alarm   OFF
Relay   OFF
CE      -52300
Checksum        \xB4
```

### SmartShunt Data Fields

| Key | Description | Unit | Conversion |
|-----|-------------|------|------------|
| V | Battery voltage | mV | Divide by 1000 for volts |
| I | Battery current | mA | Divide by 1000 for amps (negative = discharge) |
| SOC | State of charge | 0.1% | Divide by 10 for percentage |
| TTG | Time to go | minutes | -1 = infinite |
| CE | Consumed Ah | mAh | Negative = consumed |
| Alarm | Alarm condition | text | ON/OFF |
| Relay | Relay state | text | ON/OFF |
| H1 | Depth of deepest discharge | mAh | |
| H2 | Depth of last discharge | mAh | |
| H4 | Number of charge cycles | count | |
| H7 | Minimum battery voltage | mV | |
| H8 | Maximum battery voltage | mV | |

### MPPT Data Fields

| Key | Description | Unit | Conversion |
|-----|-------------|------|------------|
| PID | Product ID | hex | Device model identifier |
| SER# | Serial number | text | Unique device identifier |
| V | Battery voltage | mV | Divide by 1000 |
| I | Battery current | mA | Charge current |
| VPV | Panel voltage | mV | Divide by 1000 |
| PPV | Panel power | W | Direct value |
| CS | Charge state | enum | See charge states below |
| ERR | Error code | enum | 0 = no error |
| LOAD | Load output state | text | ON/OFF |
| IL | Load current | mA | Current from load output |
| H19 | Yield total | 0.01kWh | Multiply by 0.01 |
| H20 | Yield today | 0.01kWh | Multiply by 0.01 |
| H21 | Max power today | W | Direct value |
| H22 | Yield yesterday | 0.01kWh | Multiply by 0.01 |
| H23 | Max power yesterday | W | Direct value |

### Charge States (CS)

| Code | State |
|------|-------|
| 0 | Off |
| 2 | Fault |
| 3 | Bulk |
| 4 | Absorption |
| 5 | Float |
| 6 | Storage |
| 7 | Equalize |

### Error Codes (ERR)

| Code | Description |
|------|-------------|
| 0 | No error |
| 2 | Battery voltage too high |
| 17 | Charger temperature too high |
| 18 | Charger over current |
| 19 | Charger current reversed |
| 20 | Bulk time limit exceeded |
| 33 | Input voltage too high (solar panel) |
| 34 | Input current too high (solar panel) |

---

## MQTT Output and OTA Updates

The firmware publishes sensor telemetry over MQTT (consumed by Telegraf → TimescaleDB) and accepts OTA firmware pushes. Both are configured in `solar-monitor/include/secrets.h`.

### MQTT topics

All topics use the prefix `esp-sensor-hub/<sanitized-device-name>/` (spaces in the device name become hyphens) so they share Telegraf's `esp-sensor-hub/+/+` subscription with the temperature-sensor fleet.

| Topic | Retain | Cadence | Payload |
|-------|--------|---------|---------|
| `.../battery` | no | 30 s (when valid) | SmartShunt snapshot |
| `.../solar`   | no | 30 s (when valid) | Both MPPTs in one document (nested `mppt1`/`mppt2` objects) |
| `.../status`  | **yes** | 30 s | Device health + per-channel validity flags |
| `.../events`  | no | on-event | Boot, WiFi lifecycle, sensor errors, OTA lifecycle |

Full payload schemas and example documents live in [CONFIG.md](CONFIG.md#mqtt-topics).

### OTA updates

`platformio.ini` exposes two environments:

- `env:esp32-s3-devkitc-1` — USB flash via the CH343 UART port (first flash only)
- `env:ota` — ArduinoOTA over WiFi, inherits everything else, password via env var

```bash
# First time (USB)
pio run -e esp32-s3-devkitc-1 -t upload

# Subsequent updates (OTA)
OTA_PASSWORD=<your-pw> pio run -e ota -t upload
```

The OTA password is never stored in `platformio.ini` — `upload_flags` reads it from the `OTA_PASSWORD` shell variable. The same password must be set in `secrets.h` (consumed by the firmware side).

OTA lifecycle events (`ota_start`, `ota_complete`, `ota_error`) are published to `.../events`, which is a convenient remote audit trail.

---

## API Endpoints

The ESP32-S3 runs a web server providing JSON API endpoints and an HTML dashboard.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Simple HTML dashboard |
| `/api/battery` | GET | SmartShunt data (JSON) |
| `/api/solar` | GET | Both MPPTs data (JSON) |
| `/api/system` | GET | Combined system status (JSON) |

### Example Response: `/api/battery`

```json
{
  "voltage": 13.25,
  "current": -2.34,
  "soc": 85.0,
  "time_remaining": 240,
  "consumed_ah": 15.2,
  "alarm": false,
  "relay": false,
  "last_update": 1234567890,
  "valid": true
}
```

### Example Response: `/api/solar`

```json
{
  "mppt1": {
    "product_id": "0xA060",
    "serial_number": "HQ2145ABCDE",
    "pv_voltage": 18.65,
    "pv_power": 145,
    "charge_current": 4.5,
    "charge_state": "BULK",
    "error": 0,
    "yield_today": 2.34,
    "yield_yesterday": 3.12,
    "max_power_today": 250,
    "valid": true
  },
  "mppt2": {
    "product_id": "0xA060",
    "serial_number": "HQ2145FGHIJ",
    "pv_voltage": 19.23,
    "pv_power": 156,
    "charge_current": 5.1,
    "charge_state": "BULK",
    "error": 0,
    "yield_today": 2.56,
    "yield_yesterday": 3.45,
    "max_power_today": 275,
    "valid": true
  }
}
```

### Example Response: `/api/system`

```json
{
  "battery": {
    "voltage": 13.25,
    "current": -2.34,
    "soc": 85.0,
    "time_remaining": 240
  },
  "solar": {
    "total_pv_power": 301,
    "total_charge_current": 9.6,
    "yield_today_total": 4.90
  },
  "system": {
    "uptime": 86400,
    "wifi_rssi": -45,
    "timestamp": 1732320000
  }
}
```

---

## Quick Reference

### Connection Summary

```
ESP32-S3 GPIO 16 (RX2) ←── SmartShunt TX
ESP32-S3 GPIO 17 (RX1) ←── MPPT1 TX
ESP32-S3 GPIO 18 (SW)  ←── MPPT2 TX
ESP32-S3 GPIO 21 (SDA) ←──→ OLED SDA (optional)
ESP32-S3 GPIO  9 (SCL) ←──→ OLED SCL (optional)
ESP32-S3 3.3V ──────────→ VE.Direct VCC (all 3)
ESP32-S3 GND ───────────→ Common ground
ESP32-S3 5V  ←────────── 5V from converter
```

### VE.Direct Settings

- **Baud Rate:** 19200, 8N1
- **Voltage:** 3.3V TTL (ESP32 compatible)
- **Protocol:** ASCII text mode (key=value pairs)
- **Update Rate:** ~1 second per block

### WiFi Configuration

- **Initial Setup:** connect to the `SolarMonitor-Setup` AP on first boot (or after a double-reset)
- **Portal:** WiFiManager captive portal at `http://192.168.4.1`
- **Double Reset:** press the reset button twice within 3 seconds to re-enter config mode (ESP_DoubleResetDetector in RTC memory)
- **Configurable:** WiFi credentials and device name (MQTT broker + OTA password live in `secrets.h`; the device name drives the MQTT topic base `esp-sensor-hub/<sanitized-name>/`)

### OLED Display Pages (if enabled)

The OLED cycles through multiple pages showing:
1. Battery status (voltage, current, SOC)
2. MPPT1 status (PV power, charge state)
3. MPPT2 status (PV power, charge state)
4. Daily statistics (yield, max power)
5. System info (uptime, WiFi, IP)

---

## Troubleshooting

### No Data from a VE.Direct Device

**Symptoms:** the corresponding `smartshunt_valid` / `mppt1_valid` / `mppt2_valid` flag in the retained `.../status` MQTT topic stays `false`.

**Checks (in order):**
1. **Wrong signal wire** — yellow↔white are swapped on some cables (the SmartShunt in this deployment ships with white=TX). Swap the two non-GND wires and retry.
2. **Wrong GPIO** — SmartShunt → 16, MPPT1 → 17, MPPT2 → 18. If you see `mppt2_valid: true` when you expected `mppt1_valid`, you're on the wrong pin.
3. **Missing common ground** — the Victron device's black wire must share GND with the ESP32-S3. Without it, the signal is meaningless.
4. **VE.Direct TX port function disabled** — in VictronConnect → *Settings → Ports → TX port function* must be `Normal communication` (per-device, not global).
5. **Victron device not powered** — MPPTs derive their logic power from the battery terminals, not the solar side. With no battery voltage the VE.Direct port is silent. Confirm the device is reachable via VictronConnect's Bluetooth.
6. Probe the TX wire with a scope or LED — expect ~1 Hz bursts at 3.3V TTL.

### ESP32-S3 Not Powering On

**Symptoms:** No LED activity, no WiFi AP
**Checks:**
- Check fuse (should be intact)
- Verify 12V-to-5V converter is working
- Measure voltage at ESP32-S3 5V pin (should be ~5V)
- Check converter input voltage (should be 12V from battery)

### Garbled/Corrupt Data

**Symptoms:** Invalid values, random characters in serial output
**Checks:**
- Verify baud rate is 19200 for all VE.Direct connections
- Check ground connections are solid and low resistance
- Try shorter VE.Direct cables
- Add ferrite beads to VE.Direct cables if near noisy equipment
- Verify 3.3V supply is stable

### OLED Display Not Working

**Symptoms:** OLED remains blank or shows garbage
**Checks:**
- Set `OLED_ENABLED = false` if hardware not connected
- Verify I2C connections (GPIO 21 = SDA, GPIO 9 = SCL)
- Check OLED I2C address (usually 0x3C)
- Verify OLED power (3.3V and GND)
- Check serial output for I2C initialization errors

### WiFi Connection Issues

**Symptoms:** Cannot connect to WiFi, frequent disconnections
**Checks:**
- Double-reset within 3 seconds to enter WiFiManager portal
- Portal AP: `SolarMonitor-Setup` at `http://192.168.4.1`
- Verify WiFi credentials are correct (case-sensitive)
- Check WiFi signal strength (RSSI in system API)
- Ensure 2.4GHz WiFi is enabled (ESP32 doesn't support 5GHz)
- Check router allows new devices and DHCP has available leases

### Web Server Not Accessible

**Symptoms:** Cannot reach API endpoints or dashboard
**Checks:**
- Verify ESP32-S3 is connected to WiFi (check serial output)
- Confirm IP address (shown on OLED or in serial output)
- Try accessing from same network/subnet
- Check firewall settings
- Verify web server started (check serial output for "Web server started")

---

## Integration with Backend

This solar monitor integrates with the same Raspberry Pi infrastructure as the temperature sensors:

- **MQTT broker (Mosquitto):** message transport under `esp-sensor-hub/<device>/` topics
- **Telegraf:** consumes MQTT topics and writes to TimescaleDB
- **TimescaleDB:** time-series storage
- **Grafana:** dashboard visualization
- **Home Assistant:** automation and alerts

See [CONFIG.md](CONFIG.md) for the full topic schema and payload examples.

See the main [repository README](../../README.md) for backend setup details.

---

## Resources

### Official Documentation
- [Victron VE.Direct Protocol FAQ](https://www.victronenergy.com/live/vedirect_protocol:faq)
- [VE.Direct Protocol Whitepaper](https://www.victronenergy.com/upload/documents/Whitepaper-Data-communication-with-Victron-Energy-products_EN.pdf)
- [ESP32 Arduino Core Documentation](https://docs.espressif.com/projects/arduino-esp32/)

### Community Resources
- [DIY Solar Forum](https://diysolarforum.com)
- [Victron Community](https://community.victronenergy.com)

### Example Projects
- [VeDirectFrameHandler](https://github.com/karioja/VeDirectFrameHandler)
- [ESP32 VE.Direct](https://github.com/cterwilliger/VEDirect)

---

**Last Updated:** December 2, 2025
**Status:** ✅ Implemented and operational
