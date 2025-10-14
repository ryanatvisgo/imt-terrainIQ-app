# Simulator-to-Flutter MQTT Protocol

## Overview
This document defines the MQTT message protocol for controlling the TerrainIQ Flutter app from the web-based simulator.

## MQTT Broker
- **Production**: `mqtt://192.168.8.105:1883`
- **Development**: `mqtt://localhost:1883` or `ws://localhost:9001` (WebSocket)

## Topics

### Simulator → Flutter (Commands)

| Topic | Description | Payload Format |
|-------|-------------|----------------|
| `terrainiq/simulator/preview/enable` | Enable preview mode | `{"enabled": true}` |
| `terrainiq/simulator/preview/view` | Change view/page | `{"page": 1/2/3}` |
| `terrainiq/simulator/preview/hazard` | Update hazard info | See Hazard Payload |
| `terrainiq/simulator/preview/vehicle` | Update vehicle state | See Vehicle Payload |
| `terrainiq/simulator/preview/recording` | Control recording | `{"recording": true/false, "auto": true/false}` |
| `terrainiq/simulator/preview/orientation` | Change orientation | `{"orientation": "portrait"/"landscape"}` |

### Flutter → Simulator (Status)

| Topic | Description | Payload Format |
|-------|-------------|----------------|
| `terrainiq/flutter/preview/status` | App status updates | `{"ready": true, "mode": "preview"}` |
| `terrainiq/flutter/preview/error` | Error messages | `{"error": "message"}` |

## Message Payloads

### Hazard Payload
```json
{
  "distance": 450,
  "severity": 5,
  "type": "POTHOLE AHEAD",
  "nextHazardDistance": 345,
  "icon": "⚠️"
}
```

### Vehicle Payload
```json
{
  "speed": 65,
  "moving": true,
  "latitude": 0.0,
  "longitude": 0.0,
  "heading": 0.0
}
```

### Recording Payload
```json
{
  "recording": true,
  "autoRecord": true,
  "manualOverride": false
}
```

### Orientation Payload
```json
{
  "orientation": "portrait"
}
```

### View Payload
```json
{
  "page": 1
}
```
Where:
- `page`: 1 = Hazard HUD Only, 2 = HUD with Camera PIP, 3 = Camera Full Screen with Overlay

## Message Flow

1. **Simulator starts → Flutter**
   - Publishes `terrainiq/simulator/preview/enable` with `{"enabled": true}`

2. **Flutter receives → Simulator**
   - Enters preview mode
   - Publishes `terrainiq/flutter/preview/status` with `{"ready": true, "mode": "preview"}`

3. **User adjusts controls → Flutter**
   - Simulator publishes updates to respective topics
   - Flutter app listens and updates UI in real-time

4. **User toggles back to HTML**
   - Publishes `terrainiq/simulator/preview/enable` with `{"enabled": false}`
   - Flutter exits preview mode and resumes normal operation

## QoS Levels
- **Commands**: QoS 1 (at least once delivery)
- **Status**: QoS 0 (at most once, fire and forget)

## Retained Messages
- `terrainiq/simulator/preview/enable`: Retained (so Flutter knows state on connect)
- All other messages: Not retained

## Implementation Notes

### Simulator (Web)
- Use MQTT.js library for WebSocket connection
- Connect to broker on simulator load
- Publish messages when controls change
- Show connection status indicator

### Flutter App
- Use mqtt_client package
- Subscribe to all `terrainiq/simulator/preview/#` topics
- Only process messages when in preview mode
- Publish status on mode changes

## Security Considerations
- Preview mode should be clearly indicated in UI
- Preview mode disabled in production builds
- MQTT broker should require authentication in production
- Consider encrypting sensitive data in payloads
