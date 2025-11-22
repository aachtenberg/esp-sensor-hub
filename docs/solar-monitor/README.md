# ESP32 Solar Monitor

WiFi-enabled monitoring system for Victron Energy solar equipment using ESP32 microcontroller.

**Status:** Planning phase

## Features (Planned)

- Real-time battery monitoring (Victron SmartShunt)
- Solar charge controller monitoring (Victron SmartSolar MPPT)
- WiFi connectivity with web dashboard
- JSON API for third-party integrations
- Historical data tracking
- Low power consumption (~1.5 Ah/day)

## Hardware Requirements

- ESP32-WROOM-32 Development Board
- Victron SmartShunt 500A (or any Victron device with VE.Direct)
- Victron SmartSolar MPPT (or any VE.Direct-compatible charge controller)
- 2x VE.Direct to Serial cables
- 12V-to-5V power supply (waterproof recommended)

**Estimated Cost:** ~$60-70 (excluding Victron equipment)

## VE.Direct Protocol

VE.Direct is Victron's proprietary serial protocol:
- **Voltage:** 3.3V TTL (ESP32 compatible, no level shifter needed)
- **Baud Rate:** 19200
- **Format:** Text-based key-value pairs
- **Connection:** 3.5mm audio jack style connector

### Key Data Points

**From SmartShunt:**
- Battery voltage (V)
- Current (A) - positive = charging, negative = discharging
- Power (W)
- State of Charge (SOC %)
- Time to Go (TTG minutes)

**From MPPT:**
- PV voltage (V)
- PV power (W)
- Charge current (A)
- Charge state (Off/Bulk/Absorption/Float)
- Yield today (kWh)

## ESP32 Pin Configuration

```
ESP32-WROOM-32
├── GPIO 16 (UART2 RX) → SmartShunt VE.Direct TX
├── GPIO 19 (UART1 RX) → MPPT VE.Direct TX
├── 3.3V → VE.Direct power (both devices)
└── GND → VE.Direct ground (both devices)
```

**Note:** VE.Direct TX only - we only read data, no transmission needed.

## API Endpoints (Planned)

- `GET /` - Web dashboard
- `GET /api/data` - All data (JSON)
- `GET /api/shunt` - SmartShunt data only (JSON)
- `GET /api/mppt` - MPPT data only (JSON)

### Example JSON Response

```json
{
  "smartshunt": {
    "voltage": 13.25,
    "current": -2.34,
    "power": -31,
    "soc": 85.0,
    "ttg": 240
  },
  "mppt": {
    "pv_voltage": 18.65,
    "pv_power": 60,
    "charge_current": 4.5,
    "charge_state": "BULK",
    "yield_today": 1.25
  }
}
```

## Integration

This project will integrate with the same infrastructure as the temperature sensors:
- InfluxDB for data storage
- Grafana for dashboards
- Home Assistant for automation
- MQTT for real-time updates (optional)

## Documentation

- [Bill of Materials](BOM.md) - Component list with prices
- [Wiring Guide](WIRING.md) - Connection instructions
- [Quick Reference](QUICK_REFERENCE.md) - Pin connections at a glance

## Resources

- [Victron VE.Direct Protocol FAQ](https://www.victronenergy.com/live/vedirect_protocol:faq)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [DIY Solar Forum](https://diysolarforum.com)
