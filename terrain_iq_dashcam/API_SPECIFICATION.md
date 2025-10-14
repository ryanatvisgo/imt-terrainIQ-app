# TerrainIQ Dashcam - API Specification

**Last Updated:** 2025-10-13
**Version:** 2.0
**Base URL:** `http://192.168.8.105:3000` (default local)

This document provides complete API specifications for the TerrainIQ Dashcam backend server including REST APIs, MQTT protocol, request/response schemas, and error handling.

---

## Table of Contents

1. [Server Configuration](#server-configuration)
2. [REST API Endpoints](#rest-api-endpoints)
3. [MQTT Protocol](#mqtt-protocol)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Authentication](#authentication)
7. [Rate Limiting](#rate-limiting)

---

## Server Configuration

### Base URLs

| Environment | URL | Description |
|-------------|-----|-------------|
| Local | `http://192.168.8.105:3000` | Development server on local network |
| Ngrok | `https://YOUR-NGROK-URL.ngrok-free.app` | Tunneled public URL (optional) |

### Configuration

File: `lib/config.dart`

```dart
class AppConfig {
  static const bool useNgrok = false;
  static const String localUrl = 'http://192.168.8.105:3000';
  static const String ngrokUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';
  static String get serverUrl => useNgrok ? ngrokUrl : localUrl;
}
```

### Server Ports

| Service | Port | Protocol |
|---------|------|----------|
| HTTP API | 3000 | HTTP/1.1 |
| MQTT Broker | 1883 | MQTT v3.1.1 |
| MQTT WebSocket | 9001 | WebSocket |

---

## REST API Endpoints

### 1. Heartbeat

**Endpoint:** `POST /heartbeat`
**Purpose:** Device heartbeat to indicate active connection
**Auth:** None
**Rate Limit:** 1 per minute

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "timestamp": "2025-10-13T10:30:00.000Z",
  "status": "active",
  "upload_queue_size": 3
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| timestamp | string (ISO 8601) | Yes | Device timestamp |
| status | string | Yes | Device status: "active", "idle", "recording" |
| upload_queue_size | integer | Yes | Number of pending uploads in queue |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "message": "Heartbeat received",
  "heartbeat_count": 42,
  "server_time": "2025-10-13T10:30:01.234Z"
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Invalid request body"
}
```

---

### 2. Video Upload (Chunked) - Register

**Endpoint:** `POST /upload/register`
**Purpose:** Register a new video upload session with metadata and CSV
**Auth:** None
**Rate Limit:** 10 per minute

#### Request

**Headers:**
```
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| metadata | file (JSON) | Yes | Video metadata (see [Metadata Schema](#metadata-schema)) |
| csv | file (CSV) | Yes | Sensor data CSV (see [CSV Schema](#csv-schema)) |

**Example metadata.json:**
```json
{
  "video": {
    "filename": "recording_1760223000000.mp4",
    "size_bytes": 52428800,
    "duration_seconds": 180,
    "format": "mp4"
  },
  "recording": {
    "start_time": "2025-10-13T10:00:00.000Z",
    "end_time": "2025-10-13T10:03:00.000Z"
  },
  "device": {
    "id": "iPhone15Pro-ABC123",
    "model": "iPhone 15 Pro",
    "os_version": "iOS 17.1"
  }
}
```

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "chunk_size": 5242880,
  "total_chunks": 10,
  "ready": true,
  "message": "Upload registered successfully"
}
```

| Field | Type | Description |
|-------|------|-------------|
| upload_id | string (UUID) | Unique upload session ID |
| chunk_size | integer | Chunk size in bytes (5MB) |
| total_chunks | integer | Total number of chunks expected |
| ready | boolean | Server ready to receive chunks |

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Missing required files (metadata.json and sensors.csv)"
}
```

---

### 3. Video Upload (Chunked) - Upload Chunk

**Endpoint:** `POST /upload/chunk/:upload_id`
**Purpose:** Upload a single video chunk
**Auth:** None
**Rate Limit:** None (throughput limited)

#### Request

**Headers:**
```
Content-Type: application/octet-stream
X-Chunk-Index: 0
X-Total-Chunks: 10
```

**Body:** Raw binary video chunk data

| Header | Type | Required | Description |
|--------|------|----------|-------------|
| X-Chunk-Index | integer | Yes | Zero-based chunk index |
| X-Total-Chunks | integer | Yes | Total chunks (must match registration) |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "received": true,
  "chunk_index": 0,
  "progress": 10.0,
  "chunks_received": 1,
  "total_chunks": 10,
  "next_chunk": 1
}
```

| Field | Type | Description |
|-------|------|-------------|
| chunk_index | integer | Index of chunk just received |
| progress | float | Upload progress percentage (0-100) |
| chunks_received | integer | Total chunks received so far |
| next_chunk | integer or null | Next expected chunk index, null if complete |

**Error (404 Not Found):**
```json
{
  "success": false,
  "error": "Upload not found"
}
```

---

### 4. Video Upload (Chunked) - Complete

**Endpoint:** `POST /upload/complete/:upload_id`
**Purpose:** Finalize upload and combine chunks
**Auth:** None
**Rate Limit:** None

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:** Empty or optional metadata

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "video_url": "http://localhost:3000/videos/recording_1760223000000.mp4",
  "csv_url": "http://localhost:3000/data/recording_1760223000000.csv",
  "metadata_url": "http://localhost:3000/data/recording_1760223000000.json",
  "completed_at": "2025-10-13T10:05:00.000Z"
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Incomplete upload: 8/10 chunks",
  "missing_chunks": [3, 7]
}
```

---

### 5. Upload Status

**Endpoint:** `GET /upload/status/:upload_id`
**Purpose:** Check upload progress
**Auth:** None
**Rate Limit:** 100 per minute

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "recording_1760223000000.mp4",
  "status": "uploading",
  "progress": 60.0,
  "chunks_received": 6,
  "total_chunks": 10,
  "size_bytes": 52428800,
  "registered_at": "2025-10-13T10:00:00.000Z",
  "last_chunk_at": "2025-10-13T10:04:30.000Z",
  "completed_at": null
}
```

| Field | Value | Description |
|-------|-------|-------------|
| status | "pending" | Registered, waiting for chunks |
| status | "uploading" | Chunks being received |
| status | "complete" | All chunks received and assembled |
| status | "failed" | Upload failed |

---

### 6. List Uploads

**Endpoint:** `GET /uploads`
**Purpose:** List all upload sessions
**Auth:** None
**Rate Limit:** 10 per minute

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "total": 15,
  "uploads": [
    {
      "upload_id": "550e8400-e29b-41d4-a716-446655440000",
      "filename": "recording_1760223000000.mp4",
      "status": "complete",
      "progress": 100.0,
      "size_mb": "50.00",
      "registered_at": "2025-10-13T10:00:00.000Z",
      "completed_at": "2025-10-13T10:05:00.000Z"
    }
  ]
}
```

---

### 7. Get Hazards

**Endpoint:** `POST /get_hazards`
**Purpose:** Fetch road hazards within a radius
**Auth:** None
**Rate Limit:** 20 per minute

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "lat": 49.820725,
  "lon": -119.492921,
  "radius_km": 200
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| lat | float | Yes | Latitude (-90 to 90) |
| lon | float | Yes | Longitude (-180 to 180) |
| radius_km | integer | Yes | Search radius in kilometers |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "hazards": [
    {
      "id": "mock-1",
      "lon": -119.492921,
      "lat": 49.820725,
      "zone_m": 100,
      "last_detected": "2025-10-11T10:30:00Z",
      "times_detected_6mos": 23,
      "severity": 8,
      "labels": ["severe washboard", "bumps", "rough terrain"],
      "driver_notes": [
        {
          "datetime": "2025-10-10T14:22:00Z",
          "notes": "Very rough section, slow down",
          "driver_name": "Driver A"
        }
      ]
    }
  ],
  "count": 12,
  "query_location": {
    "lat": 49.820725,
    "lon": -119.492921
  },
  "radius_km": 200,
  "fetch_time": "2025-10-13T10:30:00.000Z"
}
```

---

### 8. Add Hazard

**Endpoint:** `POST /add_hazard`
**Purpose:** Report a new road hazard
**Auth:** None (Future: User authentication required)
**Rate Limit:** 5 per minute

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "lat": 49.820725,
  "lon": -119.492921,
  "severity": 7,
  "labels": ["pothole", "bumps"],
  "zone_m": 50,
  "notes": "Large pothole on right side"
}
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| lat | float | Yes | - | Latitude |
| lon | float | Yes | - | Longitude |
| severity | integer | No | 5 | Severity (1-10) |
| labels | string[] | No | ["custom hazard"] | Hazard types |
| zone_m | integer | No | 50 | Danger zone radius (meters) |
| notes | string | No | "" | Driver notes |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "message": "Hazard added successfully",
  "hazard": {
    "id": "1728825600000-123456789",
    "lon": -119.492921,
    "lat": 49.820725,
    "zone_m": 50,
    "last_detected": "2025-10-13T10:30:00.000Z",
    "times_detected_6mos": 1,
    "severity": 7,
    "labels": ["pothole", "bumps"],
    "driver_notes": [
      {
        "datetime": "2025-10-13T10:30:00.000Z",
        "notes": "Large pothole on right side",
        "driver_name": "Admin"
      }
    ]
  }
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Latitude and longitude are required"
}
```

---

### 9. Remove Hazard

**Endpoint:** `DELETE /remove_hazard/:id`
**Purpose:** Remove a reported hazard
**Auth:** None (Future: Admin required)
**Rate Limit:** 10 per minute

#### Request

**URL Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Hazard unique identifier |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "message": "Hazard removed successfully"
}
```

**Error (404 Not Found):**
```json
{
  "success": false,
  "error": "Hazard not found"
}
```

---

### 10. Get All Hazards

**Endpoint:** `GET /all_hazards`
**Purpose:** Get all hazards without location filtering
**Auth:** None
**Rate Limit:** 10 per minute

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "hazards": [
    // Array of hazard objects (same schema as /get_hazards)
  ],
  "count": 127
}
```

---

### 11. Get Recordings

**Endpoint:** `GET /api/recordings`
**Purpose:** List all uploaded recordings with associated data
**Auth:** None
**Rate Limit:** 10 per minute

#### Response

**Success (200 OK):**
```json
[
  {
    "filename": "recording_1760223000000.mp4",
    "baseName": "recording_1760223000000",
    "videoUrl": "/videos/recording_1760223000000.mp4",
    "csvUrl": "/data/recording_1760223000000.csv",
    "metadataUrl": "/data/recording_1760223000000.json",
    "size": "50.23 MB",
    "duration": "3:00",
    "uploadedAt": "2025-10-13T10:05:00.000Z"
  }
]
```

---

### 12. Upload Device Logs

**Endpoint:** `POST /logs`
**Purpose:** Upload device log files (crash logs, error logs)
**Auth:** None
**Rate Limit:** 20 per minute

#### Request

**Headers:**
```
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| log | file | Yes | Log file (.log or .txt) |
| timestamp | string | No | Log timestamp |
| file_size | integer | No | File size in bytes |
| file_name | string | No | Original filename |

#### Response

**Success (200 OK):**
```json
{
  "success": true,
  "message": "Log file uploaded successfully",
  "file_name": "crash_log_2025-10-13.log",
  "file_size": 15840,
  "upload_time": "2025-10-13T10:30:00.000Z"
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "No log file provided"
}
```

---

## MQTT Protocol

### Broker Configuration

| Parameter | Value |
|-----------|-------|
| Host | 192.168.8.105 |
| Port | 1883 (TCP), 9001 (WebSocket) |
| Protocol | MQTT v3.1.1 |
| QoS | 1 (At least once) |
| Clean Session | true |
| Keep Alive | 60 seconds |

### Topic Structure

```
terrainiq/
  ├─ device/{device_id}/
  │   ├─ location         (publish)
  │   ├─ status           (publish)
  │   ├─ proximity        (publish)
  │   ├─ heartbeat        (publish)
  │   ├─ recording_state  (publish)
  │   └─ command          (subscribe)
  └─ devices/all          (publish)
```

### Client Connection

**Client ID Format:** `terrainiq_dashcam_{device_id}`
**Device ID Generation:** UUID v4 generated on first launch

**Connection Example (Dart):**
```dart
final client = MqttServerClient('192.168.8.105', 'terrainiq_dashcam_${deviceId}');
client.port = 1883;
client.keepAlivePeriod = 60;
client.onConnected = onConnected;
client.onDisconnected = onDisconnected;

await client.connect();
```

---

### Published Topics

#### 1. Location Updates

**Topic:** `terrainiq/device/{device_id}/location`
**QoS:** 1
**Frequency:** Every 5 seconds

**Payload:**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:30:00.000Z",
  "latitude": 49.820725,
  "longitude": -119.492921,
  "altitude": 350.5,
  "speed": 15.6,
  "heading": 245.3,
  "accuracy": 5.0
}
```

---

#### 2. Status Updates

**Topic:** `terrainiq/device/{device_id}/status`
**QoS:** 1
**Frequency:** Every 5 seconds

**Payload:**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:30:00.000Z",
  "is_recording": true,
  "is_moving": true,
  "orientation": "portrait",
  "road_roughness": "moderate",
  "upload_queue_size": 2,
  "battery_level": 85.5
}
```

---

#### 3. Proximity Alerts

**Topic:** `terrainiq/device/{device_id}/proximity`
**QoS:** 1
**Frequency:** On change

**Payload:**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:30:00.000Z",
  "proximity_level": "warning",
  "hazard_id": "mock-1",
  "distance_meters": 150,
  "severity": 8,
  "labels": ["severe washboard", "bumps"]
}
```

**Proximity Levels:**
- `safe` - No hazards nearby
- `approaching` - Within proximity threshold (default 500m)
- `warning` - Close to hazard zone
- `insideZone` - Within danger zone

---

#### 4. Heartbeat

**Topic:** `terrainiq/device/{device_id}/heartbeat`
**QoS:** 1
**Frequency:** Every 60 seconds

**Payload:**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:30:00.000Z",
  "status": "active",
  "uptime_seconds": 3600
}
```

---

#### 5. Recording State Changes

**Topic:** `terrainiq/device/{device_id}/recording_state`
**QoS:** 1
**Frequency:** On change

**Payload (Started):**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:30:00.000Z",
  "state": "started",
  "filename": "recording_1760223000000.mp4",
  "auto_record": true
}
```

