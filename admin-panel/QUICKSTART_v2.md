# Admin Panel v2 - Modern Redesign Quick Start

## What's New?

✨ **Modern Dark Theme** - Ubuntu-inspired design with dark background and cyan accents
📱 **Responsive Layout** - Sidebar navigation that adapts to mobile/tablet
⚡ **Faster Data View** - Table-based device view instead of scrolling cards
🔧 **Runtime Config** - Change MQTT broker without restarting container
🔔 **Toast Notifications** - Real-time feedback for all user actions
📊 **Better Dashboard** - Stats and recent activity at a glance

## Key Features

### 1. Dashboard Section
- **Active Devices** - Count of currently connected devices
- **Total Devices** - All devices in inventory
- **Message Rate** - Messages per minute
- **Recent Activity** - Last 5 MQTT messages with timestamps

### 2. Devices Section
- **Compact Table View** - Name, Status, Temperature, IP, Signal, Topics
- **Online/Offline Status** - Automatic detection (5-minute threshold)
- **Real-time Updates** - See device state changes immediately
- **Quick Actions** - Status, Restart, Sleep buttons
- **Multiple Filters**:
  - Search by name
  - Filter by online/offline status
  - Filter by MQTT topic type

### 3. Messages Section (MQTT Log)
- **Real-time Updates** - See messages as they arrive
- **Color-Coded Types**:
  - 🔴 Temperature readings (orange)
  - 🔵 Status updates (blue)
  - 🟢 Events (green)
  - 🟡 Commands (yellow)
- **Three-Way Filtering**:
  - By message type (temperature/status/events/command)
  - By device name
  - By topic (text search)
- **Auto-Scroll** - Toggle to keep latest messages visible
- **Clear History** - Remove all messages with one click

### 4. Settings Section
- **MQTT Broker Configuration**:
  - Broker address (hostname or IP)
  - Port number (1-65535)
  - Optional username
  - Optional password
- **Test Connection** - Validates broker before saving
- **Automatic Save** - Updates .env file and reconnects
- **Real-time Status** - Shows connection health

## Navigation

The **left sidebar** is your main navigation:

```
🏠 Dashboard       - Overview and stats
🖥️  Devices         - Connected device list
💬 Messages        - MQTT message log
⚙️  Settings        - MQTT broker config
```

Click any item to switch to that section. Sidebar collapses on small screens for more space.

## Common Tasks

### Send a Command to Device
1. Go to **Devices** section
2. Find your device in the table
3. Click one of:
   - **Status** - Request device status
   - **Restart** - Reboot the device
   - **Sleep** - Configure deep sleep mode

### Configure Sleep Mode
1. Click **Sleep** button next to device
2. Enter sleep duration in seconds (e.g., 30)
3. Click **Set** to send command
4. Toast notification confirms command sent

### Check MQTT Messages
1. Go to **Messages** section
2. Messages appear in real-time with timestamps
3. Use filters to find specific messages:
   - Select message type (temperature, status, etc.)
   - Select device name
   - Search for topic
4. Toggle **Auto-Scroll** to keep up with new messages

### Change MQTT Broker
1. Go to **Settings** section
2. Enter new broker address and port
3. Add username/password if required
4. Click **Test & Save Connection**
5. Wait for toast notification (success or error)
6. If successful, .env is updated and MQTT reconnects
7. **No container restart needed!**

## Toast Notifications

Watch for feedback messages:

```
✓ Success (green)     - Operation completed
✗ Error (red)        - Something went wrong
⚠ Warning (orange)   - Important notice
ℹ Info (blue)        - General information
```

Messages auto-dismiss after 4-7 seconds (longer for errors).

## Desktop vs Mobile

**Desktop (1200px+):**
- Sidebar always visible with full text labels
- Side-by-side device table
- Full width message log

**Tablet (768-1200px):**
- Sidebar collapses to icons
- Table may scroll horizontally
- Stacked message log

**Mobile (<768px):**
- Sidebar collapses completely
- Full-width content areas
- Touch-friendly buttons
- Swipe navigation (planned)

## Real-Time Features

### Automatic Updates
- Devices: Update when MQTT publishes new state
- Messages: Appear in real-time as devices publish
- Connection: Shows MQTT status in header

### Dashboard Stats
- Refresh when devices connect/disconnect
- Message rate calculates per minute
- Recent activity updates with each message

## Default Credentials (if configured)

Check `.env` file for:
```
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=
```

**Can be changed via Settings panel without restart!**

## Keyboard Shortcuts (planned)

Coming in next version:
- `D` - Go to Dashboard
- `V` - Go to Devices
- `M` - Go to Messages
- `S` - Go to Settings
- `?` - Show this help

## Troubleshooting

### Devices Not Showing
- Check MQTT_BROKER setting in Settings
- Verify broker is running and accessible
- Look for red "Disconnected" status in header
- Check device last_seen timestamp (should be recent)

### Messages Not Appearing
- Verify devices are publishing MQTT messages
- Check message filter dropdowns (not set to "All")
- Toggle "Auto-Scroll" to force refresh
- Check MQTT connection status

### Can't Connect to Broker
- Verify broker address is correct
- Check port number (usually 1883)
- Try connection from Settings panel
- Check firewall allows MQTT port
- Look at Flask logs for detailed error

### Page Not Responsive
- Hard refresh browser (Ctrl+F5 or Cmd+Shift+R)
- Check browser console (F12) for errors
- Verify Flask app is running
- Check localhost:5000 is accessible

## File Structure

```
admin-panel/
├── templates/
│   └── index.html          - Main UI (220 lines)
├── static/
│   ├── style.css           - Styling (938 lines)
│   └── app.js              - JavaScript logic (803 lines)
├── app.py                  - Flask backend (342 lines)
├── config.py               - Configuration
├── mqtt_client.py          - MQTT handling
├── requirements.txt        - Python dependencies
├── Dockerfile              - Container definition
├── docker-compose.yml      - Container orchestration
└── .env                    - Environment variables
```

## Performance

- **Load Time**: < 2 seconds (after MQTT connection)
- **Message Updates**: < 100ms latency
- **Device Switching**: Instant
- **Device List**: Handles 100+ devices
- **Message Buffer**: 100 most recent messages

## Browser Support

Works on:
- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

Requires:
- JavaScript enabled
- WebSocket support
- CSS Grid & Flexbox
- ES6 compatibility

## Getting Help

1. Check **REDESIGN_COMPLETE.md** for full feature list
2. See **API_REFERENCE.md** for technical details
3. Review Flask logs: `docker logs admin-panel`
4. Check browser console: F12 → Console tab

## Next Steps

After deploying:
1. ✅ Open http://localhost:5000
2. ✅ Check devices appear in Devices section
3. ✅ Monitor messages in Messages section
4. ✅ Test a command (Status, Restart, Sleep)
5. ✅ Try changing MQTT broker in Settings
6. ✅ Verify .env was updated: `cat admin-panel/.env`

## Feedback

Features you'd like to see?
- Custom MQTT command buttons
- Message export/download
- Device groups
- Health metrics graphs
- Dark/Light theme toggle

Let me know! 🚀
