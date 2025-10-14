# TerrainIQ Dashcam Services Management

## Quick Start

### Start All Services
```bash
./start_all.sh
```

This will:
1. Stop any existing services
2. Start MQTT broker on ws://localhost:3301
3. Start mock server on http://localhost:3000
4. Start Flutter app on http://localhost:3201
5. Run all services in background with logging

### Stop All Services
```bash
./stop_all.sh
```

### Start Services Individually

```bash
./start_mqtt.sh      # MQTT broker only
./start_server.sh    # Mock server only
./start_flutter.sh   # Flutter app only
```

## Service URLs

- **Simulator**: http://localhost:3000/app_simulator.html
- **Mock Server**: http://localhost:3000
- **Flutter App**: http://localhost:3201
- **MQTT Broker**: ws://localhost:3301

## Log Files

When using `./start_all.sh`, logs are saved to:
- `logs/mqtt.log` - MQTT broker logs
- `logs/server.log` - Mock server logs
- `logs/flutter.log` - Flutter app logs

View logs in real-time:
```bash
tail -f logs/mqtt.log
tail -f logs/server.log
tail -f logs/flutter.log
```

## Important Notes

### Multiple Flutter Instances
The Flutter app uses a **unique random client ID** for MQTT connections, allowing multiple instances to run simultaneously without conflicts.

Each instance gets an ID like: `flutter_dashcam_preview_XXXXXX` (where XXXXXX is a random 6-digit number)

This means:
- You can open the simulator in a browser (which embeds Flutter in an iframe)
- AND open Flutter in a separate browser tab
- Both will work without interfering with each other

### Previous MQTT Issue (FIXED)
**Problem**: When the simulator embedded Flutter in an iframe AND the user had Flutter open in a separate window, both instances used the same client ID (`flutter_dashcam_preview`), causing constant disconnections.

**Solution**: Each Flutter instance now generates a unique random client ID on startup.

**Fix committed**: `lib/services/mqtt_preview_service_js.dart`

## Manual Service Commands

If you prefer to run services in foreground for debugging:

```bash
# MQTT Broker
node mqtt_broker.js

# Mock Server
cd mock_server && node server.js

# Flutter App
flutter run -d chrome --web-port=3201
```

## Troubleshooting

### Port Already in Use
If you get "address already in use" errors:

```bash
# Kill specific service
pkill -f "node.*mqtt_broker.js"
pkill -f "node.*server.js"
pkill -f "flutter.*chrome.*3201"

# Or stop all at once
./stop_all.sh
```

### MQTT Connection Issues
Check MQTT broker logs:
```bash
tail -f logs/mqtt.log
```

Look for client connections with unique IDs like `flutter_dashcam_preview_091307`

### Flutter Not Loading
1. Check if Flutter is running: `ps aux | grep flutter`
2. Check if port 3201 is available: `lsof -i :3201`
3. Restart Flutter: `./start_flutter.sh`
