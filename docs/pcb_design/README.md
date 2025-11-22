# PCB Designs

This directory contains custom PCB designs for the ESP12F DS18B20 temperature sensor project.

## Available Designs

### [USB-Powered](usb-powered/) (v1.0 - Current)

A compact USB-C powered board for indoor/permanent installations.

**Features:**
- USB-C power input (5V)
- AMS1117-3.3V voltage regulator
- CH340C USB-to-Serial (no external crystal needed)
- Auto-reset circuit for easy programming
- DS18B20 temperature sensor connection (GPIO4)
- Status LED on GPIO2
- Reset and Flash buttons
- Board size: 50mm x 35mm

**Use Cases:**
- Indoor temperature monitoring
- Locations with USB power available
- Permanent installations

**Files:**
- [SCHEMATIC.md](usb-powered/SCHEMATIC.md) - Circuit schematic
- [BOARD_LAYOUT.md](usb-powered/BOARD_LAYOUT.md) - PCB layout details
- [BOM.md](usb-powered/BOM.md) - Bill of materials with LCSC part numbers
- [ORDERING_GUIDE.md](usb-powered/ORDERING_GUIDE.md) - JLCPCB ordering instructions
- Manufacturing files (Gerber, BOM CSV, Pick & Place)

### Solar-Battery (Planned)

A solar-powered variant with battery backup for outdoor/remote installations.

**Planned Features:**
- Solar panel input (5-6V)
- LiPo/18650 battery with charge controller
- Deep sleep support for power efficiency
- Battery voltage monitoring via ADC
- Weatherproof enclosure compatibility

**Status:** In development

## Choosing a Design

| Feature | USB-Powered | Solar-Battery |
|---------|-------------|---------------|
| Power Source | USB-C 5V | Solar + Battery |
| Best For | Indoor | Outdoor/Remote |
| Always On | Yes | Deep sleep cycles |
| Programming | USB direct | USB or serial header |
| Cost | ~$6-7/board | TBD |

## Manufacturing

All designs are created in EasyEDA and exported for JLCPCB manufacturing. See each design's ORDERING_GUIDE.md for step-by-step instructions.
