# Progress

## Done

### December 2025 - ESP32-S3 Triple-Reset Detection Fix
- [x] Diagnosed RTC memory persistence issue on ESP32-S3 architecture
- [x] Implemented NVS-based reset detection using Arduino Preferences library
- [x] Refactored `checkResetCounter()` and `clearCrashLoop()` functions to use NVS
- [x] Optimized `setup()` timing - moved reset check before Serial.begin() delay
- [x] Enhanced web server with WIFI_AP_STA mode for simultaneous AP/STA operation
- [x] Enhanced logging to display both STA and AP IP addresses
- [x] Built and flashed ESP32-S3 firmware (1,176,949 bytes, 37.4% flash usage)
- [x] Verified triple-reset detection working via serial monitor
- [x] Confirmed config portal accessible at 192.168.4.1
- [x] Confirmed web server accessible at STA IP after WiFi connection

### December 2025 - WSL2 OTA Firewall Issue Resolution
- [x] Diagnosed Windows Firewall blocking ESP32 OTA port (3232) from WSL2
- [x] Identified root cause: authentication succeeds but upload fails with "No response from device"
- [x] Verified device shows "OTA:ready" and network connectivity works (ping succeeds)
- [x] Confirmed temporary firewall disable resolves issue immediately
- [x] Updated platformio.ini with correct OTA configuration (upload_port, upload_flags)
- [x] Added comprehensive troubleshooting section to docs/reference/CONFIG.md
- [x] Updated docs/reference/COPILOT_INSTRUCTIONS.md with WSL2 OTA issue documentation
- [x] Verified OTA upload works after firewall adjustment (100% success rate)
- [x] Documented both temporary and permanent firewall rule solutions

### December 2025 - Documentation Consolidation
- [x] Updated root README.md with ESP32-S3 platform-specific notes
- [x] Updated surveillance/README.md with complete NVS implementation details
- [x] Updated docs/solar-monitor/README.md with corrected portal addresses
- [x] Updated solar-monitor/README.md with portal access instructions
- [x] Updated surveillance/.github/copilot-instructions.md with reset detection notes
- [x] Added platform comparison (ESP32-S3 vs ESP32/ESP8266) to all relevant docs
- [x] Corrected portal addresses to 192.168.4.1 throughout documentation
- [x] Enhanced troubleshooting sections with platform-specific guidance

### December 2025 - Security Audit & Repository Sanitization
- [x] Scanned all secrets.h.example files for hardcoded IPs and credentials
- [x] Replaced hardcoded internal IPs with generic placeholders (6 files sanitized)
- [x] Removed hardcoded username "aachten" from PowerShell scripts
- [x] Updated scripts to use environment variables ($env:USER, $USER, ~)
- [x] Verified no SSH keys, tokens, or credentials exposed in repository
- [x] Confirmed .gitignore properly configured for secrets.h files
- [x] Consolidated duplicate GitHub Actions workflows (secrets-check.yml)
- [x] Enhanced secrets-check.yml with template validation
- [x] Repository ready for public publication

### December 2025 - Firmware Version Tracking Implementation
- [x] Implemented automatic firmware version tracking with build timestamps
- [x] Added version.h header with getFirmwareVersion() function
- [x] Updated platformio.ini with version build flags (MAJOR.MINOR.PATCH-buildYYYYMMDD)
- [x] Integrated version tracking into all MQTT messages (temperature, status, events)
- [x] Created update_version.sh script for automatic build timestamp updates
- [x] Updated COPILOT_INSTRUCTIONS.md with versioning documentation
- [x] Updated CONFIG.md with version tracking procedures
- [x] Tested OTA with version tracking (confirmed version changes in MQTT events)
- [x] Created README_VERSION.md with comprehensive versioning documentation

### Initial Project Setup
- [x] Initialize project structure with three ESP devices
- [x] Set up PlatformIO configurations for temperature-sensor, solar-monitor, surveillance
- [x] Implement MQTT trace instrumentation
- [x] Create comprehensive documentation structure

## Doing

- [ ] Review feature/mqtt-trace-instrumentation branch for merge
- [ ] Tag release version with ESP32-S3 support

## Next

### Short Term
- [ ] Test NVS solution on additional ESP32-S3 boards to confirm reliability
- [ ] Consider backporting NVS solution to temperature-sensor and solar-monitor for consistency
- [ ] Evaluate ESP32-C6 support (WiFi 6 + Bluetooth 5)

### Long Term  
- [ ] Update PCB designs if targeting ESP32-S3 hardware
- [ ] Implement OTA update mechanism for field deployments
- [ ] Explore power optimization for battery-powered scenarios
- [ ] Add automated testing for reset detection across platforms