# Bill of Materials (BOM) - ESP12F DS18B20 PCB

## For JLCPCB SMT Assembly

**Quantity**: 10 boards

---

## Component List with LCSC Part Numbers

| # | Component | Value | Package | Qty/Board | LCSC Part # | Type | Unit Price | Notes |
|---|-----------|-------|---------|-----------|-------------|------|------------|-------|
| 1 | ESP-12F | - | Module | 1 | C82891 | Extended | ~$2.00 | WiFi MCU module |
| 2 | CH340C | - | SOP-16 | 1 | C84681 | Basic | ~$0.40 | USB-UART (no crystal needed) |
| 3 | AMS1117-3.3 | 3.3V | SOT-223 | 1 | C6186 | Basic | ~$0.05 | Voltage regulator |
| 4 | USB-C Connector | 16P | SMD | 1 | C167321 | Basic | ~$0.10 | Power & programming |
| 5 | Resistor | 10kΩ | 0805 | 4 | C17414 | Basic | ~$0.002 | EN, GPIO0, GPIO2, GPIO15 |
| 6 | Resistor | 4.7kΩ | 0805 | 1 | C17673 | Basic | ~$0.002 | DS18B20 pull-up |
| 7 | Resistor | 5.1kΩ | 0805 | 2 | C27834 | Basic | ~$0.002 | USB-C CC1/CC2 |
| 8 | Resistor | 1kΩ | 0805 | 1 | C17513 | Basic | ~$0.002 | LED current limit |
| 9 | Capacitor | 10µF | 0805 | 2 | C15850 | Basic | ~$0.01 | Regulator in/out |
| 10 | Capacitor | 100nF | 0603 | 3 | C14663 | Basic | ~$0.002 | Decoupling (CH340, DTR, RTS) |
| 11 | LED | Blue | 0805 | 1 | C2293 | Basic | ~$0.02 | Status indicator |
| 12 | Tactile Switch | 4x4mm | SMD | 2 | C318884 | Basic | ~$0.02 | Reset + Flash buttons |
| 13 | Screw Terminal | 3-pin | 2.54mm | 1 | C475098 | Extended | ~$0.15 | DS18B20 connection |

---

## Cost Breakdown (10 Boards)

### PCB Fabrication
| Item | Cost |
|------|------|
| 2-layer PCB, 50x35mm, 10pcs | ~$2-5 |
| Green solder mask, HASL | Included |
| Shipping (standard) | ~$3-5 |

### SMT Assembly
| Item | Cost |
|------|------|
| Assembly setup fee | ~$8 |
| Per-component placement | ~$0.02/placement |
| Extended parts fee | ~$3/unique part |

### Components (for 10 boards)
| Component | Qty Total | Est. Cost |
|-----------|-----------|-----------|
| ESP-12F | 10 | ~$20.00 |
| CH340C | 10 | ~$4.00 |
| AMS1117-3.3 | 10 | ~$0.50 |
| USB-C Connector | 10 | ~$1.00 |
| Resistors (all) | 80 | ~$0.50 |
| Capacitors (all) | 50 | ~$0.50 |
| LEDs | 10 | ~$0.20 |
| Buttons | 20 | ~$0.40 |
| Screw Terminals | 10 | ~$1.50 |
| **Component Total** | | **~$28-30** |

### Total Estimated Cost
| Item | Cost |
|------|------|
| PCB Fabrication | ~$5 |
| SMT Assembly | ~$15 |
| Components | ~$30 |
| Shipping | ~$5-15 |
| **Grand Total** | **~$55-65** |
| **Per Board** | **~$5.50-6.50** |

---

## Basic vs Extended Parts

**JLCPCB Part Types:**
- **Basic Parts**: Stocked in SMT machines, no extra fee
- **Extended Parts**: Require $3 fee per unique part type

**Our BOM:**
- Basic parts: CH340C, AMS1117, USB-C, all resistors, capacitors, LED, buttons
- Extended parts: ESP-12F (~$3 fee), Screw Terminal (~$3 fee)
- **Total extended part fees**: ~$6

---

## Alternative Parts (Cost Optimization)

