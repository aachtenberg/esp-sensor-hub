# PCB Board Layout Guide

## Board Specifications

| Parameter | Value |
|-----------|-------|
| Board Size | 50mm x 35mm |
| Layers | 2 (Top + Bottom) |
| Copper Weight | 1oz (35µm) |
| Board Thickness | 1.6mm |
| Min Track Width | 0.25mm (10mil) |
| Min Clearance | 0.2mm (8mil) |
| Min Via | 0.3mm drill, 0.6mm pad |
| Surface Finish | HASL (lead-free) |
| Solder Mask | Green |
| Silkscreen | White |

---

## Recommended Board Outline

```
    ┌─────────────────────────────────────────────────────┐
    │  ○                                               ○  │ ← M3 Mounting holes
    │                                                     │   (3.2mm diameter)
    │    ┌───────────────────────────────────────┐        │
    │    │                                       │        │
    │    │           ESP-12F Module              │        │
    │    │           (24.8 x 16mm)               │        │
    │    │                                       │        │
    │    └───────────────────────────────────────┘        │
    │                                                     │
    │  ┌────┐   ┌──────────┐   ┌──────┐   ┌───────────┐  │
    │  │USB-C│  │  CH340C  │   │AMS1117│  │Screw Term │  │
    │  └────┘   └──────────┘   └──────┘   └───────────┘  │
    │                                                     │
    │   [RST]    [FLASH]    ● LED                        │
    │                                                     │
    │  ○                                               ○  │
    └─────────────────────────────────────────────────────┘
         ↑
      USB-C at board edge for easy cable access

    Dimensions: 50mm x 35mm
```

---

## Component Placement Strategy

### Top Layer (Primary Components)

```
Priority placement order:
1. USB-C connector (edge-mounted, centered on short edge)
2. ESP-12F module (centered, largest component)
3. CH340C (near USB-C, short traces to D+/D-)
4. AMS1117 regulator (between USB and ESP)
5. Screw terminal (opposite edge from USB)
6. Buttons (accessible from top)
7. LED (visible location)
8. Passive components (fill remaining space)
```

### Detailed Placement

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  (M3)                                              (M3)  │
│   ○     R1  R2  R3                          R4      ○    │
│         10k 10k 10k                         10k          │
│                                                          │
│      ┌─────────────────────────────────────────┐         │
│      │                                         │         │
│      │              ESP-12F                    │──R5(4.7k)──┐
│      │                                         │            │
│      │             (ANTENNA END)               │            │
│      │             ↑ Keep clear!               │            │
│      └─────────────────────────────────────────┘            │
│                                                             │
│   ┌─────┐    ┌──────────┐    ┌──────────┐    ┌─────────────┐
│   │USB-C│    │  CH340C  │    │ AMS1117  │    │ J2 TERMINAL │
│   │ J1  │    │    U2    │    │   U3     │    │ VCC DAT GND │
│   └──┬──┘    └────┬─────┘    └────┬─────┘    └──────┬──────┘
│      │            │               │                 │
│   R6 R7         C3 C4 C5       C1   C2              │
│  5.1k 5.1k      100n           10µ  10µ             │
│                                                      │
│   [SW1]     [SW2]      ●──R8──┘                     │
│   RESET     FLASH     LED 1kΩ                       │
│                                                      │
│  (M3)                                         (M3)  │
│   ○                                             ○    │
│                                                      │
└──────────────────────────────────────────────────────┘
        ↑
    Board edge
```

---

## Critical Layout Rules

### 1. ESP-12F Antenna Keep-Out Zone

**CRITICAL**: The ESP-12F antenna area MUST be kept clear!

```
                    ┌────────────────────┐
                    │    ANTENNA AREA    │
                    │   ░░░░░░░░░░░░░    │  ← NO copper, traces,
                    │   ░░░░░░░░░░░░░    │     or ground plane
                    │                    │     in this region
     Module edge →  ├────────────────────┤
                    │                    │
                    │    ESP-12F Body    │
                    │                    │
                    └────────────────────┘

Keep-out zone: Extend 10mm beyond antenna end
- No ground plane under antenna
- No traces under antenna
- No components near antenna
```

### 2. USB-C Placement

```
USB-C must be at board edge:
- Connector body flush with edge OR
- Slight overhang (0.5mm max)
- Centered for cable stress relief

    Board edge
        │
        ▼
━━━━━━━━━━━━━━━━━━━━━━━
        ┌─────┐
        │USB-C│
        │     │
        └─────┘
```

### 3. Power Distribution

```
Power flow:
USB VBUS (5V) → AMS1117 → 3.3V Rail → All components

Recommended approach:
- Wide 5V trace from USB to regulator (0.5mm+)
- Wide 3.3V trace from regulator (0.5mm+)
- Ground plane on bottom layer
- Via stitching around high-current paths
```

### 4. USB Data Lines (D+/D-)

```
USB differential pair requirements:
- Keep D+ and D- parallel
- Match trace lengths (within 0.5mm)
- Keep traces short (USB to CH340C)
- 90Ω differential impedance (if possible)
- Avoid routing near noisy signals

    USB-C              CH340C
    ┌───┐              ┌───┐
    │D+ ├──────────────┤D+ │  ← Parallel traces
    │D- ├──────────────┤D- │  ← Matched length
    └───┘              └───┘
```

### 5. Decoupling Capacitor Placement

```
Place decoupling caps as close as possible to IC power pins:

CH340C:
    ┌──────────────┐
    │    CH340C    │
    │   VCC ───┬───│
    └──────────│───┘
               │
             ─┴─ C (100nF)
               │
              GND

