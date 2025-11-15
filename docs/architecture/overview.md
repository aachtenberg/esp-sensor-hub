# 📚 Documentation Index

Welcome! Here's a complete guide to your ESP8266 CloudWatch temperature logger project.

---

## 🚀 Quick Start (5 minutes)

**New to this project?** Start here:

1. **[README.md](README.md)** ← **START HERE**
   - Overview of features
   - Hardware requirements
   - AWS Lambda setup (copy-paste code)
   - Build & upload instructions

2. **[DEPLOYMENT.md](DEPLOYMENT.md)** ← **Next**
   - Quick-start summary
   - Device access URLs
   - Troubleshooting guide

---

## 📖 Complete Documentation

### For Setup & Configuration
- **[README.md](README.md)** - Comprehensive setup guide
  - Hardware setup
  - AWS Lambda creation
  - WiFi configuration
  - Build and upload steps

### For Verification & Testing
- **[CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md)** - Verification checklist
  - Device-level testing
  - CloudWatch log verification
  - Troubleshooting steps
  - Log buffer details
  - Query examples

### For Understanding the Project
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Complete overview
  - What you have (features, infrastructure)
  - How it works (30-second cycle)
  - Usage examples
  - Architecture diagram
  - Free tier coverage

### For Code Deep Dive
- **[CODE_STRUCTURE.md](CODE_STRUCTURE.md)** - Implementation details
  - Main firmware components
  - Log buffering system
  - CloudWatch upload mechanism
  - Lambda function code
  - Memory & performance metrics
  - Optional enhancements

### For CloudWatch Dashboard (New!)
- **[CDK_GUIDE.md](CDK_GUIDE.md)** - AWS CDK Dashboard Setup
  - What gets created (dashboard, alarms, SNS)
  - Quick start (1 command deployment)
  - Customization (thresholds, notifications)
  - Usage examples
  - Troubleshooting

### For Quick Reference
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Troubleshooting & quick-start
  - Device quick-start
  - Web dashboard access
  - API endpoints
  - Log upload cycle
  - Build/upload commands

---

## 🎯 By Use Case

### "I just want it working"
1. Read: [README.md](README.md) (Setup section)
2. Create: AWS Lambda function (copy code from README)
3. Upload: Firmware with `platformio run -e nodemcuv2 --target upload`
4. Verify: Check CloudWatch Logs in AWS Console

### "How do I check if it's working?"
1. Read: [CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md)
2. Run: `platformio device monitor` and look for "HTTP Code: 200"
3. Check: CloudWatch log group `esp-sensor-logs` has entries

### "I want to understand the architecture"
1. Read: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Architecture section
2. Read: [CODE_STRUCTURE.md](CODE_STRUCTURE.md) - Data flow diagram

### "I need to make changes"
1. Read: [CODE_STRUCTURE.md](CODE_STRUCTURE.md) - Component breakdown
2. Edit: `src/main.cpp` (see "Main Components" section)
3. Rebuild: `platformio run -e nodemcuv2 --target upload`

### "Something isn't working"
1. Read: [DEPLOYMENT.md](DEPLOYMENT.md) - Troubleshooting section
2. Read: [CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md) - Debug checklist
3. Run: Serial monitor (`platformio device monitor`)

---

## 📋 All Documentation Files

| File | Purpose | Read Time |
|------|---------|-----------|
| **README.md** | Complete setup & reference | 15 min |
| **DEPLOYMENT.md** | Quick-start & troubleshooting | 5 min |
| **PROJECT_SUMMARY.md** | Architecture & overview | 10 min |
| **CLOUDWATCH_VERIFICATION.md** | Testing & verification | 8 min |
| **CODE_STRUCTURE.md** | Implementation details | 15 min |
| **CDK_GUIDE.md** | CloudWatch Dashboard setup | 10 min |
| **DOCUMENTATION.md** | This file (navigation) | 3 min |

---

## 🔍 Finding What You Need

