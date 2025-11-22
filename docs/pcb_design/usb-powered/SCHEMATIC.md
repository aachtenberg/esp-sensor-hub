# ESP12F DS18B20 Temperature Sensor - PCB Schematic

## Block Diagram

```
                                    ┌─────────────────────────────────────┐
                                    │           ESP-12F Module            │
    ┌──────────┐    ┌──────────┐    │                                     │
    │  USB-C   │───▶│ CH340C   │───▶│  TX/RX (GPIO1/GPIO3)               │
    │          │    │ USB-UART │    │                                     │
    │  5V/GND  │    │          │    │  GPIO4 ──────────────▶ DS18B20     │
    └──────────┘    └──────────┘    │                                     │
         │                          │  GPIO2 ──────────────▶ Status LED  │
         ▼                          │                                     │
    ┌──────────┐                    │  EN, GPIO0, GPIO15 (boot config)   │
    │AMS1117   │                    │                                     │
    │ 3.3V Reg │───────────────────▶│  3.3V Power                        │
    └──────────┘                    └─────────────────────────────────────┘
```

---

## Complete Schematic - Connection Details

### 1. USB-C Power Input

```
USB-C Connector (16-pin)
├── VBUS (Pin A4, B4, A9, B9) ────────▶ +5V Rail
├── GND (Pin A1, B1, A12, B12) ───────▶ GND Rail
├── D+ (Pin A6) ──────────────────────▶ CH340C D+
├── D- (Pin A7) ──────────────────────▶ CH340C D-
├── CC1 (Pin A5) ─────┬───[5.1kΩ]────▶ GND (UFP identification)
└── CC2 (Pin B5) ─────┘
```

**Note**: The 5.1kΩ resistors on CC1/CC2 identify the device as a USB sink (power consumer).

---

### 2. Voltage Regulator (AMS1117-3.3)

```
         5V Rail
            │
            ▼
    ┌───────────────┐
    │   AMS1117     │
    │    3.3V       │
    │               │
    │ VIN    VOUT   │──────▶ 3.3V Rail
    │       GND    │
    └───────┬───────┘
            │
           GND

Capacitors:
- C1: 10µF ceramic (5V to GND) - Input capacitor
- C2: 10µF ceramic (3.3V to GND) - Output capacitor
```

**AMS1117-3.3 Pinout (SOT-223):**
- Pin 1: GND/Adjust
- Pin 2: VOUT (3.3V)
- Pin 3: VIN (5V)
- Tab: VOUT (connected to Pin 2)

---

### 3. CH340C USB-to-Serial Converter

```
                    ┌─────────────────┐
         5V ───────▶│ VCC (Pin 16)    │
                    │                 │
        GND ───────▶│ GND (Pin 1)     │
                    │                 │
USB D+ ────────────▶│ D+ (Pin 5)      │
                    │                 │
USB D- ────────────▶│ D- (Pin 6)      │
                    │                 │
                    │ TXD (Pin 2) ────│───────▶ ESP RXD (GPIO3)
                    │                 │
                    │ RXD (Pin 3) ◀───│──────── ESP TXD (GPIO1)
                    │                 │
                    │ DTR (Pin 13)────│───┐
                    │                 │   │    Auto-Reset Circuit
                    │ RTS (Pin 14)────│───┼──▶ (see below)
                    │                 │   │
                    │ V3 (Pin 4) ─────│───┼──[100nF]──▶ GND
                    └─────────────────┘   │
                                          ▼
                                    To ESP EN & GPIO0
```

**CH340C Features:**
- Built-in oscillator (no external crystal needed!)
- Works with 5V power
- V3 pin needs 100nF decoupling capacitor to GND

---

### 4. Auto-Reset Circuit (for programming)

This circuit allows the ESP to be programmed without manually pressing buttons:

```
                DTR (from CH340C)
                      │
                      │
                    ──┴──
                   │     │ 100nF
                    ──┬──
                      │
                      ├─────────────────────▶ ESP EN (Reset)
                      │
                     ─┴─
                      ▼ 1N4148 (optional)
                      │
                RTS ──┴──────────────────────▶ ESP GPIO0


Alternative simpler circuit (works for most cases):

        DTR ────[100nF]────▶ ESP EN

        RTS ────[100nF]────▶ ESP GPIO0
```

---

### 5. ESP-12F Module Connections

