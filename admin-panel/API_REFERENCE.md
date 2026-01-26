# Admin Panel API Reference

## REST API Endpoints

### GET /api/devices
Returns list of all connected devices with their current state.

**Response:**
```json
[
  {
    "name": "Temp Sensor",
    "mqtt_name": "Temp-Sensor",
    "online": true,
    "mqtt_state": {
      "last_seen": "2024-01-15T10:30:45.123Z",
      "temperature": {
        "topic": "esp-sensor-hub/Temp-Sensor/temperature",
        "payload": {
          "current_temp_c": 23.5,
          "humidity": 45
        }
      },
      "status": {
        "topic": "esp-sensor-hub/Temp-Sensor/status",
        "payload": {
          "ip": "192.168.0.50",
          "wifi_rssi": -65,
          "uptime_sec": 86400
        }
      }
    },
    "chip_id": "ESP32-ABC123",
    "platform": "ESP32",
    "display": "None"
  }
]
```

### GET /api/messages
Returns recent MQTT messages.

**Response:**
```json
[
  {
    "topic": "esp-sensor-hub/Temp-Sensor/temperature",
    "device": "Temp-Sensor",
    "type": "temperature",
    "payload": {
      "current_temp_c": 23.5
    },
    "timestamp": "2024-01-15T10:30:45.123Z"
  },
  {
    "topic": "esp-sensor-hub/Temp-Sensor/status",
    "device": "Temp-Sensor",
    "type": "status",
    "payload": {
      "ip": "192.168.0.50",
      "wifi_rssi": -65
    },
    "timestamp": "2024-01-15T10:30:50.456Z"
  }
]
```

### GET /api/config
Returns current MQTT broker configuration.

**Response:**
```json
{
  "broker": "192.168.0.167",
  "port": 1883,
  "username": "mqtt_user",
  "password": ""
}
```

### POST /api/config
Tests MQTT connection and saves new configuration.

**Request:**
```json
{
  "broker": "192.168.0.167",
  "port": 1883,
  "username": "mqtt_user",
  "password": "mqtt_password"
}
```

**Response (Success):**
```json
{
  "success": true
}
```

**Response (Failure):**
```json
{
  "success": false,
  "error": "Could not connect to MQTT broker"
}
```

**Actions:**
- Tests connection to specified broker
- Validates port number (1-65535)
- Requires broker address
- Updates .env file if successful
- Reconnects MQTT client with new settings

## WebSocket Events (Socket.IO)

### Client Events Emitted

#### send_command
Send a command to a device.

**Emit:**
```javascript
socket.emit('send_command', {
  device: 'Temp-Sensor',
  command: 'restart'
});
```

**Available Commands:**
- `status` - Request device status
- `restart` - Restart the device
- `deepsleep <seconds>` - Enter deep sleep mode
- `interval <seconds>` - Change update interval

### Server Events Received

#### connect
Emitted when WebSocket connection established.

#### disconnect
Emitted when WebSocket connection lost.

#### mqtt_status
Emitted when MQTT broker connection status changes.

**Data:**
```javascript
{
  connected: true,
  broker: "192.168.0.167",
  port: 1883
}
```

#### mqtt_message
Emitted when new MQTT message received.

**Data:**
```javascript
{
  topic: "esp-sensor-hub/Temp-Sensor/temperature",
  device: "Temp-Sensor",
  type: "temperature",
  payload: { current_temp_c: 23.5 },
  timestamp: "2024-01-15T10:30:45.123Z"
}
```

#### device_update
Emitted when device state changes.

**Data:**
```javascript
{
  device: "Temp-Sensor",
  state: {
    last_seen: "2024-01-15T10:30:45.123Z",
    temperature: { ... },
    status: { ... },
    events: { ... }
  }
}
```

#### initial_state
Emitted on connection with all current device states and messages.

**Data:**
```javascript
{
  devices: {
    "Temp-Sensor": { ... },
    "Humidity-Sensor": { ... }
  },
  messages: [ ... ]
}
```

#### command_response
Emitted after command execution.

**Data:**
```javascript
{
  success: true,
  device: "Temp-Sensor",
  command: "restart"
}
```

## Error Codes

### HTTP Status Codes
- `200 OK` - Request successful
- `400 Bad Request` - Invalid parameters (e.g., missing broker address)
- `500 Internal Server Error` - MQTT client not connected

### MQTT Config Validation
- Broker address required
- Port must be 1-65535
- Connection test performed before saving
- Useful error messages for connection failures

## Usage Examples

### Get Current Configuration
```bash
curl http://localhost:5000/api/config
```

### Update MQTT Broker
```bash
curl -X POST http://localhost:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{
    "broker": "192.168.0.100",
    "port": 1883,
    "username": "user",
    "password": "pass"
  }'
```

### Get Devices
```bash
curl http://localhost:5000/api/devices
```

### Get Recent Messages
```bash
curl http://localhost:5000/api/messages
```

### Send Command (via WebSocket)
```javascript
const socket = io('http://localhost:5000');
socket.emit('send_command', {
  device: 'Temp-Sensor',
  command: 'status'
});
```

## Device Filtering

### By Name
Filter in Devices section search box:
- "temp" matches "Temperature Sensor"
- "spa" matches "Spa Monitor"

### By Status
Select in Status dropdown:
- Online (last seen < 5 minutes)
- Offline (last seen > 5 minutes)

### By Topic
Select in Topic dropdown:
- Shows available message types: temperature, status, events

### Messages By Type
Select in Message Type dropdown:
- temperature
- status
- events
- command

### Messages By Device
Select in Device dropdown:
- All devices or specific device

### Messages By Topic
Search box in Messages section:
- Partial topic matching

## Connection Flow

1. Browser connects to server
2. Socket.IO connection established
3. Server sends `initial_state` with all devices and recent messages
4. Subscribe to Socket.IO events for updates
5. All subsequent changes push real-time updates

## MQTT Topic Structure

```
esp-sensor-hub/{device}/{type}

Types:
  - temperature: Current temperature readings
  - status: Device status, IP, WiFi signal
  - events: Event notifications
  - command: Incoming commands from admin panel
```

## Performance Considerations

- Device list: ~100 device limit
- Message buffer: 100 most recent messages
- Update frequency: Real-time via Socket.IO
- Table refresh: On demand when switching sections
- Auto-scroll: Toggleable (default: on)
- Toast auto-dismiss: 4-7 seconds depending on type

## Security Notes

- Password field not returned in GET /api/config
- Credentials sent over HTTPS in production
- WebSocket connection uses same security as HTTP
- MQTT credentials stored in .env file (not committed to git)
- No token/authentication for admin panel (local use assumed)
