# ESP8266 DS18B20 Temperature Sensor with CloudWatch Logging

A PlatformIO-based ESP8266 firmware that reads temperature from a DS18B20 sensor and logs all data, errors, and diagnostics to **AWS CloudWatch** via a serverless Lambda function.

## Features

- 🌡️ **DS18B20 Temperature Readings**: Reads temperature every 30 seconds
- 📊 **WiFi Web Dashboard**: HTTP endpoints for real-time temperature (`/temperaturec`, `/temperaturef`)
- 🔐 **CloudWatch Integration**: All device logs (temperature, errors, diagnostics) automatically uploaded to AWS CloudWatch Logs
- 🚀 **Serverless Architecture**: Uses AWS Lambda + API Gateway (no VPS/MQTT broker required)
- 🛠️ **Clean Logging**: Centralized log buffering prevents serial spam; all messages captured and sent to CloudWatch

## Hardware

- **ESP8266** (NodeMCU v2 recommended)
- **DS18B20** Temperature Sensor (1-Wire protocol on GPIO 4)
- **Micro USB** cable for power/programming

## Setup

### 1. Clone & Configure

```bash
cd esp12f_ds18b20_temp_sensor
```

### 2. WiFi Credentials

Edit `include/secrets.h`:

```cpp
static const char* WIFI_SSID = "Your_WiFi_SSID";
static const char* WIFI_PASSWORD = "Your_WiFi_Password";
```

### 3. AWS Lambda Setup

#### Create Lambda Function

1. **AWS Console** → **Lambda** → **Create function**
2. **Name**: `esp-temperature-logger`
3. **Runtime**: Python 3.11
4. **Paste this code**:

```python
import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Parse incoming JSON from ESP8266
        body = json.loads(event.get('body', '{}'))
        
        device = body.get('device', 'unknown')
        temp_c = body.get('tempC', 'N/A')
        temp_f = body.get('tempF', 'N/A')
        log_count = body.get('logCount', 0)
        logs = body.get('logs', [])
        
        # Log temperature
        logger.info(f"Device: {device} | Temp: {temp_c}°C / {temp_f}°F")
        
        # Log all buffered device messages
        for log_entry in logs:
            msg = log_entry.get('msg', '')
            logger.info(f"Device Log: {msg}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Logged {log_count} entries successfully',
                'device': device,
                'temp': f'{temp_c}°C / {temp_f}°F'
            })
        }
    
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

5. **Click "Deploy"**

#### Create API Gateway

1. In Lambda function, scroll to **Function overview**
2. Click **+ Add trigger**
3. Select **API Gateway**
4. Create new API:
   - **API type**: REST API
   - **Security**: API key (optional) or CORS enabled
   - Click **Create**
5. **Copy the Invoke URL** (looks like `https://xxxxxxxxxx.execute-api.ca-central-1.amazonaws.com/default`)

#### Update ESP8266 Secrets

Edit `include/secrets.h`:

```cpp
static const char* LAMBDA_ENDPOINT = "https://YOUR_API_ID.execute-api.ca-central-1.amazonaws.com/default/esp-temperature-logger";
```

### 4. Build & Upload

```bash
# Activate PlatformIO venv (if using isolated environment)
source ~/.venvs/platformio/bin/activate

# Build
platformio run -e nodemcuv2

# Upload
platformio run -e nodemcuv2 --target upload

# Monitor serial output
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

## Usage

### Web Dashboard

Once connected to WiFi, access the device via its local IP:

- **`http://<ESP_IP>/`** - HTML dashboard with live temperature
- **`http://<ESP_IP>/temperaturec`** - Current temperature in Celsius (plain text)
- **`http://<ESP_IP>/temperaturef`** - Current temperature in Fahrenheit (plain text)

**Example**:
```bash
# Get Celsius temperature
curl http://192.168.1.100/temperaturec
# Output: 23.56

# Get Fahrenheit temperature
curl http://192.168.1.100/temperaturef
# Output: 74.41
```

### CloudWatch Logs

View logs in **AWS Console** → **CloudWatch Logs**:

1. **Log Group**: `esp-sensor-logs`
2. **Log Stream**: `garage-temperature` (or your device name)
3. **View entries**: All temperature readings, device errors, and diagnostics appear here with timestamps

**Example log entries**:
```
Device: Big Garage Temperature | Temp: 23.56°C / 74.41°F
Device Log: Temperature C: 23.56
Device Log: Temperature F: 74.41
Device Log: Logs sent to CloudWatch successfully!
```

## Logging Architecture

### Device-Side (ESP8266)

- All `logMessage()` calls buffer to a 50-entry circular log
- Every 30 seconds: temperatures are read and logs sent to Lambda
- After successful Lambda POST (HTTP 200), log buffer is cleared
- Serial output includes all logs for debugging

### Server-Side (Lambda)

- Parses JSON payload with temperature, device name, and log entries
- Writes to CloudWatch Logs using Python's `logging` module
- CloudWatch automatically timestamps each log entry
- Logs are retained per your CloudWatch retention policy

## Configuration

### `platformio.ini`