**Payload (Stopped):**
```json
{
  "device_id": "iPhone15Pro-ABC123",
  "timestamp": "2025-10-13T10:33:00.000Z",
  "state": "stopped",
  "filename": "recording_1760223000000.mp4",
  "duration_seconds": 180,
  "file_size_bytes": 52428800
}
```

---

### Subscribed Topics

#### 1. Commands

**Topic:** `terrainiq/device/{device_id}/command`
**QoS:** 1

**Payload (Enable High-Frequency Mode):**
```json
{
  "action": "enable_high_frequency",
  "enabled": true
}
```

**Supported Commands:**
| Action | Description | Parameters |
|--------|-------------|------------|
| enable_high_frequency | Toggle high-freq hazard mode (5s, 50km) | enabled: boolean |
| update_threshold | Change proximity threshold | threshold_m: integer (100-500) |
| force_fetch | Force immediate hazard fetch | - |

---

## Data Models

### Metadata Schema

**File:** `recording_{timestamp}.json`

```json
{
  "version": "1.0",
  "video": {
    "filename": "recording_1760223000000.mp4",
    "size_bytes": 52428800,
    "duration_seconds": 180,
    "format": "mp4",
    "resolution": "1920x1080",
    "fps": 30,
    "codec": "H.264"
  },
  "recording": {
    "start_time": "2025-10-13T10:00:00.000Z",
    "end_time": "2025-10-13T10:03:00.000Z",
    "auto_record": true,
    "trigger": "motion_detected"
  },
  "device": {
    "id": "iPhone15Pro-ABC123",
    "model": "iPhone 15 Pro",
    "os_version": "iOS 17.1",
    "app_version": "1.0.0+1"
  },
  "location": {
    "start": {
      "latitude": 49.820725,
      "longitude": -119.492921,
      "altitude": 350.5
    },
    "end": {
      "latitude": 49.821020,
      "longitude": -119.494069,
      "altitude": 352.8
    }
  },
  "statistics": {
    "distance_km": 0.15,
    "avg_speed_kmh": 3.0,
    "max_roughness": "moderate",
    "hazards_encountered": 1
  }
}
```

