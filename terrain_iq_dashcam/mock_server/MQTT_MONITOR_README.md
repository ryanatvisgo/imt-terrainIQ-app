# MQTT Live Monitor

## Overview
Real-time MQTT communication monitoring with automatic log rotation.

## Features
- **Live tail**: Updates every 1 second
- **Auto-rotation**: Keeps only last 5 minutes (300 lines)
- **Compact format**: Single-line entries with timestamps
- **Color-coded**: Easy to read terminal output

## Usage

### 1. Start the MQTT Server
```bash
cd mock_server
node server_mqtt.js
```

### 2. Watch the MQTT Log
In a separate terminal:
```bash
cd mock_server
./watch_mqtt.sh
```

Or manually:
```bash
tail -f mqtt_log.txt
```

### 3. Run the Flutter App
The app will automatically connect and start publishing MQTT messages:
- Location updates (every 5s)
- Status updates (every 5s)
- Proximity alerts (when proximity changes)
- Health pulse (every 60s)
- Recording state changes (when recording starts/stops)

### 4. View the Dashboard
Open in your browser:
```
http://localhost:3000/dashboard
```

## Log Format

```
[2025-10-11T18:30:00.000Z] 📱 MQTT Client connected: ios_1234
[2025-10-11T18:30:01.000Z] 📍 ios_1234 | Lat: 34.052230, Lon: -118.243680 | Acc: 5.0m, Speed: 12.5m/s
[2025-10-11T18:30:01.100Z] 📊 ios_1234 | Rec: true, Moving: true | Orient: portrait
[2025-10-11T18:30:15.000Z] ⚠️  ios_1234 | NEAR | Distance: 450m | Hazard: severe washboard (sev: 8)
[2025-10-11T18:31:00.000Z] 💓 ios_1234 | Battery: 85% ⚡ | Storage: 5000MB
[2025-10-11T18:31:05.000Z] 🎥 ios_1234 | Recording started
```

## Log Symbols

- 📱 Client connection/disconnection
- 📍 Location update
- 📊 Status update
- ⚠️  Proximity alert
- 💓 Health pulse (heartbeat)
- 🎥 Recording state change
- ⚡ Battery charging indicator

## Files

- `server_mqtt.js` - MQTT server with logging
- `watch_mqtt.sh` - Live monitoring script
- `mqtt_log.txt` - Rotating log file (auto-managed)

## Tips

- Press `Ctrl+C` to exit the monitor
- Log file is automatically trimmed to 300 lines (5 minutes @ 1 msg/sec)
- Check log file directly: `cat mqtt_log.txt`
- Monitor specific device: `grep "ios_1234" mqtt_log.txt`
- Filter by message type: `grep "📍" mqtt_log.txt` (location only)
