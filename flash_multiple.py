#!/usr/bin/env python3
"""
Flash multiple ESP8266 devices with the same firmware
Allows you to flash to multiple USB ports sequentially
"""

import subprocess
import sys
import os
import argparse
from pathlib import Path

def list_devices():
    """List available serial ports"""
    print("\n=== Available Serial Ports ===")
    try:
        result = subprocess.run(['ls', '-1', '/dev/ttyUSB*'], 
                              capture_output=True, text=True, shell=True)
        if result.stdout.strip():
            devices = result.stdout.strip().split('\n')
            for i, device in enumerate(devices, 1):
                print(f"{i}. {device}")
            return devices
        else:
            print("No USB serial devices found!")
            return []
    except Exception as e:
        print(f"Error listing devices: {e}")
        return []

def flash_device(port, env='nodemcuv2'):
    """Flash firmware to a specific device"""
    print(f"\n{'='*60}")
    print(f"Flashing {port}...")
    print(f"{'='*60}")
    
    try:
        cmd = ['platformio', 'run', '--target', 'upload', '-e', env, '--upload-port', port]
        result = subprocess.run(cmd, cwd=Path(__file__).parent)
        
        if result.returncode == 0:
            print(f"✅ Successfully flashed {port}")
            return True
        else:
            print(f"❌ Failed to flash {port}")
            return False
    except Exception as e:
        print(f"❌ Error flashing {port}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Flash multiple ESP8266 devices')
    parser.add_argument('--list', action='store_true', help='List available devices')
    parser.add_argument('--ports', nargs='+', help='Specific ports to flash (e.g., /dev/ttyUSB0 /dev/ttyUSB1)')
    parser.add_argument('--all', action='store_true', help='Flash all detected devices')
    parser.add_argument('--env', default='nodemcuv2', help='PlatformIO environment (default: nodemcuv2)')
    
    args = parser.parse_args()
    
    if args.list:
        devices = list_devices()
        sys.exit(0)
    
    devices_to_flash = []
    
    if args.ports:
        devices_to_flash = args.ports
    elif args.all:
        devices_to_flash = list_devices()
        if not devices_to_flash:
            print("No devices found!")
            sys.exit(1)
    else:
        # Interactive mode
        devices = list_devices()
        if not devices:
            sys.exit(1)
        
        print("\n=== Flash Multiple Devices ===")
        print("Options:")
        print("  (A)ll - Flash all devices")
        print("  (S)elect - Choose specific devices")
        print("  (Q)uit - Exit")
        
        choice = input("\nEnter choice (A/S/Q): ").upper()
        
        if choice == 'A':
            devices_to_flash = devices
        elif choice == 'S':
            print("\nEnter device numbers separated by space (e.g., 1 2):")
            try:
                selections = [int(x) - 1 for x in input().split()]
                devices_to_flash = [devices[i] for i in selections if 0 <= i < len(devices)]
            except (ValueError, IndexError):
                print("Invalid selection")
                sys.exit(1)
        else:
            print("Exiting")
            sys.exit(0)
    
    if not devices_to_flash:
        print("No devices to flash!")
        sys.exit(1)
    
    print(f"\n📋 Will flash {len(devices_to_flash)} device(s):")
    for i, port in enumerate(devices_to_flash, 1):
        print(f"   {i}. {port}")
    
    confirm = input("\nProceed with flashing? (yes/no): ").lower()
    if confirm != 'yes':
        print("Cancelled")
        sys.exit(0)
    
    # Flash each device
    results = {}
    for port in devices_to_flash:
        print(f"\n⏳ Flashing device {devices_to_flash.index(port) + 1}/{len(devices_to_flash)}")
        success = flash_device(port, args.env)
        results[port] = success
        
        if success and devices_to_flash.index(port) < len(devices_to_flash) - 1:
            input("\n✅ Device flashed! Connect next device and press Enter...")
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    successful = sum(1 for v in results.values() if v)
    for port, success in results.items():
        status = "✅ SUCCESS" if success else "❌ FAILED"
        print(f"{port}: {status}")
    print(f"\nTotal: {successful}/{len(devices_to_flash)} successfully flashed")
    
    sys.exit(0 if successful == len(devices_to_flash) else 1)

if __name__ == '__main__':
    main()
