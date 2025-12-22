# PostgreSQL Database Configuration for raspberrypi2
# Copy this to inventory_config.py and update with your actual credentials

DB_CONFIG = {
    'host': '192.168.0.146',  # raspberrypi2 IP address
    'port': 5432,
    'database': 'camera_db',  # Found from container environment
    'user': 'camera',  # Found from container environment
    'password': 'change_me'  # Found from container environment
}

# MQTT Configuration (for inventory_sync.py)
MQTT_CONFIG = {
    'broker': '192.168.0.167',  # Your MQTT broker IP (raspberrypi)
    'port': 1883,
    'topics': [
        'esp-sensor-hub/#',
        'surveillance/#',
        'solar-monitor/#'
    ]
}