#ifndef OneWire_Direct_RegType_h
#define OneWire_Direct_RegType_h

// Register types for platforms where IO_REG_TYPE isn't the normal uint8_t
// Note: This header is intended for internal use only.

#if defined(ARDUINO_ARCH_ESP32) || defined(__riscv) || defined(__IMXRT1062__)
#define IO_REG_TYPE uint32_t
#else
#define IO_REG_TYPE uint8_t
#endif

#endif
