# MQTT Reconnection Issue - ESP8266 12-Hour Timeout Fix

## Problem Summary
ESP8266 temperature sensors lost MQTT connection after ~12 hours while still running. The device would silently disconnect from the broker and fail to reconnect.

**Symptoms:**
- Device appears to be running (no reboot, no crash logs)
- Temperature readings continue working locally
- MQTT messages stop appearing in broker
- Device never automatically reconnects
- ESP32 devices (like spa) continue working normally (they have more memory)

## Root Cause
Complex exponential backoff logic with multiple state variables causing reconnection timing to fail after extended operation.

## Solution
Simplified MQTT reconnection to use a **fixed 5-second retry interval** with no backoff complexity.

## Changes Made

### Global Variables (lines 102-112)
Removed unused backoff variables:
- ~~`mqttReconnectInterval`~~ → Fixed to `MQTT_RECONNECT_INTERVAL_MS = 5000`
- ~~`mqttBackoffResetTime`~~
- ~~`mqttConsecutiveFailures`~~
- ~~`MQTT_RECONNECT_INTERVAL_MAX_MS`~~
- ~~`MQTT_BACKOFF_RESET_INTERVAL_MS`~~
- ~~`MQTT_MAX_CONSECUTIVE_FAILURES`~~

### Connection Logic (lines 431-462)
**Removed:**
- Exponential backoff calculation
- Backoff reset timers
- Consecutive failure counting

**Kept simple:**
```cpp
// Just attempt reconnect every 5 seconds if disconnected
if (lastMqttReconnectAttempt > 0 &&
    (now - lastMqttReconnectAttempt) < MQTT_RECONNECT_INTERVAL_MS) {
  return false;
}
```

### Loop Timing (lines 979-988)
**Before:**
```cpp
// Complex backoff checking
if (!mqttClient.connected() &&
    (now - lastMqttReconnectAttempt) >= mqttReconnectInterval) {
  ensureMqttConnected();
}
```

**After:**
```cpp
// Simple fixed-interval retry
if (!mqttClient.connected() &&
    (now - lastMqttReconnectAttempt) >= MQTT_RECONNECT_INTERVAL_MS) {
  ensureMqttConnected();
}
```

### Heap Monitoring (lines 1030-1041)
Added ESP8266-specific memory check:
```cpp
#ifdef ESP8266
  uint32_t freeHeap = ESP.getFreeHeap();
  if (freeHeap < 8000) {
    Serial.printf("[WARNING] Low heap: %lu bytes\n", freeHeap);
    if (freeHeap < 6000) {
      Serial.println("[WARNING] Critical heap - reconnecting MQTT");
      mqttClient.disconnect();
      lastMqttReconnectAttempt = 0;  // Force immediate reconnect
    }
  }
#endif
```

## Testing

### Verification
1. Deploy updated firmware to ESP8266 sensors
2. Monitor serial output for successful connection: `[MQTT] Connected to broker`
3. Monitor MQTT for temperature messages appearing regularly
4. Check device stays online for extended periods (24+ hours)

### Monitoring Commands

**Check device health:**
```bash
curl http://<device-ip>/health | jq '.uptime_seconds'
```

**Monitor reconnection attempts:**
```bash
screen /dev/ttyUSB0 115200
# Look for: [MQTT] Attempting connection...
# Should retry every 5 seconds if disconnected
```

**Watch for memory warnings:**
```bash
screen /dev/ttyUSB0 115200
# Watch for: [WARNING] Low heap: XXXX bytes
```

## Why This Works

**Fixed 5-second retry:**
- Simple, predictable reconnection behavior
- No state machine complexity
- Works reliably even under memory pressure
- ESP8266 can handle 5-second intervals without resource exhaustion

**Heap monitoring:**
- Detects memory exhaustion before it breaks MQTT
- Forces fresh connection when heap critical
- Prevents silent failures from memory corruption

## Firmware Update Instructions

```bash
cd temperature-sensor

# Build with updated code
pio run -e esp8266

# Flash to device
pio run -e esp8266 -t upload --upload-port /dev/ttyUSB0

# Monitor startup
pio device monitor -b 115200
```

**Expected startup sequence:**
```
[MQTT] Attempting connection to <broker>:1883 as <device>-<chipid>
[MQTT] Connected to broker
[MQTT] Subscribed to command topic: ...
```

## Why This Beats Exponential Backoff

**Exponential backoff problems:**
- After 10 failures: 30-second waits
- Complex state variables that can get corrupted
- Edge cases with `millis()` arithmetic
- Over 12 hours, complexity compounds

**Fixed interval benefits:**
- No state corruption possible
- Predictable behavior under stress
- Easier to debug and maintain
- Works with resource-constrained ESP8266