---

### CSV Schema

**File:** `recording_{timestamp}.csv`
**Format:** 16 columns, header row
**Sampling Rate:** 10Hz (every 100ms)

**Columns:**
```
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
```

**Example:**
```csv
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-13T10:00:00.000Z,0.05,-0.02,9.81,0.01,-0.01,0.00,1.2,smooth,portrait,true,49.820725,-119.492921,350.5,4.2,5.0
2025-10-13T10:00:00.100Z,0.08,-0.03,9.79,0.02,-0.01,0.01,1.5,smooth,portrait,true,49.820726,-119.492922,350.6,4.3,5.0
```

| Column | Type | Unit | Description |
|--------|------|------|-------------|
| timestamp | ISO 8601 | - | Sample timestamp |
| accel_x | float | m/s² | X-axis acceleration |
| accel_y | float | m/s² | Y-axis acceleration |
| accel_z | float | m/s² | Z-axis acceleration |
| gyro_x | float | rad/s | X-axis rotation |
| gyro_y | float | rad/s | Y-axis rotation |
| gyro_z | float | rad/s | Z-axis rotation |
| roughness | float | - | Road roughness score |
| roughness_level | string | - | smooth/moderate/rough/very_rough |
| orientation | string | - | portrait/landscape/flat |
| is_moving | boolean | - | Movement detected |
| latitude | float | degrees | GPS latitude |
| longitude | float | degrees | GPS longitude |
| altitude | float | meters | GPS altitude |
| speed_mps | float | m/s | GPS speed |
| accuracy | float | meters | GPS accuracy |

