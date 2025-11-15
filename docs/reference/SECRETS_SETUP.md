# Configuration & Secrets Setup

## Secrets Management

The `include/secrets.h` file contains all sensitive credentials and is **excluded from version control** for security.

### Initial Setup

1. **Copy the example file**:
   ```bash
   cp include/secrets.h.example include/secrets.h
   ```

2. **Edit `include/secrets.h`** with your credentials:
   ```cpp
   static const char* WIFI_SSID = "YOUR_NETWORK_NAME";
   static const char* WIFI_PASSWORD = "YOUR_PASSWORD";
   static const char* INFLUXDB_TOKEN = "YOUR_TOKEN";
   // ... etc
   ```

3. **Never commit** `secrets.h` to git (already in `.gitignore`)

## Required Credentials

### WiFi
- `WIFI_SSID` - Your WiFi network name
- `WIFI_PASSWORD` - Your WiFi password
- `STATIC_IP` - (optional) Set to fixed IP, leave empty for DHCP

### InfluxDB Cloud
- `INFLUXDB_URL` - Your InfluxDB Cloud instance URL
- `INFLUXDB_BUCKET` - Bucket name (e.g., "sensor_data")
- `INFLUXDB_TOKEN` - InfluxDB API token with write permissions

### AWS Lambda
- `LAMBDA_ENDPOINT` - Your API Gateway endpoint URL
- No authentication required (public endpoint)

### AWS CloudWatch (optional)
- `AWS_ACCESS_KEY_ID` - IAM user access key
- `AWS_SECRET_ACCESS_KEY` - IAM user secret key
- `AWS_REGION` - AWS region (e.g., "ca-central-1")
- `AWS_LOG_GROUP` - CloudWatch log group name
- `AWS_LOG_STREAM` - CloudWatch log stream name

### MQTT (optional)
- `MQTT_BROKER` - Broker IP/hostname
- `MQTT_PORT` - Port (default 1883)
- `MQTT_USER` / `MQTT_PASSWORD` - Credentials (if required)

### BigQuery (optional)
- `BIGQUERY_TOKEN` - Service account token

## Device Configuration

The `include/device_config.h` file stores device-specific settings:

```cpp
static const char* DEVICE_LOCATION = "Big Garage";
static const char* DEVICE_BOARD = "esp8266";
```

These are automatically updated when using the flash script:
```bash
scripts/flash_device.sh "Device Location" esp8266
```

## Security Best Practices

1. ✅ Keep `secrets.h` in `.gitignore` (already configured)
2. ✅ Use example file (`secrets.h.example`) as template
3. ✅ Rotate API tokens regularly
4. ✅ Use least-privilege IAM policies
5. ✅ Monitor CloudWatch logs for suspicious activity
6. ✅ Enable MFA on AWS account

## Troubleshooting

**"Undefined reference to WIFI_SSID"**
- Ensure `include/secrets.h` exists (copy from `secrets.h.example`)
- Check file is in `include/` directory
- Rebuild: `platformio run -e esp8266`

**Build fails with missing credentials**
- Verify all required fields in `secrets.h` are filled
- No empty string values (use placeholder if not needed)

**"Invalid credentials" at runtime**
- Double-check token/key values (often have typos)
- Verify credentials have correct permissions
- Check tokens haven't expired