### Option 1: ESP-12F as Through-Hole (Hand Solder)
Skip SMT assembly for ESP-12F, solder it yourself:
- Remove ESP-12F from JLCPCB BOM
- Buy ESP-12F modules separately from AliExpress (~$1.50 each)
- Saves: ~$3 extended fee + assembly cost
- Requires: Soldering skills (castellated pads)

### Option 2: Use Pin Headers Instead of Screw Terminal
Replace screw terminal with standard 2.54mm pin header:
- LCSC: C2337 (1x3 male header) - Basic part, ~$0.02
- Saves: ~$3 extended fee
- Trade-off: Less secure connection for DS18B20 wire

### Option 3: CH340G Instead of CH340C
- CH340G requires external 12MHz crystal
- More components, but CH340G is slightly cheaper
- **Not recommended** - CH340C simplicity is worth it

---

## LCSC Part Details

### ESP-12F (C82891)
```
Manufacturer: Ai-Thinker
Package: Module (24.8mm x 16mm)
Operating Voltage: 3.0-3.6V
Flash: 4MB
WiFi: 802.11 b/g/n
```

### CH340C (C84681)
```
Manufacturer: WCH
Package: SOP-16 (3.9mm x 10mm)
Built-in oscillator: Yes (no external crystal!)
Max Baud: 2Mbps
Operating Voltage: 3.3V-5V
```

### AMS1117-3.3 (C6186)
```
Manufacturer: AMS
Package: SOT-223
Output: 3.3V, 1A
Dropout: ~1.1V
Input Range: 4.5V-12V
```

### USB Type-C 16P (C167321)
```
Manufacturer: SHOU HAN
Type: Receptacle, right-angle
Pins: 16 (full featured)
Current Rating: 3A
```

### Tactile Switch (C318884)
```
Manufacturer: SHOU HAN
Size: 4x4x1.5mm
Travel: 0.25mm
Operating Force: 160gf
Life: 100,000 cycles
```

---

## Parts to Order Separately

These parts are NOT included in JLCPCB assembly:

| Part | Where to Buy | Est. Cost |
|------|--------------|-----------|
| DS18B20 Waterproof Probe | Amazon/AliExpress | ~$2-5 each |
| USB-C Cable | Amazon | ~$5-10 |
| Enclosure (optional) | Amazon/AliExpress | ~$2-5 each |

---

## BOM CSV for JLCPCB (Copy/Paste Ready)

```csv
Comment,Designator,Footprint,LCSC Part #
ESP-12F,U1,ESP-12F,C82891
CH340C,U2,SOP-16,C84681
AMS1117-3.3,U3,SOT-223,C6186
USB-C-16P,J1,USB-C-SMD,C167321
10kΩ,R1 R2 R3 R4,0805,C17414
4.7kΩ,R5,0805,C17673
5.1kΩ,R6 R7,0805,C27834
1kΩ,R8,0805,C17513
10µF,C1 C2,0805,C15850
100nF,C3 C4 C5,0603,C14663
LED Blue,D1,0805,C2293
Switch,SW1 SW2,4x4mm,C318884
Screw Terminal 3P,J2,P2.54mm,C475098
```

---

## Component Placement Reference

```
Designator Assignment:
- U1: ESP-12F module
- U2: CH340C USB-Serial
- U3: AMS1117-3.3 Regulator
- J1: USB-C Connector
- J2: DS18B20 Screw Terminal
- R1: EN pull-up (10kΩ)
- R2: GPIO0 pull-up (10kΩ)
- R3: GPIO2 pull-up (10kΩ)
- R4: GPIO15 pull-down (10kΩ)
- R5: DS18B20 data pull-up (4.7kΩ)
- R6: USB-C CC1 (5.1kΩ)
- R7: USB-C CC2 (5.1kΩ)
- R8: LED current limiter (1kΩ)
- C1: Regulator input (10µF)
- C2: Regulator output (10µF)
- C3: CH340C V3 decoupling (100nF)
- C4: DTR to EN (100nF)
- C5: RTS to GPIO0 (100nF)
- D1: Status LED (Blue)
- SW1: Reset button
- SW2: Flash button
```