### "How do I build and upload?"
→ [README.md - Build & Upload section](README.md#build--upload)

### "What's the Lambda code?"
→ [README.md - Lambda Setup section](README.md#create-lambda-function)

### "How do I create a CloudWatch dashboard?"
→ [CDK_GUIDE.md - Quick Start section](CDK_GUIDE.md#quick-start)

### "How do I access temperature from my phone?"
→ [DEPLOYMENT.md - Access the Device section](DEPLOYMENT.md#access-the-device)

### "What gets logged to CloudWatch?"
→ [CLOUDWATCH_VERIFICATION.md - What Gets Logged section](CLOUDWATCH_VERIFICATION.md#what-gets-logged-to-cloudwatch)

### "Why is my device not uploading logs?"
→ [CLOUDWATCH_VERIFICATION.md - Troubleshooting section](CLOUDWATCH_VERIFICATION.md#troubleshooting-cloudwatch-integration)

### "Can I add more sensors?"
→ [CODE_STRUCTURE.md - Optional Enhancements section](CODE_STRUCTURE.md#optional-enhancements)

### "What's the data format?"
→ [CODE_STRUCTURE.md - CloudWatch Upload section](CODE_STRUCTURE.md#5-cloudwatch-upload-lines-125-165)

### "How much will this cost?"
→ [PROJECT_SUMMARY.md - AWS Free Tier Coverage](PROJECT_SUMMARY.md#aws-free-tier-coverage)

---

## 🛠️ Common Commands

### Build firmware
```bash
source ~/.venvs/platformio/bin/activate
platformio run -e nodemcuv2
```

### Upload to device
```bash
platformio run -e nodemcuv2 --target upload
```

### Monitor serial output
```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

### Deploy CloudWatch Dashboard (CDK)
```bash
cd cdk
pip install -r requirements.txt
npm install -g aws-cdk
cdk deploy
```

### View CloudWatch logs
AWS Console → CloudWatch → Logs → Log Groups → esp-sensor-logs

### Access device temperature
```bash
curl http://192.168.1.100/temperaturec  # Celsius
curl http://192.168.1.100/temperaturef  # Fahrenheit
curl http://192.168.1.100/               # Dashboard
```

---

## 📊 Project Structure

```
esp12f_ds18b20_temp_sensor/
├── README.md                      ← SETUP & REFERENCE
├── DEPLOYMENT.md                  ← QUICK-START
├── PROJECT_SUMMARY.md             ← ARCHITECTURE
├── CLOUDWATCH_VERIFICATION.md     ← TESTING
├── CODE_STRUCTURE.md              ← IMPLEMENTATION
├── DOCUMENTATION.md               ← YOU ARE HERE
│
├── platformio.ini                 # Build configuration
├── .gitignore                     # Excludes secrets.h
│
├── src/
│   └── main.cpp                   # 520+ lines of firmware
├── include/
│   └── secrets.h                  # WiFi & AWS credentials
├── lib/
│   ├── OneWire/                   # OneWire protocol
│   └── DallasTemperature/         # DS18B20 driver
└── test/
    └── README                     # Testing notes
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Device reads temperature every 30 seconds (serial monitor)
- [ ] Lambda receives data (HTTP Code: 200 in serial output)
- [ ] CloudWatch log group `esp-sensor-logs` exists
- [ ] Log stream `garage-temperature` contains entries
- [ ] Web dashboard accessible at `http://<device-ip>/`
- [ ] API endpoints return temperature (`/temperaturec`, `/temperaturef`)

See [CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md) for detailed checks.

---

## 🎓 Learning Path

**Beginner** (just want it working):
1. [README.md](README.md) - Setup section
2. [DEPLOYMENT.md](DEPLOYMENT.md) - Quick-start

**Intermediate** (understand how it works):
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Architecture
2. [CODE_STRUCTURE.md](CODE_STRUCTURE.md) - Components

**Advanced** (modify & extend):
1. [CODE_STRUCTURE.md](CODE_STRUCTURE.md) - Full code breakdown
2. Modify `src/main.cpp`
3. Add additional sensors
4. Create CloudWatch dashboards

---

## 🆘 Support

### If something isn't working:

1. **Check device first**:
   ```bash
   platformio device monitor -p /dev/ttyUSB0 -b 115200
   ```
   Look for errors in output (15-30 seconds)

2. **Read the guide**:
   - [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) - Troubleshooting
   - [CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md#troubleshooting-cloudwatch-integration) - CloudWatch issues

3. **Check specific component**:
   - Device won't connect to WiFi? → README.md Troubleshooting
   - Logs not in CloudWatch? → CLOUDWATCH_VERIFICATION.md
   - Temperature reads as "--"? → CODE_STRUCTURE.md (DS18B20 section)

---

## 📈 What's Next?

### Suggested Next Steps

1. **Verify everything works** (see checklist above)

2. **Optional: Set up alarms**
   - AWS CloudWatch → Alarms → Create
   - Alert when temperature > 30°C
   - Send email notification

3. **Optional: Create dashboard**
   - CloudWatch Dashboards
   - Graph temperature over time
   - Add custom widgets

4. **Optional: Add more sensors**
   - Humidity (DHT22)
   - Pressure (BMP280)
   - CO2 (MH-Z19)
   - See CODE_STRUCTURE.md for examples

5. **Optional: Export to other services**
   - S3 for long-term storage
   - Grafana for visualization
   - DynamoDB for queryable logs

---

## 📞 Quick Reference

| Need | Location |
|------|----------|
| WiFi setup | [README.md](README.md#2-wifi-credentials) |
| AWS Lambda code | [README.md](README.md#create-lambda-function) |
| Build instructions | [README.md](README.md#4-build--upload) |
| Device endpoints | [DEPLOYMENT.md](DEPLOYMENT.md#access-the-device) |
| Troubleshooting | [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) |
| CloudWatch verification | [CLOUDWATCH_VERIFICATION.md](CLOUDWATCH_VERIFICATION.md) |
| Code explanation | [CODE_STRUCTURE.md](CODE_STRUCTURE.md) |
| CloudWatch Dashboard | [CDK_GUIDE.md](CDK_GUIDE.md) |
| Architecture | [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#architecture-diagram) |
| Cost breakdown | [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#aws-free-tier-coverage) |

---

## 🎉 You're Ready!

Your ESP8266 temperature logger is **fully documented** and **ready to deploy**!

**Start with [README.md](README.md) if you haven't already.**

---

*Last updated: November 13, 2025*  
*Status: ✅ Complete & Operational*
