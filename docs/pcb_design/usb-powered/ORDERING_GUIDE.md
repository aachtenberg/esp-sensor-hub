# Step-by-Step Guide: EasyEDA Design & JLCPCB Ordering

## Overview

This guide walks you through:
1. Creating the PCB design in EasyEDA (free online tool)
2. Ordering assembled PCBs from JLCPCB with SMT service

**Time estimate**: 2-4 hours for design, 2-3 weeks for delivery

---

## Part 1: Setting Up EasyEDA

### Step 1: Create an Account

1. Go to [https://easyeda.com](https://easyeda.com)
2. Click "Sign Up" (or use Google/GitHub login)
3. Verify your email

### Step 2: Create a New Project

1. Click **"File" → "New" → "Project"**
2. Name it: `ESP12F-DS18B20-Sensor`
3. Click **Create**

### Step 3: Create a New Schematic

1. Right-click the project → **"New" → "Schematic"**
2. Name it: `Main`

---

## Part 2: Building the Schematic

### Step 4: Add Components from LCSC Library

For each component, search by LCSC part number:

1. Click **"Library"** icon (or press `Shift+F`)
2. In search box, enter the LCSC part number
3. Click component → **"Place"**
4. Click on schematic to place

**Components to add:**

| Search Term | Component | Qty |
|-------------|-----------|-----|
| C82891 | ESP-12F | 1 |
| C84681 | CH340C | 1 |
| C6186 | AMS1117-3.3 | 1 |
| C167321 | USB-C 16P | 1 |
| C17414 | 10kΩ 0805 | 4 |
| C17673 | 4.7kΩ 0805 | 1 |
| C27834 | 5.1kΩ 0805 | 2 |
| C17513 | 1kΩ 0805 | 1 |
| C15850 | 10µF 0805 | 2 |
| C14663 | 100nF 0603 | 3 |
| C2293 | Blue LED 0805 | 1 |
| C318884 | Tactile Switch | 2 |
| C475098 | 3P Screw Terminal | 1 |

### Step 5: Wire the Schematic

Use the **"Wire"** tool (shortcut: `W`) to connect components.

**Connection checklist:**

#### Power Section:
```
USB VBUS → AMS1117 VIN → CH340C VCC
                ↓
            AMS1117 VOUT → ESP VCC → All 3.3V connections

USB GND → AMS1117 GND → CH340C GND → ESP GND → All GND
```

#### USB-C:
```
USB D+ → CH340C D+
USB D- → CH340C D-
USB CC1 → R6 (5.1kΩ) → GND
USB CC2 → R7 (5.1kΩ) → GND
```

#### CH340C to ESP:
```
CH340C TXD → ESP RXD (GPIO3)
CH340C RXD → ESP TXD (GPIO1)
CH340C DTR → C4 (100nF) → ESP EN
CH340C RTS → C5 (100nF) → ESP GPIO0
CH340C V3 → C3 (100nF) → GND
```

#### ESP Boot Config:
```
3.3V → R1 (10kΩ) → ESP EN
3.3V → R2 (10kΩ) → ESP GPIO0
3.3V → R3 (10kΩ) → ESP GPIO2
GND → R4 (10kΩ) → ESP GPIO15
```

#### DS18B20:
```
3.3V → R5 (4.7kΩ) → Screw Terminal Pin 2 (DATA)
ESP GPIO4 → Screw Terminal Pin 2 (DATA)
3.3V → Screw Terminal Pin 1 (VCC)
GND → Screw Terminal Pin 3 (GND)
```

#### Buttons:
```
GND → SW1 (Reset) → ESP EN
GND → SW2 (Flash) → ESP GPIO0
```

#### Status LED:
```
3.3V → R8 (1kΩ) → LED Anode
LED Cathode → ESP GPIO2
```

#### Capacitors:
```
C1 (10µF): USB VBUS to GND (at AMS1117 input)
C2 (10µF): 3.3V to GND (at AMS1117 output)
```

### Step 6: Add Net Labels

For cleaner schematic, use net labels instead of long wires:

1. Click **"Net Label"** tool
2. Add labels: `5V`, `3V3`, `GND`, `TX`, `RX`, `DTR`, `RTS`, `GPIO0`, `GPIO2`, `GPIO4`, `EN`

### Step 7: Run Electrical Rule Check (ERC)

1. Click **"Design" → "Electrical Rules Check"**
2. Fix any errors (unconnected pins, etc.)
3. Re-run until clean

---

## Part 3: Creating the PCB Layout

### Step 8: Convert Schematic to PCB

1. Click **"Design" → "Convert Schematic to PCB"**
2. Set board size: **50mm x 35mm**
3. Set layers: **2 layers**
4. Click **"Apply"**

A new PCB document opens with all components (rats nest).

### Step 9: Set Board Outline

1. Select **"Board Outline"** layer
2. Draw rectangle: 50mm x 35mm
3. Or: **"Tools" → "Set Board Outline"** and enter dimensions

### Step 10: Add Mounting Holes

1. Search library for: `Mounting Hole M3`
2. Place 4 holes at corners:
   - (3mm, 3mm)
   - (47mm, 3mm)
   - (3mm, 32mm)
   - (47mm, 32mm)

### Step 11: Place Components

**Placement order:**

1. **USB-C (J1)**: Bottom edge, centered
2. **ESP-12F (U1)**: Center-top, antenna pointing AWAY from board center
3. **CH340C (U2)**: Near USB-C
4. **AMS1117 (U3)**: Between USB and ESP
5. **Screw Terminal (J2)**: Top edge (opposite USB)
6. **Buttons (SW1, SW2)**: Bottom area, accessible
7. **LED (D1)**: Visible location
8. **Passives**: Near their connected ICs

### Step 12: Create Ground Plane (Bottom Layer)

1. In the right panel (Layers), click **"BottomLayer"** to select it
2. In the toolbar, find **"Copper Area"** tool (or **"PCB Tools" → "Copper Area"**)
3. Click to start drawing a rectangle that covers the entire board outline
4. After drawing, a properties dialog appears:
   - Set **Net**: `GND`
   - Set **Layer**: `BottomLayer`
   - Click **OK**
5. The copper area should fill with a crosshatch pattern
6. If it doesn't auto-fill, click **"Rebuild Copper Area"** in the toolbar or right-click → Rebuild

**Important - Antenna Keep-Out Zone:**
The ESP-12F antenna area must have NO copper underneath for good WiFi signal:

1. Select the copper area you just created
2. Look for **"Cutout"** tool (or right-click copper area → "Add Cutout")
3. Draw a rectangle under the ESP antenna area (the part with the zigzag trace pattern)
4. The cutout should be about 15mm x 10mm covering the antenna end

**Alternative if you can't find Copper Area:**
- Try: **"Place" → "Copper Area"**
- Or: Press `Shift+P` then look for copper area option
- Or: Search in the top menu under "PCB Tools"

### Step 13: Route Traces

Use **"Track"** tool (shortcut: `W`) to route connections.

**Routing priority:**
1. USB D+/D- (keep short, parallel)
2. Power traces (5V, 3.3V) - use 0.5mm+ width
3. UART (TX, RX)
4. All other signals

**Tips:**
- Press `L` to switch layers
- Press `V` to place via
- Double-click to end trace
- Use 45° angles (no 90° corners)

### Step 14: Run Design Rule Check (DRC)

1. Click **"Design" → "Design Rule Check"**
2. Use JLCPCB settings:
   - Clearance: 0.127mm
   - Track width: 0.127mm
   - Via drill: 0.3mm
3. Fix all errors
4. Re-run until clean

### Step 15: Add Silkscreen

1. Select **"Top Silk Layer"**
2. Add text: `ESP12F-DS18B20 v1.0`
3. Label screw terminal pins: `VCC`, `DAT`, `GND`
4. Ensure no silkscreen overlaps pads

---

## Part 4: Generate Manufacturing Files

### Step 16: Generate Gerber Files

1. Click **"Fabrication" → "PCB Fabrication File (Gerber)"**
2. Review layers (should show all required layers)
3. Click **"Generate Gerber"**
4. Download ZIP file

### Step 17: Generate BOM and Pick & Place Files

For SMT assembly, you need:

1. **BOM (Bill of Materials)**:
   - Click **"Fabrication" → "BOM"**
   - Ensure all LCSC part numbers are present
   - Export as CSV

2. **Pick & Place (CPL) File**:
   - Click **"Fabrication" → "Pick and Place File"**
   - Download CSV

---

## Part 5: Ordering from JLCPCB

### Step 18: Go to JLCPCB

1. Visit [https://jlcpcb.com](https://jlcpcb.com)
2. Log in (or create account - can use same as EasyEDA)

### Step 19: Upload Gerber Files

1. Click **"Order Now"** or **"Quote Now"**
2. Click **"Add Gerber File"**
3. Upload your Gerber ZIP
4. Wait for processing (shows board preview)

### Step 20: Configure PCB Options

Set these options:

| Option | Setting |
|--------|---------|
| Base Material | FR-4 |
| Layers | 2 |
| Dimensions | 50mm x 35mm (auto-detected) |
| PCB Qty | 10 |
| PCB Thickness | 1.6mm |
| PCB Color | Green (cheapest) |
| Surface Finish | HASL (lead free) |
| Copper Weight | 1oz |
| Remove Order Number | Yes (optional, +$1) |

### Step 21: Enable SMT Assembly

1. Scroll down to **"SMT Assembly"**
2. Toggle **ON**
3. Select **"Assemble top side"**
4. Select **"Economic" or "Standard"** (economic is cheaper)
5. Set **Quantity: 10**

### Step 22: Upload BOM and Pick & Place

1. Click **"Add BOM File"** → Upload your BOM CSV
2. Click **"Add CPL File"** → Upload your Pick & Place CSV
3. Click **"Process BOM & CPL"**

### Step 23: Review Parts Matching

JLCPCB will show a parts matching screen:

1. Verify each component matches correct LCSC part
2. Check stock availability (green = in stock)
3. Note any "Extended" parts (extra fee)
4. Confirm all parts are correct

**Expected extended parts fee:**
- ESP-12F: ~$3
- Screw Terminal: ~$3

### Step 24: Review Component Placement

1. Click **"Next"**
2. Review 3D preview of assembled board
3. Check component orientations:
   - USB-C facing correct edge
   - ESP-12F pin 1 correct
   - LED polarity correct
   - IC orientations correct
4. Rotate components if needed (click to select, use rotation controls)

### Step 25: Review & Pay

1. Review final quote:
   - PCB cost: ~$5
   - Assembly: ~$8-15
   - Components: ~$28-30
   - Extended parts fee: ~$6
   - Shipping: ~$5-20 (varies by method)

2. Select shipping method:
   - **Standard** (~$5-10, 2-3 weeks)
   - **Express** (~$15-30, 1 week)

3. Add to cart and checkout

---

## Part 6: After Ordering

### What to Expect

1. **Order confirmation**: Immediate email
2. **Production start**: 1-2 business days
3. **Production time**: 3-5 days (PCB) + 2-3 days (assembly)
4. **Shipping**: Depends on method selected
5. **Total time**: ~2-3 weeks (standard shipping)

### Tracking Your Order

1. Log into JLCPCB
2. Go to **"Order History"**
3. Click your order for status updates
4. Tracking number provided when shipped

### When Boards Arrive

1. Inspect for damage
2. Visual check of solder joints
3. Test one board before deploying all:
   - Connect USB-C cable
   - Check for 3.3V on test points
   - Upload your firmware
   - Connect DS18B20 and verify reading

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Part not found" in BOM | Search by LCSC number, verify stock |
| DRC errors | Check trace clearances, via sizes |
| Component rotation wrong | Rotate in placement preview |
| Board preview looks wrong | Re-check Gerber generation |
| ESP won't program | Check DTR/RTS connections, try manual flash buttons |
| No 3.3V output | Check AMS1117 orientation, capacitor values |

### Getting Help

- **EasyEDA Forum**: [https://easyeda.com/forum](https://easyeda.com/forum)
- **JLCPCB Support**: support@jlcpcb.com
- **r/PrintedCircuitBoard**: Reddit community

---

## Cost Summary (10 Boards)

| Item | Cost |
|------|------|
| PCB Fabrication (10x) | $5 |
| SMT Assembly Setup | $8 |
| Component Placement | $5 |
| Extended Parts Fee | $6 |
| Components (from LCSC) | $30 |
| Standard Shipping | $8 |
| **TOTAL** | **~$62** |
| **Per Board** | **~$6.20** |

Plus you'll need (not assembled):
- DS18B20 waterproof probes: ~$2-5 each
- USB-C cables: ~$2-5 each
- Enclosures (optional): ~$2-5 each

---

## Next Steps After Assembly

1. **Update firmware** if needed for new GPIO2 LED:
   ```cpp
   // In your code, add LED control:
   #define STATUS_LED_PIN 2
   pinMode(STATUS_LED_PIN, OUTPUT);
   digitalWrite(STATUS_LED_PIN, LOW);  // LED ON (active low)
   ```

2. **Wire DS18B20**: Connect waterproof probe to screw terminal
   - Red → VCC
   - Yellow → DAT
   - Black → GND

3. **Program via USB-C**: Connect cable, upload from PlatformIO

4. **Deploy!**

---

## Files Reference

After completing design, you'll have:

```
ESP12F-DS18B20-Sensor/
├── Schematic.json        (EasyEDA project file)
├── PCB.json              (EasyEDA PCB file)
├── Gerber/
│   ├── Gerber_TopLayer.GTL
│   ├── Gerber_BottomLayer.GBL
│   ├── Gerber_TopSilk.GTO
│   ├── Gerber_TopSolder.GTS
│   ├── Gerber_BottomSolder.GBS
│   ├── Gerber_BoardOutline.GKO
│   └── Drill.DRL
├── BOM.csv               (Bill of Materials)
└── PickPlace.csv         (Component positions)
```

Good luck with your PCB! 🎉