```
ESP-12F Pin Layout (Top View):
                    ┌─────────────────────┐
                    │      Antenna        │
                    │         ░░░         │
         RST/EN ◀───│ 1  EN        GPIO0  │───▶ Flash Button / RTS
           ADC ◀────│ 2  ADC0      GPIO2  │───▶ Status LED
       (NC) ◀───────│ 3  CH_PD     GPIO15 │───▶ [10kΩ] ──▶ GND
      GPIO16 ◀──────│ 4  GPIO16    GND    │───▶ GND
      GPIO14 ◀──────│ 5  GPIO14    GPIO13 │───▶ (available)
      GPIO12 ◀──────│ 6  GPIO12    GPIO12 │
      GPIO13 ◀──────│ 7  GPIO13    VCC    │───▶ 3.3V
         VCC ◀──────│ 8  VCC       GPIO4  │───▶ DS18B20 Data
                    │                     │
          TX ◀──────│ TX (GPIO1)   GPIO5  │───▶ (available)
          RX ◀──────│ RX (GPIO3)   GPIO0  │
         GND ◀──────│ GND          GPIO2  │
                    └─────────────────────┘
```

**Boot Configuration Resistors:**

```
3.3V Rail
    │
    ├───[10kΩ]───▶ EN (Pin 1) - Must be HIGH for operation
    │
    ├───[10kΩ]───▶ GPIO0 - HIGH for normal boot, LOW for flash
    │                      (directly if using manual flash button)
    │                      (or via auto-reset circuit)
    │
    └───[10kΩ]───▶ GPIO2 - Internal pull-up usually sufficient
                          (external 10kΩ recommended for reliability)

GND Rail
    │
    └───[10kΩ]───▶ GPIO15 - Must be LOW for boot from flash
```

---

### 6. DS18B20 Temperature Sensor Connection

```
3.3V Rail
    │
    └───[4.7kΩ]───┬───▶ Screw Terminal Pin 2 (Data/Yellow wire)
                  │
                  └───▶ ESP GPIO4


Screw Terminal (3-pin, 2.54mm pitch):
┌─────┬─────┬─────┐
│ VCC │ DAT │ GND │
│  1  │  2  │  3  │
└──┬──┴──┬──┴──┬──┘
   │     │     │
   ▼     ▼     ▼
 3.3V  GPIO4  GND
       (with 4.7kΩ
        pull-up)


DS18B20 Wire Colors (standard):
- Red:    VCC (3.3V)
- Yellow: Data (GPIO4)
- Black:  GND
```

---

### 7. Status LED

```
3.3V Rail (or ESP GPIO2 for controllable LED)
    │
    └───[1kΩ]───▶ LED Anode (+)
                       │
                  LED Cathode (-)
                       │
                      GND (if power LED)
                       │
                      or
                       │
                  ESP GPIO2 (if status LED, active LOW)


Option A - Power LED (always on when powered):
    3.3V ───[1kΩ]───▶│───▶ GND


Option B - GPIO2 Status LED (controllable, directly off GPIO2):
    3.3V ───[1kΩ]───▶│───▶ GPIO2

    (GPIO2 LOW = LED ON, GPIO2 HIGH = LED OFF)
    Note: GPIO2 must be HIGH at boot, LED will blink during boot
```

**Recommended**: Use Option B (GPIO2) so you can blink it in code for status indication.

---

### 8. Buttons

**Reset Button:**
```
ESP EN Pin ◀───┬───[10kΩ]───▶ 3.3V (pull-up)
               │
               └───[Switch]───▶ GND

Pressing button pulls EN LOW, resetting the ESP.
```

**Flash Button (GPIO0):**
```
ESP GPIO0 ◀───┬───[10kΩ]───▶ 3.3V (pull-up, for normal boot)
              │
              └───[Switch]───▶ GND

To enter flash mode:
1. Hold Flash button (GPIO0 LOW)
2. Press and release Reset button
3. Release Flash button
4. ESP is now in bootloader mode
```

---

## Complete Schematic Diagram (ASCII)

