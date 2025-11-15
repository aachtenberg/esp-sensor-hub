# ESP12F DS18B20 Temperature Sensor

Multi-board temperature sensor project supporting ESP32 and ESP8266 with cloud data logging.

## Quick Start

1. **Setup**: See [docs/SETUP.md](docs/SETUP.md)
2. **Flash Device**: See [docs/guides/DEVICE_FLASHING_QUICK_GUIDE.md](docs/guides/DEVICE_FLASHING_QUICK_GUIDE.md)
3. **Scripts**: All flashing/deployment scripts in `scripts/`

## Project Structure

```
├── src/                    # Main application code
├── include/                # Header files (config, secrets)
├── lib/                    # Local libraries (OneWire, DallasTemperature)
├── test/                   # Test files
├── docs/                   # Documentation (organized by category)
│   ├── api/               # AWS Lambda, InfluxDB, MQTT docs
│   ├── guides/            # How-to guides
│   ├── architecture/      # Technical design
│   └── reference/         # Reference material
├── scripts/               # Utility scripts (flash, deploy, CDK)
├── platformio.ini         # PlatformIO configuration
└── .gitignore            # Git ignore rules
```

## Supported Boards

- **ESP32** (esp32dev)
- **ESP8266** (nodemcuv2)

## Documentation

- [Full Setup Guide](docs/SETUP.md)
- [Architecture & Code Structure](docs/architecture/CODE_STRUCTURE.md)
- [Flashing & Device Setup](docs/guides/)
- [API Integration Guides](docs/api/)

## Building & Flashing

```bash
# Build and flash ESP8266
scripts/flash_device.sh "Device Name" esp8266

# Build and flash ESP32
scripts/flash_device.sh "Device Name" esp32
```

See [docs/SETUP.md](docs/SETUP.md) for detailed build instructions.