AMS1117:
    5V ──┬── [AMS1117] ──┬── 3.3V
         │               │
       ─┴─ C1(10µF)    ─┴─ C2(10µF)
         │               │
        GND             GND
```

---

## Trace Width Guidelines

| Net | Current | Min Width | Recommended |
|-----|---------|-----------|-------------|
| 5V Power | 500mA | 0.5mm | 0.8mm |
| 3.3V Power | 300mA | 0.4mm | 0.6mm |
| GND | 500mA | 0.5mm | Ground plane |
| USB D+/D- | Signal | 0.25mm | 0.3mm (matched) |
| UART TX/RX | Signal | 0.2mm | 0.25mm |
| GPIO signals | Signal | 0.2mm | 0.25mm |
| All others | Signal | 0.2mm | 0.25mm |

---

## Layer Stack-Up

### 2-Layer Board

```
┌─────────────────────────────┐
│     Top Layer (Components)   │ ← Components, signals, some power
│         FR4 (1.6mm)         │
│    Bottom Layer (Ground)     │ ← Ground plane (solid copper)
└─────────────────────────────┘
```

**Recommended approach:**
- **Top layer**: All components, signal traces, power traces
- **Bottom layer**: Solid ground plane with minimal cuts

---

## Ground Plane Design

```
Bottom layer - Ground plane with cutouts only where needed:

┌─────────────────────────────────────────────────┐
│ ████████████████████████████████████████████████│
│ ████████████████████████████████████████████████│
│ ████████████████████                     ███████│ ← Cutout under
│ ████████████████████    (antenna         ███████│   ESP-12F antenna
│ ████████████████████     keep-out)       ███████│
│ ████████████████████                     ███████│
│ ████████████████████████████████████████████████│
│ ████████████████████████████████████████████████│
│ ████████████████████████████████████████████████│
└─────────────────────────────────────────────────┘

Ground plane coverage: >80% of bottom layer (excluding antenna zone)
```

---

## Via Placement

### Power Vias
```
Place vias to connect top traces to bottom ground:
- Near every IC ground pin
- At corners of ground plane
- Along board edges (via stitching)

Via specs for JLCPCB:
- Drill: 0.3mm
- Pad: 0.6mm
- Annular ring: 0.15mm
```

### Thermal Relief
```
For large ground pads (AMS1117 tab, connectors):
Use thermal relief pattern for easier soldering:

    ┌───────────┐
    │   │   │   │
    │ ──┼───┼── │
    │   │ ● │   │  ← Via with thermal relief
    │ ──┼───┼── │     (4 spokes to ground)
    │   │   │   │
    └───────────┘
```

---

## Mounting Holes

```
4x M3 mounting holes in corners:
- Hole diameter: 3.2mm
- Pad diameter: 6mm (connected to GND for shielding)
- Distance from edges: 3mm

Corner positions (from bottom-left origin):
- (3, 3)
- (47, 3)
- (3, 32)
- (47, 32)

        3mm
         ↓
    ○────────────────────────○
    │                        │  ↑ 3mm
    │                        │
    │                        │
    │                        │
    │                        │
    ○────────────────────────○
```

---

## Silkscreen Design

### Component Labels
```
Essential silkscreen items:
- Component designators (U1, R1, C1, etc.)
- Pin 1 indicators for ICs
- Polarity marks for capacitors (if polarized)
- LED polarity (+/-)
- Connector pin labels (VCC, DAT, GND for J2)
- Board name and version
- Orientation marks for ESP-12F
```

### Example Silkscreen Layout
```
┌─────────────────────────────────────────────┐
│  ESP12F-DS18B20 v1.0                        │
│                                             │
│      ▼ (pin 1 mark)                         │
│    ┌───────────────────────┐                │
│    │      ESP-12F U1       │                │
│    └───────────────────────┘                │
│                                             │
│   USB    CH340C   AMS1117    ┌───────────┐  │
│    J1      U2       U3       │VCC DAT GND│  │
│                              │    J2     │  │
│                              └───────────┘  │
│                                             │
│   RST    FLASH    ● LED                     │
│   SW1     SW2     D1                        │
└─────────────────────────────────────────────┘
```

---

## Design Rule Check (DRC) Settings

For JLCPCB manufacturing, use these DRC settings in EasyEDA:

| Rule | Value |
|------|-------|
| Minimum Track Width | 0.127mm (5mil) |
| Minimum Clearance | 0.127mm (5mil) |
| Minimum Via Drill | 0.3mm |
| Minimum Via Diameter | 0.5mm |
| Minimum Annular Ring | 0.13mm |
| Minimum Hole Size | 0.3mm |
| Silkscreen Width | 0.15mm minimum |
| Board Outline | 0.3mm line width |

**Recommended (for easier manufacturing):**
| Rule | Value |
|------|-------|
| Track Width | 0.25mm (10mil) |
| Clearance | 0.2mm (8mil) |
| Via Drill | 0.3mm |
| Via Diameter | 0.6mm |

---

## Final Checklist Before Ordering

- [ ] All components placed and connected
- [ ] No DRC errors
- [ ] Antenna keep-out zone clear
- [ ] USB-C at board edge
- [ ] Ground plane >80% coverage
- [ ] All vias properly placed
- [ ] Silkscreen readable and not overlapping pads
- [ ] Mounting holes in all 4 corners
- [ ] Board outline correct (50x35mm)
- [ ] All LCSC part numbers assigned
- [ ] BOM and Pick & Place files generated
