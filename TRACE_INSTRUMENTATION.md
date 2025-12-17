# MQTT Trace Instrumentation Implementation

## Overview
This document describes the trace ID instrumentation added to all MQTT payloads in the temperature-sensor and surveillance projects.

## Purpose
Enable end-to-end request tracking and message correlation across MQTT topics and backend systems using unique trace IDs and sequence numbers.

## Implementation Details

### Trace ID Generation
- **Strategy**: Single UUID per device boot (Option A)
- **Format**: UUID-like string (36 characters)
  - ESP32: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (derived from EfuseMac + millis())
  - ESP8266: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (derived from ChipID + millis())
- **Persistence**: Constant per boot session; regenerated on device restart
- **No External Dependencies**: Uses only Arduino.h and standard C++ (sstream)

### Sequence Numbering
- **Type**: Monotonic unsigned 32-bit counter
- **Range**: 1 to 4,294,967,295 per boot
- **Reset**: Counter resets to 0 on device reboot
- **Overflow**: At 1 message/second, counter runs for ~136 years before overflow

### Schema Versioning
- **Field**: `schema_version`
- **Type**: Integer
- **Current Version**: 1
- **Purpose**: Enables backward-compatible schema evolution in backend systems

## Files Modified

### New Trace Utility Files
```
temperature-sensor/include/trace.h
temperature-sensor/src/trace.cpp
surveillance/include/trace.h
surveillance/src/trace.cpp
```

### Modified Main Files
```
temperature-sensor/src/main.cpp
  - Added #include "trace.h"
  - Added Trace::init() call in setup()
  - Instrumented: publishEvent(), publishTemperature(), publishStatus()

surveillance/src/main.cpp
  - Added #include "trace.h"
  - Added Trace::init() call in setup()
  - Instrumented: publishMetricsToMQTT(), logEventToMQTT()
```

## MQTT Payload Examples

### Temperature Sensor - Temperature Reading
```json
{
  "device": "temp-sensor-01",
  "chip_id": "a1b2c3d4",
  "trace_id": "a1b2c3d4-1a2b-3c4d-5e6f-7a8b9c0d1e2f",
  "seq_num": 1,
  "schema_version": 1,
  "timestamp": 1234567890,
  "celsius": 22.5,
  "fahrenheit": 72.5
}
```

### Surveillance - Metrics
```json
{
  "device": "esp32-cam-01",
  "chip_id": "f1e2d3c4",
  "trace_id": "f1e2d3c4-2b3c-4d5e-6f7a-8b9c0d1e2f3a",
  "seq_num": 145,
  "schema_version": 1,
  "location": "surveillance",
  "timestamp": 1234567890,
  "uptime": 3600,
  "wifi_rssi": -65,
  "free_heap": 262144,
  "camera_ready": 1,
  "mqtt_connected": 1,
  "capture_count": 42
}
```

## Build Verification

### Successful Builds
- ✅ ESP32 (esp32dev)
  - RAM: 14.1% (46,336 bytes / 327,680 bytes)
  - Flash: 75.4% (988,417 bytes / 1,310,720 bytes)

- ✅ ESP8266 (nodemcuv2)
  - RAM: 41.7% (34,124 bytes / 81,920 bytes)
  - Flash: 39.3% (410,199 bytes / 1,044,464 bytes)

- ✅ ESP32-S3 (freenove_esp32_s3_wroom)
  - RAM: 16.8% (55,016 bytes / 327,680 bytes)
  - Flash: 36.3% (1,141,725 bytes / 3,145,728 bytes)

- ✅ Surveillance ESP32-S3 (esp32-s3-devkitc-1)
  - All environments compile successfully

## API Reference

### Trace Namespace Functions

#### `void init()`
Initialize trace system at device boot.
- Must be called once during setup()
- Generates unique trace ID for this session
- Resets sequence counter to 0

**Example:**
```cpp
void setup() {
  Serial.begin(115200);
  Trace::init();  // Initialize after Serial is ready
  // ... rest of setup
}
```

#### `std::string getTraceId()`
Get the current trace ID (UUID-like string).
- Returns: 36-character UUID-formatted string
- Same value for entire boot session
- Safe to call multiple times

**Example:**
```cpp
std::string id = Trace::getTraceId();  // "a1b2c3d4-1a2b-3c4d-5e6f-7a8b9c0d1e2f"
```

#### `uint32_t getSequenceNumber()`
Get next sequence number for this message.
- Increments counter on each call
- First call returns 1, second returns 2, etc.
- Safe for concurrent calls (monotonic)

**Example:**
```cpp
uint32_t seq = Trace::getSequenceNumber();  // First call: 1, Second call: 2
```

#### `std::string getTraceIdentifier()`
Get human-readable trace identifier.
- Returns: `{trace_id}:{seq_num}` format
- Useful for logs and debugging
- Example: `"a1b2c3d4-1a2b-3c4d-5e6f-7a8b9c0d1e2f:42"`

## Integration Patterns

### Adding to Existing Publish Functions

1. **Include the header:**
   ```cpp
   #include "trace.h"
   ```

2. **Initialize in setup():**
   ```cpp
   void setup() {
     // ... other initialization
     Trace::init();
     // ... rest of setup
   }
   ```

3. **Add fields to payload:**
   ```cpp
   JsonDocument doc;
   doc["device"] = deviceName;
   // ... existing fields
   doc["trace_id"] = Trace::getTraceId();
   doc["seq_num"] = Trace::getSequenceNumber();
   doc["schema_version"] = 1;
   // ... rest of payload
   ```

## Future Enhancements

### Backward Compatibility Considerations
- `schema_version = 1`: Current schema with trace fields
- Backend should verify `schema_version` before accessing trace fields
- New devices always send `schema_version = 1`

### Schema Evolution
To add new fields in future:
1. Increment `schema_version` to 2
2. Send both old and new fields for compatibility
3. Backends can parse based on `schema_version`

### Multi-Message Correlation
- Use `trace_id` to correlate all messages from a single device session
- Use `seq_num` to order messages chronologically
- Combined `{trace_id}:{seq_num}` creates globally unique message identifier

## Testing Recommendations

1. **Verify trace IDs are unique across boots:**
   - Restart device, check trace ID changes
   - Different devices should have different trace IDs

2. **Verify sequence numbers monotonically increase:**
   - Publish multiple messages
   - Confirm seq_num increments by 1 each time
   - Check seq_num resets to 0 after device restart

3. **Verify payload size remains within MQTT limits:**
   - Maximum payload: 1024 bytes (configured)
   - Trace fields add ~70 bytes overhead
   - Remaining space: ~950 bytes for other data

4. **Test on actual hardware:**
   - Flash firmware to ESP32, ESP8266, ESP32-S3 devices
   - Monitor MQTT traffic
   - Verify trace fields present in payloads

## Deployment Notes

### No Breaking Changes
- Adds new fields to JSON payloads
- Existing fields unchanged
- Backend systems can ignore trace fields if not needed
- Gradual rollout possible

### Recommended Actions
1. Update MQTT message consumer to extract and log `trace_id`
2. Update backend to use `trace_id` for request correlation
3. Add monitoring/alerting on trace ID uniqueness
4. Document trace ID format in API specifications

## References
- [ArduinoJson Documentation](https://arduinojson.org/)
- [PubSubClient](https://github.com/knolleary/pubsubclient)
- [ESP32 Reference](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- [ESP8266 Reference](https://arduino-esp8266.readthedocs.io/)
