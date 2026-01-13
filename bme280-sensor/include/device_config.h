#ifndef DEVICE_CONFIG_H
#define DEVICE_CONFIG_H

/**
 * BME280 Environmental Sensor - Device Configuration
 * Per-device hardware settings and timing defaults
 */

// BME280 I2C Configuration
// Pin assignments vary by board:
// - ESP32-S3 WROOM: SDA=GPIO 8, SCL=GPIO 9
// - ESP32 (standard): SDA=GPIO 21, SCL=GPIO 22
#if defined(ARDUINO_FREENOVE_ESP32_S3_WROOM) || defined(ESP32S3)
  static const int BME280_I2C_SDA = 8;   // ESP32-S3 SDA
  static const int BME280_I2C_SCL = 9;   // ESP32-S3 SCL
#else
  static const int BME280_I2C_SDA = 21;  // ESP32 SDA
  static const int BME280_I2C_SCL = 22;  // ESP32 SCL
#endif
static const int BME280_I2C_ADDR = 0x76;  // I2C address (0x76 if SDO low, 0x77 if SDO high)

// Device board type - Auto-detected from build environment
#if defined(ESP32S3)
  static const char* DEVICE_BOARD = "esp32s3";
#elif defined(ESP32)
  static const char* DEVICE_BOARD = "esp32";
#else
  static const char* DEVICE_BOARD = "esp8266";
#endif

// Timing constants
static const unsigned long WIFI_CHECK_INTERVAL_MS = 15000;    // Check WiFi connection every 15s
static const unsigned long SENSOR_READ_INTERVAL_MS = 30000;   // Read sensor every 30s
#ifdef ESP8266
  static const int HTTP_TIMEOUT_MS = 5000;   // 5s timeout for ESP8266
#else
  static const int HTTP_TIMEOUT_MS = 10000;  // 10s timeout for ESP32
#endif

// =============================================================================
// BATTERY MONITORING (Optional)
// =============================================================================
// Complete battery setup with TP4056 charger: see docs/hardware/BATTERY_SETUP_GUIDE.md
// Voltage divider required: Battery+ -> 10K -> ADC_PIN -> 10K -> GND
// 
// ADC Pin Assignments:
//   - ESP32 (original): GPIO 34 (ADC1_CH6)
//   - ESP32-S3: GPIO 4 (ADC1_CH3) - Pin 34 does not exist on S3!
//
// IMPORTANT: Only enable battery monitoring on battery-powered builds
// ESP32-S3 does NOT support battery monitoring by default (no ADC pin configured)
#if defined(BATTERY_POWERED) && !defined(ESP32S3)
  #define BATTERY_MONITOR_ENABLED
#endif

#ifndef BATTERY_POWERED
  #define BATTERY_POWERED 0
#endif

#ifndef OLED_ENABLED
  #define OLED_ENABLED 0
#endif

#ifndef API_ENDPOINTS_ONLY
  #define API_ENDPOINTS_ONLY 0
#endif

#ifdef BATTERY_MONITOR_ENABLED
  #if defined(ESP32S3)
    static const int BATTERY_PIN = 4;            // ESP32-S3: GPIO 4 (ADC1_CH3)
    static const float VOLTAGE_DIVIDER = 2.0;    // Voltage divider ratio
    static const float CALIBRATION = 1.134;      // Calibration factor
    static const float ADC_MAX = 4095.0;         // 12-bit ADC
    static const float REF_VOLTAGE = 3.3;        // ESP32-S3 reference voltage
    static const float BATTERY_MIN_V = 3.0;      // 0% battery voltage
    static const float BATTERY_MAX_V = 4.2;      // 100% battery voltage
  #elif defined(ESP32)
    static const int BATTERY_PIN = 34;           // ESP32: GPIO 34 (ADC1_CH6)
    static const float VOLTAGE_DIVIDER = 2.0;    // Voltage divider ratio
    static const float CALIBRATION = 1.134;      // Calibration factor
    static const float ADC_MAX = 4095.0;         // 12-bit ADC
    static const float REF_VOLTAGE = 3.3;        // ESP32 reference voltage
    static const float BATTERY_MIN_V = 3.0;      // 0% battery voltage
    static const float BATTERY_MAX_V = 4.2;      // 100% battery voltage
  #else
    #error "Battery monitoring configuration missing for this platform"
  #endif
#endif

// =============================================================================
// LOW-POWER CONFIGURATION
// =============================================================================

#ifdef ESP8266
  #define CPU_FREQ_MHZ 80  // ESP8266: 80 MHz (vs 160 MHz default)
#else
  #define CPU_FREQ_MHZ 80  // ESP32: 80 MHz (vs 240 MHz default)
#endif

// =============================================================================
// SENSOR COMPENSATION PARAMETERS
// =============================================================================
// Adjust these based on environmental calibration or sensor placement

// Temperature offset (degrees C) - adjust if sensor reads high/low
static const float TEMP_OFFSET = 0.0;

// Pressure sea-level reference (Pa) - for altitude calculation
static const float PRESSURE_SEA_LEVEL = 101325.0;

// Pressure baseline configuration (for barometer-style weather tracking)
// Set to local station pressure for weather monitoring:
//   - Sea level: 101.325 kPa (1013.25 hPa)
//   - High altitude: ~98.0 kPa (980 hPa) for 200m elevation
//   - Set to 0.0 to disable baseline tracking

// =============================================================================
// RESET DETECTION & CRASH RECOVERY (ESP32 Only)
// =============================================================================
#ifdef ESP32
  #define RESET_DETECT_TIMEOUT 2       // 2 second window for triple-reset
  // Allows time to press reset 3 times to trigger config portal
  #define RESET_COUNT_THRESHOLD 3      // Number of resets to trigger config portal
  // Pressing reset button 3 times within 2 seconds enters portal mode
  #define CRASH_LOOP_THRESHOLD 5       // 5 consecutive crashes triggers recovery mode
  #define CRASH_LOOP_MAGIC 0xDEADBEEF  // Magic number to detect incomplete boots
#endif
// Adjust via MQTT commands:
//   - "calibrate" or "set_baseline": Use current reading
//   - "baseline 980.0": Set specific value in hPa
//   - "clear_baseline": Disable tracking
static const float PRESSURE_BASELINE_DEFAULT = 0.0;  // Pa (0 = disabled)
static const char* PRESSURE_BASELINE_FILE = "/pressure_baseline.txt";

// Humidity calibration (optional)
// Adjust if sensor consistently reads high/low compared to reference
static const float HUMIDITY_OFFSET = 0.0;  // ±% RH adjustment

#endif // DEVICE_CONFIG_H
