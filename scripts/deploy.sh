#!/bin/bash
cd /home/aachten/PlatformIO/esp12f_ds18b20_temp_sensor
export PYTHONPATH=/home/aachten/.local/lib/python3.10/site-packages:$PYTHONPATH
cdk deploy --require-approval never
