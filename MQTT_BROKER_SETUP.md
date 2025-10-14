# MQTT Broker Setup for HTML Simulator + Flutter Web Integration

This guide explains how to set up an MQTT broker to enable communication between the HTML simulator and the Flutter Web app.

## Overview

The HTML simulator can control the live Flutter Web app through MQTT messages. This allows you to:
- Toggle between HTML mockup view and real Flutter UI
- Control the Flutter app in real-time from the simulator controls
- See the actual Flutter rendering and behavior

## Architecture

```
HTML Simulator (localhost:3001)
    ↓ MQTT Messages
MQTT Broker (localhost:9001 WebSocket)
    ↓ MQTT Messages
Flutter Web App (localhost:8080/#/preview)
```

## Prerequisites

- Node.js installed
- Mosquitto MQTT broker (or alternative)
- Flutter SDK installed

## Option 1: Mosquitto MQTT Broker (Recommended)

### Install Mosquitto

**macOS:**
```bash
brew install mosquitto
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install mosquitto mosquitto-clients
```

**Windows:**
Download from: https://mosquitto.org/download/

### Configure Mosquitto for WebSockets

1. Create or edit the Mosquitto config file:

**macOS:**
```bash
sudo nano /opt/homebrew/etc/mosquitto/mosquitto.conf
```

**Linux:**
```bash
sudo nano /etc/mosquitto/mosquitto.conf
```

2. Add the following configuration:

```conf
# Standard MQTT port
listener 1883
protocol mqtt

# WebSocket port for browser clients
listener 9001
protocol websockets

# Allow anonymous connections (for development)
allow_anonymous true

# Logging
log_dest stdout
log_type all
```

3. Restart Mosquitto:

**macOS:**
```bash
brew services restart mosquitto
```

**Linux:**
```bash
sudo systemctl restart mosquitto
```

4. Verify it's running:
```bash
# Check if WebSocket port is open
lsof -i :9001

# Check if MQTT port is open
lsof -i :1883
```

### Test the Connection

Open a terminal and subscribe to test messages:
```bash
mosquitto_sub -h localhost -t "test/#" -v
```

In another terminal, publish a test message:
```bash
mosquitto_pub -h localhost -t "test/hello" -m "Hello MQTT"
```

You should see the message in the first terminal.

## Option 2: Aedes MQTT Broker (Node.js)

If you prefer a Node.js-based broker:

1. Install Aedes:
```bash
npm install -g aedes
```

2. Create a simple broker script `mqtt_broker.js`:
```javascript
const aedes = require('aedes')();
const httpServer = require('http').createServer();
const ws = require('websocket-stream');
const net = require('net');
const port = 1883;
const wsPort = 9001;

// MQTT over TCP
const server = net.createServer(aedes.handle);
server.listen(port, function () {
  console.log('MQTT Broker listening on port', port);
});

// MQTT over WebSocket
ws.createServer({ server: httpServer }, aedes.handle);
httpServer.listen(wsPort, function () {
  console.log('MQTT WebSocket listening on port', wsPort);
});

// Log events
aedes.on('client', function (client) {
  console.log('Client connected:', client.id);
});

aedes.on('clientDisconnect', function (client) {
  console.log('Client disconnected:', client.id);
});

aedes.on('publish', function (packet, client) {
  if (client) {
    console.log('Message from', client.id, ':', packet.topic);
  }
});
```

3. Run the broker:
```bash
node mqtt_broker.js
```

## Running the Complete System

### Terminal 1: Start MQTT Broker

**Option 1 (Mosquitto):**
```bash
# macOS
brew services start mosquitto

# Linux
sudo systemctl start mosquitto
```

**Option 2 (Aedes):**
```bash
node mqtt_broker.js
```

### Terminal 2: Start Flutter Web App

```bash
cd terrain_iq_dashcam
flutter run -d chrome --web-port 8080
```

Or build and serve:
```bash
flutter build web
cd build/web
python3 -m http.server 8080
```

### Terminal 3: Start HTML Simulator

```bash
cd terrain_iq_dashcam
python3 -m http.server 3001
```

Then open: http://localhost:3001/app_simulator.html

## Using the Integration

1. Open the HTML simulator in your browser
2. Check the MQTT status indicator - it should show "MQTT: Connected" in green
3. Click the "Flutter App" button to switch from HTML mockup to real Flutter Web
4. The Flutter app will load in an iframe
5. Adjust the simulator controls (distance, severity, speed, etc.)
6. Watch the Flutter app update in real-time!

## MQTT Topics

The system uses these MQTT topics:

### HTML → Flutter (Control Messages)
- `terrainiq/simulator/preview/enable` - Enable/disable preview mode
- `terrainiq/simulator/preview/hazard` - Hazard data (distance, severity, type)
- `terrainiq/simulator/preview/vehicle` - Vehicle data (speed, movement, GPS)
- `terrainiq/simulator/preview/recording` - Recording state
- `terrainiq/simulator/preview/orientation` - Screen orientation

### Flutter → HTML (Status Messages)
- `terrainiq/simulator/flutter/status` - Flutter app ready status

## Troubleshooting

### MQTT Connection Failed

**Check if broker is running:**
```bash
# Check WebSocket port
lsof -i :9001

# Check MQTT port
lsof -i :1883
```

**Test WebSocket connection:**
Open browser console on the simulator page:
```javascript
const client = mqtt.connect('ws://localhost:9001');
client.on('connect', () => console.log('Connected!'));
client.on('error', (err) => console.error('Error:', err));
```

### Flutter App Not Loading

1. Verify Flutter Web is running:
   ```bash
   curl http://localhost:8080
   ```

2. Check browser console for errors

3. Ensure CORS is not blocking the iframe

### Controls Not Working

1. Check MQTT status in simulator (should be green "Connected")
2. Open browser console to see MQTT message logs
3. Verify Flutter app is in preview mode (check the screen)

## Security Notes

⚠️ **For Development Only**

The configuration above allows anonymous MQTT connections and is intended for local development only.

**For Production:**
- Enable MQTT authentication
- Use TLS/SSL encryption
- Restrict topic access
- Use proper firewall rules

## Alternative: Without MQTT

If you want to use Flutter Web without MQTT integration:

1. Run Flutter Web:
   ```bash
   flutter run -d chrome --web-port 8080
   ```

2. Navigate to preview mode directly:
   ```
   http://localhost:8080/#/preview
   ```

The preview screen will show "Waiting for MQTT" but you can still test the Flutter UI independently.