```
                              USB-C
                         ┌─────┴─────┐
                         │ VBUS  GND │
                         │  D+   D-  │
                         │ CC1  CC2  │
                         └──┬──┬─┬─┬─┘
                            │  │ │ │
              ┌─────────────┘  │ │ └───[5.1kΩ]───┐
              │                │ │               │
              ▼                │ │              GND
           ┌──────┐            │ │
     5V ───┤ 10µF ├─── GND     │ │
           └──┬───┘            │ │
              │                │ │
              ▼                ▼ ▼
         ┌─────────┐      ┌─────────┐
   5V ───┤AMS1117  ├──┬──▶│ CH340C  │◀── D+/D-
         │  3.3V   │  │   │         │
         └────┬────┘  │   │ TXD ────│─────────────────────────▶ ESP RXD
              │       │   │ RXD ◀───│────────────────────────── ESP TXD
           ┌──┴──┐    │   │ DTR ────│──[100nF]───┬────────────▶ ESP EN
           │10µF │    │   │ RTS ────│──[100nF]───┼────────────▶ ESP GPIO0
           └──┬──┘    │   │ V3 ─────│──[100nF]─▶GND            │
              │       │   └─────────┘                          │
             GND      │                                        │
                      │   3.3V Rail                            │
                      └────┬───────────────────────────────────┤
                           │                                   │
                           ├───[10kΩ]──────────────────────────┴──▶ ESP EN
                           │
                           ├───[10kΩ]─────────────────────────────▶ ESP GPIO0
                           │                                             │
                           ├───[10kΩ]─────────────────────────────▶ ESP GPIO2
                           │                                             │
                           │                            ┌────────────────┘
                           │                            │
                           │                      ┌─────┴─────┐
                           │                      │  ESP-12F  │
                           ├──────────────────────│ VCC   GND │─────▶ GND
                           │                      │           │
                           │                      │ GPIO4 ────│───┬──▶ DS18B20 DATA
                           │                      │           │   │
                           └───[4.7kΩ]────────────│───────────│───┘
                                                  │           │
                                                  │ GPIO2 ◀───│───[1kΩ]───▶│───▶ 3.3V (LED)
                                                  │           │
                                                  └───────────┘

GND ◀───[10kΩ]───▶ ESP GPIO15

GND ◀───[RESET BTN]───▶ ESP EN

GND ◀───[FLASH BTN]───▶ ESP GPIO0


DS18B20 Screw Terminal:
┌─────┬─────┬─────┐
│3.3V │DATA │ GND │
└──┬──┴──┬──┴──┬──┘
   │     │     │
   ▼     │     ▼
 3.3V    │    GND
         │
    GPIO4 + 4.7kΩ pull-up
```

---

## Net List Summary

| Net Name | Connected Components |
|----------|---------------------|
| 5V | USB VBUS, AMS1117 VIN, CH340C VCC |
| 3.3V | AMS1117 VOUT, ESP VCC, Pull-up resistors, LED, DS18B20 VCC |
| GND | All ground pins |
| D+ | USB D+, CH340C D+ |
| D- | USB D-, CH340C D- |
| TXD | CH340C TXD, ESP RXD (GPIO3) |
| RXD | CH340C RXD, ESP TXD (GPIO1) |
| DTR | CH340C DTR, 100nF cap to EN |
| RTS | CH340C RTS, 100nF cap to GPIO0 |
| EN | ESP EN, 10kΩ to 3.3V, Reset button, DTR cap |
| GPIO0 | ESP GPIO0, 10kΩ to 3.3V, Flash button, RTS cap |
| GPIO2 | ESP GPIO2, LED via 1kΩ, 10kΩ to 3.3V |
| GPIO4 | ESP GPIO4, DS18B20 Data, 4.7kΩ to 3.3V |
| GPIO15 | ESP GPIO15, 10kΩ to GND |

---

## Design Notes

1. **CH340C vs CH340G**: Using CH340C because it has an internal oscillator - no external 12MHz crystal needed!

2. **USB-C CC Resistors**: The 5.1kΩ resistors on CC1/CC2 are required for USB-C compliance. They tell the host this is a power-consuming device.

3. **Auto-Reset**: The DTR/RTS to EN/GPIO0 circuit allows automatic reset into bootloader mode when uploading code from PlatformIO/Arduino IDE.

4. **GPIO2 LED**: GPIO2 must be HIGH during boot. With the LED connected between 3.3V and GPIO2, when GPIO2 is HIGH, no current flows (LED off). When GPIO2 is LOW, LED turns on. This is "active LOW" logic.

5. **Power Sequencing**: The AMS1117 provides stable 3.3V. The 10µF caps are essential for stability.

6. **DS18B20 Pull-up**: The 4.7kΩ value is optimal for the 3.3V logic level and typical cable lengths (up to ~10m).
