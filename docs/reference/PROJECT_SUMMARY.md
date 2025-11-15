# 📋 Project Summary - ESP8266 Temperature Logger with CloudWatch

## Overview

**A complete IoT temperature monitoring solution** that reads DS18B20 sensor data on an ESP8266, buffers all logs/errors/diagnostics locally, and uploads them every 30 seconds to **AWS CloudWatch** via a serverless Lambda + API Gateway architecture.

**Status**: ✅ **FULLY OPERATIONAL & TESTED**

---

## What You Have

### Hardware
- ✅ **ESP8266** (NodeMCU v2) with custom firmware
- ✅ **DS18B20** digital temperature sensor
- ✅ **WiFi-enabled** real-time logging

### Firmware Features
- ✅ **30-second cycle**: Read temp → Buffer logs → Send to CloudWatch → Clear buffer
- ✅ **Web dashboard**: HTTP endpoints for live temperature
- ✅ **Log buffering**: Captures up to 50 entries (temp, errors, diagnostics)
- ✅ **Error handling**: All failures logged and sent to CloudWatch
- ✅ **No MQTT required**: Uses Lambda + API Gateway (serverless, free tier)
- ✅ **Serial monitoring**: Real-time feedback for debugging

### Cloud Infrastructure
- ✅ **AWS Lambda** (Python 3.11) - processes and logs data
- ✅ **API Gateway** (REST) - provides HTTPS endpoint
- ✅ **CloudWatch Logs** - stores all device data with timestamps
- ✅ **All free tier eligible** (5GB/month log storage included)

---

## File Structure

```
esp12f_ds18b20_temp_sensor/
├── README.md                     # Comprehensive setup guide
├── DEPLOYMENT.md                 # Quick-start & troubleshooting
├── CLOUDWATCH_VERIFICATION.md    # Verification checklist
├── platformio.ini                # PlatformIO configuration
├── .gitignore                    # Excludes secrets.h
├── src/
│   └── main.cpp                  # Firmware (520+ lines, fully commented)
├── include/
│   └── secrets.h                 # WiFi + AWS credentials (DO NOT COMMIT)
├── lib/
│   ├── OneWire/                  # OneWire protocol library
│   └── DallasTemperature/        # DS18B20 driver
└── test/
    └── README                    # Testing directory
```

---

## Key Features Implemented

### 1. Temperature Reading
```cpp
// Reads every 30 seconds
updateTemperatures();
// Produces: temperatureC = "23.38", temperatureF = "74.07"
```

### 2. Log Buffering
```cpp
// All messages automatically captured
logMessage("Temperature C: 23.38");     // → logBuffer[0]
logMessage("Logs sent to CloudWatch!"); // → logBuffer[1]
// ...up to 50 entries
```

### 3. CloudWatch Upload
```cpp
// Every 30 seconds
sendToLambda();  // → POST JSON to API Gateway
// Lambda parses and logs to CloudWatch
// On HTTP 200 success: buffer cleared
```

### 4. Web Dashboard
```
GET http://192.168.1.100/            → HTML dashboard
GET http://192.168.1.100/temperaturec → "23.38"
GET http://192.168.1.100/temperaturef → "74.07"
```

---

## How It Works

### Upload Cycle (Every 30 seconds)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Read DS18B20 Sensor                                      │
│    → temperatureC = "23.38°C"                               │
│    → temperatureF = "74.07°F"                               │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Collect All Buffered Logs                                │
│    → ["Temperature C: 23.38", "Temperature F: 74.07", ...]  │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Send JSON via HTTPS POST                                 │
│    → API Gateway Invoke URL                                 │
│    └─ Content-Type: application/json                        │
│    └─ Body: {"device": "...", "tempC": 23.38, "logs": [...]}
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Lambda Processes                                         │
│    → Parses JSON payload                                    │
│    → Extracts temperature & logs                            │
│    → Writes to CloudWatch Logs                              │
│    → Returns HTTP 200 OK                                    │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Device Confirms & Clears                                 │
│    → Receives HTTP 200 from Lambda                          │
│    → Clears log buffer                                      │
│    → Waits 30 seconds                                       │
│    → Loop repeats                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### View Live Temperature from Device

