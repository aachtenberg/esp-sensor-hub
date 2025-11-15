#ifndef DEVICE_CONFIG_H
#define DEVICE_CONFIG_H

/**
 * Device Configuration
 * Each ESP device can have a unique location name and board type
 * Update DEVICE_LOCATION and DEVICE_BOARD for each device before flashing
 */

// Device location name (appears in InfluxDB, Lambda logs, and Home Assistant)
// Examples: "Big Garage", "Bedroom", "Living Room", "Basement", "Attic", etc.
static const char* DEVICE_LOCATION = "Pump House";

// Optional: Device ID (useful for Home Assistant entity identification)
// If empty, will use chip ID (MAC address)
static const char* DEVICE_ID = "";

// Device board type - MUST match the physical hardware!
// Options: "esp8266" or "esp32"
// This is set automatically by flash_device.sh, but you can override here if needed
static const char* DEVICE_BOARD = "esp8266";

// Device timezone offset (hours from UTC)
// Used for logging timestamps
static const int TIMEZONE_OFFSET = -5;  // EST/CDT

#endif // DEVICE_CONFIG_H
