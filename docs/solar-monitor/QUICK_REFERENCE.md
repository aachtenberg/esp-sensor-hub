# Quick Reference Card

## ESP32 Pin Connections

```
ESP32 GPIO 16 (RX2) ←── SmartShunt TX
ESP32 GPIO 19 (RX1) ←── MPPT TX
ESP32 3.3V ──────────→ VE.Direct VCC (both)
ESP32 GND ───────────→ VE.Direct GND (both)
ESP32 VIN ←────────── 5V from 12V-to-5V converter
```

## VE.Direct Settings

- **Baud Rate:** 19200
- **Voltage:** 3.3V TTL
- **Protocol:** Text mode (key=value pairs)

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Web dashboard |
| `GET /api/data` | All data (JSON) |
| `GET /api/shunt` | SmartShunt only |
| `GET /api/mppt` | MPPT only |

## SmartShunt Data Fields

| Field | Key | Unit | Description |
|-------|-----|------|-------------|
| Voltage | V | mV | Battery voltage |
| Current | I | mA | Battery current |
| Power | P | W | Instantaneous power |
| SOC | SOC | % | State of charge |
| TTG | TTG | min | Time to go |

## MPPT Data Fields

| Field | Key | Unit | Description |
|-------|-----|------|-------------|
| PV Voltage | VPV | mV | Solar panel voltage |
| PV Power | PPV | W | Solar panel power |
| Battery Voltage | V | mV | Battery voltage |
| Charge Current | I | mA | Charging current |
| Charge State | CS | - | 0=Off, 3=Bulk, 4=Absorption, 5=Float |
| Yield Today | H20 | 0.01kWh | Energy harvested today |

## Charge States

| Code | State |
|------|-------|
| 0 | Off |
| 2 | Fault |
| 3 | Bulk |
| 4 | Absorption |
| 5 | Float |
| 6 | Storage |
| 7 | Equalize |

## Troubleshooting

| Symptom | Check |
|---------|-------|
| No SmartShunt data | GPIO 16, cable, VE.Direct enabled |
| No MPPT data | GPIO 19, cable, VE.Direct enabled |
| No power | Fuse, 5V converter, VIN connection |
| Corrupt data | Ground connection, baud rate 19200 |
