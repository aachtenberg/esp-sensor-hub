# GitHub Copilot Project Summary: ESP Multi-Device Temperature Sensor

This document outlines the work completed by GitHub Copilot to build, debug, and refactor a temperature sensor project designed to run on both ESP8266 and ESP32 microcontrollers. The project evolved from a single-device setup to a robust, multi-board solution with a streamlined flashing process and several critical bug fixes.

## 1. Project Evolution & Key Fixes

The project underwent several major iterations to resolve bugs and add features.

### Initial State:
- The project was initially configured for a single board type.
- The build process was failing due to incorrect library dependencies and missing Python packages.
- The device was experiencing runtime crashes, particularly on the ESP8266, due to memory issues.

### Phase 1: Build & Dependency Resolution
- **Problem**: The initial build failed because the ESP32 requires a different asynchronous TCP library (`AsyncTCP`) than the ESP8266 (`ESPAsyncTCP`).
- **Solution**:
    1.  Modified `platformio.ini` to use `me-no-dev/AsyncTCP` for the ESP32.
    2.  Corrected a missing Python dependency (`intelhex`) required by PlatformIO's `esptool.py` by running `pip install intelhex`.
    3.  Fixed conditional compilation flags in `main.cpp` to include the correct headers (`HTTPClient` for ESP32) and API calls (`WiFi.setSleep(false)` for ESP32 vs. `WiFi.setSleepMode()` for ESP8266).

### Phase 2: Multi-Board Architecture
- **Problem**: The project needed to support both ESP8266 and ESP32 devices from the same codebase without manual configuration changes for each flash.
- **Solution**:
    1.  **`platformio.ini` Refactor**: Created two distinct environments: `[env:esp32dev]` and `[env:esp8266]`, each with the correct platform and board settings.
    2.  **`flash_device.sh` Script**: Heavily modified the script to accept a board type (`esp32` or `esp8266`) as an argument. The script now automatically selects the correct PlatformIO environment.
    3.  **`device_config.h`**: Added a `DEVICE_BOARD` variable, which the flash script updates automatically. This allows the C++ code to know which board it's running on.

### Phase 3: Fixing Runtime Errors (Lambda 500 & Memory Crashes)
- **Problem**: The ESP8266 device was crashing and rebooting. When it did run, it sent a malformed JSON payload to AWS Lambda, resulting in an HTTP 500 error.
- **Solution**:
    1.  **JSON Payload Fix**: Corrected a missing comma in the JSON string being built in `sendToLambda()`.
    2.  **Memory Optimization**: The primary cause of crashes was memory exhaustion on the ESP8266.
        - The `sendToLambda()` function was rewritten to use `snprintf` instead of `String` concatenation, which dramatically reduced heap fragmentation.
        - The large, buffered log payload was removed in favor of a simple, direct temperature payload.
        - The MQTT client, which consumes significant RAM, was disabled for the ESP8266 build.
    3.  **Logging Reduction**: Removed verbose `Serial.println` statements from the main loop to clean up the output and reduce overhead.

## 2. Final Architecture & How to Use

The project is now stable, configurable, and easy to manage.

### Configuration Files
- **`include/secrets.h`**: Stores all sensitive information like WiFi credentials, InfluxDB tokens, and AWS keys. **This file should not be committed to version control.**
- **`include/device_config.h`**: Stores the device's location and board type. These values are **set automatically** by the `flash_device.sh` script.

### Flashing a Device
The `flash_device.sh` script is the primary tool for flashing.

**Usage**:
```bash
./flash_device.sh "Device Location" [board_type]
```
- `Device Location`: A string that will identify the device (e.g., "Pump House").
- `board_type`: Either `esp32` or `esp8266`.

**Examples**:
```bash
# Flash an ESP32 device for the garage
./flash_device.sh "Big Garage" esp32

# Flash an ESP8266 device for the pump house
./flash_device.sh "Pump House" esp8266
```

### Monitoring
After flashing, the script will prompt you to monitor the serial output. You can also do this manually:
```bash
pio device monitor -b 115200
```

### Accessing the Web Interface
Once a device is connected to WiFi, you can view its temperature by navigating to its IP address in a web browser (e.g., `http://192.168.0.204`). The IP address is printed in the serial monitor on boot.