---

### Hazard Schema

```json
{
  "id": "1728825600000-123456789",
  "lon": -119.492921,
  "lat": 49.820725,
  "zone_m": 100,
  "last_detected": "2025-10-11T10:30:00Z",
  "times_detected_6mos": 23,
  "severity": 8,
  "labels": ["severe washboard", "bumps", "rough terrain"],
  "driver_notes": [
    {
      "datetime": "2025-10-10T14:22:00Z",
      "notes": "Very rough section, slow down",
      "driver_name": "Driver A"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique hazard identifier |
| lon | float | Longitude (-180 to 180) |
| lat | float | Latitude (-90 to 90) |
| zone_m | integer | Danger zone radius in meters |
| last_detected | ISO 8601 | Last detection timestamp |
| times_detected_6mos | integer | Detection count (last 6 months) |
| severity | integer | Severity level (1-10, 10=worst) |
| labels | string[] | Hazard type labels |
| driver_notes | DriverNote[] | Driver-submitted notes |

**DriverNote:**
```json
{
  "datetime": "2025-10-10T14:22:00Z",
  "notes": "Very rough section, slow down",
  "driver_name": "Driver A"
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful request |
| 400 | Bad Request | Invalid parameters or missing fields |
| 404 | Not Found | Resource not found (upload_id, hazard_id) |
| 500 | Internal Server Error | Server-side error |

### Error Response Format

All errors return this structure:

```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

### Common Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "No video file provided" | Missing video in upload | Include video file in multipart request |
| "Missing required files" | Missing metadata or CSV | Include both files in /upload/register |
| "Upload not found" | Invalid upload_id | Verify upload_id from registration response |
| "Incomplete upload: X/Y chunks" | Not all chunks received | Check missing_chunks array and resend |
| "Latitude and longitude are required" | Missing coordinates | Include lat/lon in request body |
| "Hazard not found" | Invalid hazard_id | Verify hazard exists with /all_hazards |

---

## Authentication

### Current Implementation

**Status:** No authentication (development only)

All endpoints are currently open without authentication. This is suitable only for local development and testing.

### Future Implementation

**Planned:** JWT-based authentication

**Flow:**
1. User logs in → Receive JWT token
2. Include token in Authorization header:
   ```
   Authorization: Bearer {jwt_token}
   ```
3. Server validates token for protected endpoints

**Protected Endpoints (Future):**
- `POST /add_hazard` - Authenticated users only
- `DELETE /remove_hazard/:id` - Admin only
- `POST /upload/*` - Authenticated devices only

---

## Rate Limiting

### Current Implementation

**Status:** No rate limiting (development only)

### Future Implementation

**Strategy:** Token bucket per device/user

| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /heartbeat | 1 | 1 minute |
| POST /upload/register | 10 | 1 minute |
| POST /get_hazards | 20 | 1 minute |
| POST /add_hazard | 5 | 1 minute |
| GET /uploads | 10 | 1 minute |
| GET /upload/status | 100 | 1 minute |

**Rate Limit Response (429 Too Many Requests):**
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "retry_after": 45
}
```

---

## Web Interfaces

### Available UIs

| Path | Purpose |
|------|---------|
| `/` | Server home page with endpoint list |
| `/viewer.html` | Video & CSV data viewer |
| `/files` | File browser with expandable details |
| `/hazard-map` | Interactive hazard map (OpenStreetMap) |
| `/app_simulator.html` | Interactive app simulator |
| `/status` | Server status JSON |

---

## Client Implementation Notes

### Flutter HTTP Client

**Service:** `ServerService` (`lib/services/server_service.dart`)

**Key Methods:**
- `sendHeartbeat()` - Send heartbeat every 60s
- `registerUpload()` - Register video upload
- `uploadChunk()` - Upload single chunk
- `completeUpload()` - Finalize upload
- `uploadPendingLogs()` - Upload crash/error logs

**Error Handling:**
```dart
try {
  final response = await http.post(url, body: jsonEncode(body));
  if (response.statusCode == 200) {
    // Success
  } else {
    // Handle error
  }
} on TimeoutException {
  // Handle timeout
} catch (e) {
  // Handle network error
}
```

---

## Testing

### Manual Testing Tools

**cURL Examples:**

**Heartbeat:**
```bash
curl -X POST http://192.168.8.105:3000/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2025-10-13T10:30:00Z","status":"active","upload_queue_size":0}'
```

**Get Hazards:**
```bash
curl -X POST http://192.168.8.105:3000/get_hazards \
  -H "Content-Type: application/json" \
  -d '{"lat":49.820725,"lon":-119.492921,"radius_km":200}'
```

**Add Hazard:**
```bash
curl -X POST http://192.168.8.105:3000/add_hazard \
  -H "Content-Type: application/json" \
  -d '{"lat":49.820725,"lon":-119.492921,"severity":7,"labels":["pothole"]}'
```

### Automated Testing

**Test Suite:** `mock_server/test_server.js`

Run tests:
```bash
cd mock_server
npm test
```

---

## Changelog

### Version 2.0 (2025-10-13)
- Added chunked video upload with resume support
- Added metadata and CSV file association
- Added upload progress tracking
- Added /upload/register, /upload/chunk, /upload/complete endpoints
- Added /api/recordings endpoint

### Version 1.0 (2025-10-11)
- Initial API implementation
- Heartbeat endpoint
- Simple video upload
- Hazard management endpoints
- MQTT integration

---

*This document should be updated whenever API endpoints or data schemas change.*
