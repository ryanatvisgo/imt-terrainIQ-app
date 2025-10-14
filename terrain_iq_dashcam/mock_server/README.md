# TerrainIQ Dashcam Mock Server

A simple Node.js Express server for testing the TerrainIQ Dashcam app's server communication features.

## Features

- **Heartbeat Endpoint**: Receives periodic heartbeat signals from the app
- **Video Upload Endpoint**: Accepts video file uploads via multipart/form-data
- **Status Endpoint**: View server statistics and uploaded files
- **Video Serving**: Serves uploaded videos via HTTP

## Installation

1. Install Node.js (if not already installed):
   - Download from https://nodejs.org/
   - Or use Homebrew on macOS: `brew install node`

2. Install dependencies:
   ```bash
   cd mock_server
   npm install
   ```

## Usage

Start the server:
```bash
npm start
```

Or directly with Node:
```bash
node server.js
```

The server will start on http://localhost:3000

## Endpoints

### POST /heartbeat

Receives heartbeat signals from the dashcam app.

**Request Body:**
```json
{
  "timestamp": "2025-10-10T12:00:00.000Z",
  "status": "recording",
  "upload_queue_size": 2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Heartbeat received",
  "heartbeat_count": 1,
  "server_time": "2025-10-10T12:00:00.123Z"
}
```

### POST /upload

Receives video file uploads.

**Request:**
- Content-Type: multipart/form-data
- Field name: `video`
- Additional fields: `timestamp`, `file_size`

**Response:**
```json
{
  "success": true,
  "message": "Video uploaded successfully",
  "video_url": "http://localhost:3000/videos/video-1728561234567-123456789.mp4",
  "file_size": 12345678,
  "upload_time": "2025-10-10T12:00:00.123Z"
}
```

### GET /status

View server status and statistics.

**Response:**
```json
{
  "status": "running",
  "uptime": 123.456,
  "heartbeat_count": 10,
  "uploaded_videos": 3,
  "total_storage_mb": "45.67",
  "files": ["video-1.mp4", "video-2.mp4", "video-3.mp4"]
}
```

### GET /videos/:filename

Access uploaded video files directly.

Example: http://localhost:3000/videos/video-1728561234567-123456789.mp4

## Testing with cURL

Test heartbeat:
```bash
curl -X POST http://localhost:3000/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2025-10-10T12:00:00Z","status":"idle","upload_queue_size":0}'
```

Test file upload:
```bash
curl -X POST http://localhost:3000/upload \
  -F "video=@/path/to/test_video.mp4" \
  -F "timestamp=2025-10-10T12:00:00Z" \
  -F "file_size=12345678"
```

Check status:
```bash
curl http://localhost:3000/status
```

## Configuration

To change the server port, edit `server.js`:
```javascript
const PORT = 3000; // Change to your desired port
```

## Uploaded Files

Uploaded videos are stored in the `uploads/` directory within the mock_server folder.

To clear uploads:
```bash
rm -rf uploads/*
```

## Logs

The server logs all requests to the console:
- Heartbeat signals show timestamp, status, and queue size
- Upload requests show file name, size, and upload time

## Development Notes

- Maximum file upload size: 500MB (configurable in server.js)
- Files are stored with unique names to prevent conflicts
- Server includes CORS headers for cross-origin requests (if needed)

## Troubleshooting

**Port already in use:**
```
Error: listen EADDRINUSE: address already in use :::3000
```
Solution: Change the PORT in server.js or kill the process using port 3000:
```bash
lsof -ti:3000 | xargs kill
```

**Module not found:**
```
Error: Cannot find module 'express'
```
Solution: Run `npm install` in the mock_server directory.

## iOS Network Security

For iOS devices to connect to localhost, you may need to update `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

This allows HTTP connections to localhost during development.
