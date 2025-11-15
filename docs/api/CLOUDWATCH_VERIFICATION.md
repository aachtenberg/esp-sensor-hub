# 📊 CloudWatch Log Verification Checklist

## Pre-Deployment Verification

Once you've uploaded the firmware, verify everything is working:

### ✅ Device Level
```bash
# Monitor device serial output
platformio device monitor -p /dev/ttyUSB0 -b 115200

# Expected output every 30 seconds:
Temperature C: 23.XX
Temperature F: 7X.XX
Sending logs to Lambda endpoint...
Lambda payload size: XXX bytes
Lambda HTTP Code: 200
Logs sent to CloudWatch successfully!
```

### ✅ Web Dashboard
```bash
# Find device IP (from serial monitor or router)
# Then visit in browser:
http://192.168.1.100/

# Or test endpoints:
curl http://192.168.1.100/temperaturec
# Output: 23.38

curl http://192.168.1.100/temperaturef
# Output: 74.07
```

### ✅ AWS CloudWatch Logs

**Navigate to CloudWatch Logs**:
1. AWS Console → Search **CloudWatch**
2. Click **Logs** (left sidebar)
3. Click **Log Groups**
4. Find **`esp-sensor-logs`**
5. Click **`garage-temperature`** stream
6. Verify entries appear with timestamps

**Expected log format**:
```
2025-11-13T19:57:03.487570 Device: Big Garage Temperature | Temp: 23.38°C / 74.07°F
2025-11-13T19:57:03.487571 Device Log: Temperature C: 23.38
2025-11-13T19:57:03.487572 Device Log: Temperature F: 74.07
2025-11-13T19:57:03.487573 Device Log: Logs sent to CloudWatch successfully!
```

---

## What Gets Logged to CloudWatch

### Device Temperature Readings
- Current temperature in Celsius
- Current temperature in Fahrenheit
- Logged every 30 seconds

### All Device Diagnostics
- WiFi connection status
- Temperature sensor read status
- Lambda HTTP response codes
- Successful uploads ("Logs sent to CloudWatch successfully!")
- Any errors or warnings

### Example Log Stream
```
Device: Big Garage Temperature | Temp: 23.56°C / 74.41°F | Time: 2025-11-13T19:57:03.123456
Device Log: Temperature C: 23.56
Device Log: Temperature F: 74.41
Device Log: Logs sent to CloudWatch successfully!
```

---

## Log Retention & Storage

- **Default retention**: 30 days (adjustable in CloudWatch)
- **Searchable**: Use CloudWatch Logs Insights for queries
- **No cost** for storage in free tier (~5GB/month included)

### Query Examples in CloudWatch Logs Insights

**Find all temperature readings**:
```
fields @timestamp, @message | filter @message like /Temp:/
```

**Get average temperature**:
```
fields tempC | stats avg(tempC) as avg_temp
```

**Find errors**:
```
fields @timestamp, @message | filter @message like /error|Error|ERROR|failed|Failed/
```

---

## Troubleshooting CloudWatch Integration

### Problem: No logs appearing in CloudWatch

**Check 1: Device is uploading**
```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200 | grep "Lambda HTTP"
```
Should show: `Lambda HTTP Code: 200`

**Check 2: Lambda function is receiving requests**
- AWS Console → Lambda → `esp-temperature-logger`
- Click **Monitor** tab
- Check **Invocations** graph and **Logs**

**Check 3: Log group exists**
- AWS Console → CloudWatch → Logs → Log Groups
- Search for `esp-sensor-logs`
- If missing, Lambda function needs to create it (happens automatically on first log)

**Check 4: API Gateway endpoint is correct**
- Verify in `include/secrets.h`:
  ```cpp
  static const char* LAMBDA_ENDPOINT = "https://2v5is8pxxc.execute-api.ca-central-1.amazonaws.com/default/esp-temperature-logger";
  ```
- Must match your actual API Gateway Invoke URL

### Problem: HTTP 404 or 403 from Lambda

**Solution**: 
- Ensure API Gateway is **Deployed** (not just saved)
- In API Gateway console → Click **Deploy API** button
- Check that authorization is set to **NONE** (unauthenticated)

### Problem: Temperature reads as "--"

**Check**:
1. GPIO 4 is connected to DS18B20 data pin
2. 4.7kΩ pullup resistor on data line
3. Serial monitor shows sensor detection
4. Try power-cycling the device

---

## Log Buffer Details

### How it Works
1. **50-entry circular buffer** stores all `logMessage()` calls
2. **Every 30 seconds**: Buffer is sent to Lambda as JSON array
3. **After HTTP 200 success**: Buffer is cleared
4. **If upload fails**: Buffer retains logs for next cycle

### Buffer Overflow Prevention
- If buffer fills (50 entries), oldest entries are overwritten
- Ensures device doesn't run out of RAM
- Typical buffer fills every 30 seconds anyway

### Example Payload Sent to Lambda
```json
{
  "device": "Big Garage Temperature",
  "timestamp": 123456789,
  "tempC": 23.38,
  "tempF": 74.07,
  "logCount": 6,
  "logs": [
    {"msg": "Temperature C: 23.38", "ts": 123400000},
    {"msg": "Temperature F: 74.07", "ts": 123400001},
    {"msg": "Logs sent to CloudWatch successfully!", "ts": 123400002},
    ...
  ]
}
```

---

## Optional: Set Up Alarms

### Temperature High Alarm
1. CloudWatch → Alarms → Create Alarm
2. Source: **Log Group** → `esp-sensor-logs`
3. Condition: `[tempC > 30]` (adjust threshold)
4. Action: Send SNS notification (email)

### No Data Alarm
1. CloudWatch → Alarms → Create Alarm
2. Source: **Log Group** → `esp-sensor-logs`
3. Condition: No logs in last 5 minutes
4. Action: Send SNS notification

---

## Next: Advanced Usage

### Option 1: Grafana Dashboard
- Connect Grafana to CloudWatch Logs
- Create live temperature graph
- Add alerts with webhooks

### Option 2: CloudWatch Dashboard
- Visualize logs with metrics
- Add widgets for temperature trends
- Share dashboard with team

### Option 3: Export to S3
- Archive logs to S3 for long-term storage
- Enable Log Insights queries on archived data

---

## Support

If logs aren't appearing:
1. Check device serial output for "HTTP Code: 200"
2. Verify Lambda `esp-temperature-logger` has recent invocations
3. Confirm log group `esp-sensor-logs` exists
4. Check CloudWatch Logs Insights for any filtering

**All critical information is in device serial output.** When troubleshooting, always run:
```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

---

**You're all set!** 🎉 Your device is now logging everything to CloudWatch.
