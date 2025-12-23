# ESP8266 Deep Sleep Wake-up Troubleshooting Guide

## Problem
Your ESP8266 never wakes up from deep sleep after the code calls `ESP.deepSleep()`.

## Root Cause
The ESP8266's timer-based wake-up requires a **hardware connection that may be missing**:
- GPIO 16 (labeled "D0" on most boards) must be connected to the RST (reset) pin
- Without this connection, the internal timer interrupt cannot wake the device
- Result: Device sleeps forever

## Solution

### Hardware Fix (Required for Timer-based Wake-up)
You need to connect GPIO 16 to RST with a proper RC circuit:

```
RST pin --[10K resistor]--+-- GPIO 16 (D0)
                          |
                       [0.1µF cap]
                          |
                         GND
```

**Connection Details:**
- **Resistor**: 10K ohm (or similar, 4.7K-22K range acceptable)
- **Capacitor**: 0.1µF ceramic or electrolytic
- **Purpose**: Prevents glitches on RST from triggering unwanted resets

### Verify Your Board
Check if your ESP8266 board already has this connection:
- Some development boards (like WeMos D1 Mini) have this built-in
- Many bare modules do NOT have this connection
- Check your board's schematic or pinout documentation

### Software Testing
If you don't want to add the hardware yet:

1. **Disable deep sleep temporarily:**
   ```bash
   # Delete the deep sleep config file from LittleFS
   # Or set deepSleepSeconds to 0 via the /deepsleep endpoint
   curl http://<device-ip>/deepsleep -X POST -d "seconds=0"
   ```

2. **Check if device works normally** (without deep sleep):
   ```bash
   # Monitor serial output
   screen /dev/ttyUSB0 115200
   ```

3. **Verify the GPIO 16 warning message:**
   - When deep sleep is triggered, look for:
     ```
     [DEEP SLEEP] Entering deep sleep for X seconds...
     [DEEP SLEEP] *** IMPORTANT: GPIO 16 must be connected to RST for wake-up ***
     [DEEP SLEEP] Without GPIO16->RST connection, device will sleep forever!
     ```

## Detailed Explanation

### Why ESP8266 is Different
- **ESP32**: Has a built-in RTC that can wake from deep sleep without external connections
- **ESP8266**: Requires GPIO 16 to drive the RST pin to wake from timer-based deep sleep

### How It Works (with proper connection)
1. Device calls `ESP.deepSleep(microseconds)`
2. Device enters ultra-low power state
3. Internal RTC timer counts down
4. When timer expires, RTC triggers GPIO 16 output to HIGH
5. GPIO 16 → RST connection causes device to reset (wake up)
6. Device boots and resumes normal operation

### Common Symptoms
- ✅ Device works fine without deep sleep
- ✅ Deep sleep code runs (you see the MQTT message and serial log)
- ❌ Device never comes back online
- ❌ No serial output after deep sleep begins
- ❌ MQTT never publishes updates after "entering deep sleep"

## Testing After Hardware Fix

### Step 1: Verify Connection
```bash
# Use a multimeter to check GPIO 16 and RST are properly connected
# With device powered off:
# - Measure resistance between GPIO 16 and RST
# - Should see ~10K ohms (the resistor value)
```

### Step 2: Test with Short Interval
```bash
# Set deep sleep to 5 seconds for testing
curl http://<device-ip>/deepsleep -X POST -d "seconds=5"

# Monitor serial output - should see boot messages every ~5 seconds
screen /dev/ttyUSB0 115200
```

### Step 3: Monitor in MQTT
```bash
# Watch MQTT messages
mosquitto_sub -h <broker> -t "esp-sensor-hub/+/+"

# You should see:
# - device boot messages every ~5 seconds
# - temperature updates every ~5 seconds
```

## If It Still Doesn't Work

### Check the connection physically:
1. Disconnect power
2. Use a multimeter to verify GPIO 16 and RST continuity
3. Check solder joints for cold joints or bridges
4. Verify no accidental shorts to GND or 3.3V

### Check your board:
1. Verify you're modifying the correct GPIO
   - ESP-12F: GPIO 16 is the RTC GPIO
   - Check datasheet for your specific module
2. Some boards have GPIO 16 occupied by other functions
   - If GPIO 16 is used elsewhere, deep sleep cannot work on that board

### Alternative: Use External Interrupt
If GPIO 16 isn't available:
1. Use an external button/switch on GPIO 0, 4, 5, 12, 13, 14, or 15
2. Press the button to wake from light sleep instead of deep sleep
3. Modify the code to use `ESP.lightSleep()` instead

## Production Recommendations

For battery-powered ESP8266 sensors:
1. **Verify GPIO 16 connection is solid** before deployment
2. **Test wake-up cycle multiple times** before field deployment
3. **Keep wake interval short initially** (10-30 seconds) for testing
4. **Monitor MQTT uptime** to ensure consistent wake cycles
5. **Add watchdog timer** to catch any edge cases

## Code Changes Made
The code now displays a warning when deep sleep is triggered on ESP8266:
```
[DEEP SLEEP] *** IMPORTANT: GPIO 16 must be connected to RST for wake-up ***
[DEEP SLEEP] Without GPIO16->RST connection, device will sleep forever!
```

This helps identify the issue faster in the future.