```bash
# Get current Celsius
curl http://192.168.1.100/temperaturec
# Output: 23.38

# Get current Fahrenheit
curl http://192.168.1.100/temperaturef
# Output: 74.07

# Open dashboard in browser
open http://192.168.1.100
```

### Monitor Device Serial Output

```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200

# Expected output every 30 seconds:
Temperature C: 23.38
Temperature F: 74.07
Sending logs to Lambda endpoint...
Lambda payload size: 190 bytes
Lambda HTTP Code: 200
Lambda response: {"message": "Data logged successfully", ...}
Logs sent to CloudWatch successfully!
```

### View CloudWatch Logs

1. AWS Console → **CloudWatch**
2. **Logs** (left sidebar)
3. **Log Groups** → **esp-sensor-logs**
4. **Log Streams** → **garage-temperature**
5. **View entries** (live updating)

```
2025-11-13T19:57:03.487570 Device: Big Garage Temperature | Temp: 23.38°C / 74.07°F
2025-11-13T19:57:03.487571 Device Log: Temperature C: 23.38
2025-11-13T19:57:03.487572 Device Log: Temperature F: 74.07
2025-11-13T19:57:03.487573 Device Log: Logs sent to CloudWatch successfully!
```

---

## Rebuilding & Deploying

### Quick Rebuild

```bash
# Activate environment
source ~/.venvs/platformio/bin/activate

# Build
platformio run -e nodemcuv2

# Upload
platformio run -e nodemcuv2 --target upload

# Monitor
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

### Making Changes

**Edit firmware**:
```cpp
// Edit src/main.cpp
// Change anything, e.g., timer interval:
unsigned long timerDelay = 60000;  // 60 seconds instead of 30
```

**Rebuild and upload**:
```bash
platformio run -e nodemcuv2 --target upload
```

---

## Verification Checklist

✅ **Device Level**:
- [ ] Serial monitor shows "Temperature C: XX.XX" every 30 seconds
- [ ] Serial monitor shows "Lambda HTTP Code: 200"
- [ ] Web dashboard accessible at `http://<device-ip>/`

✅ **Cloud Level**:
- [ ] Lambda invocations appear in Lambda Monitor tab
- [ ] CloudWatch log group `esp-sensor-logs` exists
- [ ] Log stream `garage-temperature` contains entries
- [ ] Entries appear with correct timestamps

✅ **Integration**:
- [ ] Device uploads every 30 seconds (no gaps > 60 seconds)
- [ ] All temperature, errors, and diagnostics appear in CloudWatch
- [ ] No HTTP errors (all responses should be 200)

---

## AWS Free Tier Coverage

| Service | Free Tier Allocation | Your Usage | Status |
|---------|----------------------|-----------|--------|
| **Lambda** | 1M invocations/month | ~43,200/month* | ✅ Well within |
| **API Gateway** | 1M API calls/month | ~43,200/month* | ✅ Well within |
| **CloudWatch Logs** | 5GB ingestion/month | ~10MB/month** | ✅ Negligible |
| **Total Cost** | -- | $0.00/month | ✅ **FREE** |

*43,200 = 30 seconds × 60 min × 24 hrs × 1 day  
**10MB = 200 bytes per upload × 43,200 uploads

---

## Next Steps (Optional)

### 1. Set Up Temperature Alarms
```
AWS Console → CloudWatch → Alarms → Create
Condition: Temperature > 30°C → Send Email Notification
```

### 2. Create Grafana Dashboard
- Connect Grafana to CloudWatch Logs
- Graph temperature over time
- Add custom alerts

### 3. Export Logs to S3
- Archive old logs automatically
- Long-term storage for analysis

### 4. Add More Sensors
- Humidity (DHT22, DHT11)
- Pressure (BMP180, BMP280)
- CO2 (MH-Z19)
- Update Lambda to parse and log all readings