- **Board**: `nodemcuv2` (ESP8266 NodeMCU v2)
- **Framework**: Arduino ESP8266
- **Monitor Speed**: 115200 baud
- **Library Dependencies**:
  - ESPAsyncTCP 2.0.0
  - ESPAsyncWebServer 3.6.0
  - OneWire (GitHub)
  - DallasTemperature
  - PubSubClient 2.8.0
  - ESP8266HTTPClient 1.2

### `include/secrets.h`

Edit credentials here:

```cpp
// WiFi
static const char* WIFI_SSID = "Your_SSID";
static const char* WIFI_PASSWORD = "Your_Password";

// AWS Lambda endpoint
static const char* LAMBDA_ENDPOINT = "https://YOUR_API.execute-api.ca-central-1.amazonaws.com/default/esp-temperature-logger";

// Optional: MQTT (disabled by default)
static const char* MQTT_BROKER = "192.168.0.167";
static const int MQTT_PORT = 1883;

// Optional: InfluxDB Cloud
static const char* INFLUXDB_URL = "https://us-east-1-1.aws.cloud2.influxdata.com";
```

## Troubleshooting

### Device not connecting to WiFi

- Check SSID/password in `include/secrets.h`
- Verify ESP8266 antenna (external or PCB) is in good contact
- Restart device: `ESP.restart()` in code or power cycle

### Logs not appearing in CloudWatch

1. **Check Lambda execution**: AWS Console → Lambda → `esp-temperature-logger` → **Monitor** tab
2. **Check API Gateway**: Verify Invoke URL is correct in `secrets.h`
3. **Check serial output**: Run `platformio device monitor` to see HTTP response codes
4. **CloudWatch Logs**: Verify log group `esp-sensor-logs` exists and has entries

### HTTP 404 errors from ESP

- Ensure API Gateway **Deploy** was clicked after creating/modifying the function
- Double-check Invoke URL ends with `/esp-temperature-logger` (or your Lambda resource name)

### Temperature reads as "--"

- Check GPIO 4 connection to DS18B20 data pin
- Verify OneWire library is correctly included
- Run `updateTemperatures()` in setup to test sensor immediately

## Optional: Send to InfluxDB Cloud Instead

To also send temperature to InfluxDB Cloud:

1. In `src/main.cpp` loop section, uncomment:
   ```cpp
   // sendToInfluxDB();  // Uncomment to also send to InfluxDB
   ```

2. Configure `include/secrets.h`:
   ```cpp
   static const char* INFLUXDB_URL = "https://us-east-1-1.aws.cloud2.influxdata.com";
   static const char* INFLUXDB_BUCKET = "sensor_data";
   static const char* INFLUXDB_TOKEN = "your_token";
   ```

3. Rebuild and upload

## Optional: CloudWatch Dashboard

To visualize temperature over time in AWS:

1. **AWS Console** → **CloudWatch** → **Dashboards** → **Create dashboard**
2. Add **Metric** widget with:
   - **Source**: CloudWatch Logs Insights
   - **Query**: 
     ```
     fields @timestamp, @message | filter @message like /Temp:/ | stats avg(temp) as temp_avg by bin(1m)
     ```

## Project Structure

```
esp12f_ds18b20_temp_sensor/
├── platformio.ini              # PlatformIO configuration
├── src/
│   └── main.cpp               # Main firmware (WiFi, DS18B20, Lambda logging)
├── include/
│   ├── README                 # Include directory notes
│   └── secrets.h              # WiFi/AWS credentials (add to .gitignore!)
├── lib/
│   ├── OneWire/               # OneWire protocol library
│   └── DallasTemperature/     # DS18B20 temperature library
├── test/
│   └── README                 # Test directory (optional)
└── README.md                  # This file
```

## Security Notes

⚠️ **Important**:

1. **Never commit `include/secrets.h`** to public repos
   - Add to `.gitignore`: `include/secrets.h`
   - Use environment variables in CI/CD

2. **API Gateway**: Currently allows unauthenticated POST
   - For production, enable **AWS_IAM** authentication or API keys

3. **SSL Verification**: ESP8266 disables SSL cert verification (`setInsecure()`)
   - Safe for internal use; consider certificate pinning for public deployments

## License

This project is provided as-is for personal use. See LICENSE file for details.

## Contributing

Feel free to fork and submit PRs for:
- Additional sensor support (humidity, pressure, etc.)
- Grafana dashboard integration
- MQTT fallback support
- OTA firmware updates

---

## 📚 Credits & References

This project is based on the excellent ESP32 DS18B20 temperature sensor tutorial by Random Nerd Tutorials:

- **Tutorial**: [ESP32 DS18B20 Temperature Arduino IDE](https://randomnerdtutorials.com/esp32-ds18b20-temperature-arduino-ide/)
- **Author**: Rui Santos
- **Platform**: Random Nerd Tutorials

The original tutorial provides the foundation for the DS18B20 sensor integration and basic ESP32/ESP8266 setup used in this project. This project extends the original work to support multiple boards, cloud logging to AWS Lambda and InfluxDB Cloud, and production-grade reliability features like exponential backoff and health monitoring.

---

**Happy Monitoring!** 🎉

If you have questions or issues, check the serial monitor output first:
```bash
platformio device monitor -p /dev/ttyUSB0 -b 115200
```

````
