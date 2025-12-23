#ifndef VERSION_H
#define VERSION_H

/**
 * Firmware Version Information
 * Automatically generated from build flags
 */

#include <Arduino.h>

// Version components from build flags
#define FIRMWARE_VERSION_STRING String(FIRMWARE_VERSION_MAJOR) + "." + String(FIRMWARE_VERSION_MINOR) + "." + String(FIRMWARE_VERSION_PATCH) + "-build" + String(BUILD_TIMESTAMP)

// Helper function to get version string
inline String getFirmwareVersion() {
    return FIRMWARE_VERSION_STRING;
}

#endif // VERSION_H