---

## Troubleshooting Guide

### Device won't connect to WiFi
1. Check SSID/password in `include/secrets.h`
2. Verify router is broadcasting 2.4GHz (ESP8266 doesn't support 5GHz)
3. Restart device (power cycle or upload code)

### Logs not appearing in CloudWatch
1. Run serial monitor: `platformio device monitor`
2. Check for "Lambda HTTP Code: 200" every 30 seconds
3. If error code appears: Check Lambda logs in AWS Console
4. Verify API Gateway Invoke URL in `secrets.h`

### Temperature reads as "--"
1. Check GPIO 4 wiring to DS18B20
2. Ensure 4.7kΩ pullup resistor on data line
3. Try different OneWire delay: increase in `main.cpp`

### Serial monitor shows garbage output
1. Check baud rate is 115200
2. Check USB cable connection
3. Try different USB port

---

## File Locations for Quick Reference

| What | Where | Edit? |
|-----|-------|-------|
| WiFi SSID/Password | `include/secrets.h` | Yes (before upload) |
| Lambda endpoint | `include/secrets.h` line 37 | Yes (from API Gateway) |
| Temperature read interval | `src/main.cpp` line 36 | Yes (change `timerDelay`) |
| Web dashboard | `src/main.cpp` lines 180-230 | Yes (customize HTML) |
| Build settings | `platformio.ini` | Rarely |
| Main firmware | `src/main.cpp` | Yes (add features) |

---

## Architecture Diagram

```
┌──────────────────┐
│   ESP8266        │
│  - DS18B20       │
│  - WiFi Module   │
│  - Log Buffer    │
└────────┬─────────┘
         │ HTTPS POST (JSON)
         │ {"device": "...", "tempC": 23.38, "logs": [...]}
         ↓
┌──────────────────────┐
│  API Gateway         │
│  (public endpoint)   │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────┐
│  AWS Lambda          │
│  (Python function)   │
│  - Parse JSON        │
│  - Extract temp/logs │
│  - Write to CW       │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────┐
│  CloudWatch Logs     │
│  - esp-sensor-logs   │
│  - garage-temperature│
│  - Timestamps, data  │
└──────────────────────┘
```

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Lines of Code** | 520+ (firmware) |
| **Build Time** | ~30 seconds |
| **Upload Time** | ~27 seconds |
| **Upload Cycle** | Every 30 seconds |
| **Uptime Target** | 24/7 (99.9% with WiFi stability) |
| **Monthly Cost** | $0.00 (AWS free tier) |
| **Log Retention** | 30 days (adjustable) |
| **Web Dashboard** | Responsive HTML5 |
| **Time to Deploy** | < 5 minutes |

---

## What's Different from MQTT/InfluxDB

| Feature | MQTT | InfluxDB Cloud | Lambda + CloudWatch |
|---------|------|-----------------|-------------------|
| Setup | Broker required | Account + token | AWS account (free) |
| Cost | Variable | Paid plans | Free tier |
| Complexity | Medium | Medium | Simple |
| Authentication | Username/pass | Token | Unauthenticated (optional) |
| Storage | External DB | Cloud | CloudWatch Logs |
| Visualization | Separate tool | Built-in | CloudWatch + Grafana |
| Scalability | Limited | Good | Excellent |
| This Project | ❌ | ❌ | ✅ CHOSEN |

---

## Final Notes

1. **Security**: `include/secrets.h` is in `.gitignore` ✅
2. **Reliability**: Device restarts if WiFi drops ✅
3. **Debugging**: Full serial output for troubleshooting ✅
4. **Extensibility**: Easy to add more sensors ✅
5. **Cost**: Free tier covers all usage ✅

---

**You now have a production-ready IoT temperature logger! 🎉**

For questions, check:
1. Device serial output (`platformio device monitor`)
2. Lambda execution logs (AWS Console)
3. CloudWatch log group (AWS Console)
4. README.md (comprehensive guide)

---

Generated: November 13, 2025  
Status: ✅ COMPLETE & OPERATIONAL
