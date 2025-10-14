/**
 * TerrainIQ Mock Server with MQTT Broker
 *
 * Features:
 * - HTTP endpoints (heartbeat, upload, hazards)
 * - MQTT broker for real-time communication
 * - WebSocket MQTT for browser dashboard
 * - Real-time map dashboard
 */

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const aedes = require('aedes')();
const { createServer } = require('net');
const ws = require('ws');
const http = require('http');

const app = express();
const HTTP_PORT = 3000;
const MQTT_PORT = 1883;
const MQTT_WS_PORT = 8883;

// MQTT Log File Setup
const MQTT_LOG_FILE = path.join(__dirname, 'mqtt_log.txt');
const MAX_LOG_LINES = 300; // 5 minutes at ~1 update/second
let logBuffer = [];

function writeToLog(message) {
  const timestamp = new Date().toISOString();
  const logLine = `[${timestamp}] ${message}`;

  // Add to buffer
  logBuffer.push(logLine);

  // Keep only last MAX_LOG_LINES
  if (logBuffer.length > MAX_LOG_LINES) {
    logBuffer = logBuffer.slice(-MAX_LOG_LINES);
  }

  // Write entire buffer to file (overwrites old content)
  fs.writeFileSync(MQTT_LOG_FILE, logBuffer.join('\n') + '\n');

  // Also log to console
  console.log(logLine);
}

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadDir;
    if (file.fieldname === 'video') {
      uploadDir = path.join(__dirname, 'uploads');
    } else if (file.fieldname === 'csv' || file.fieldname === 'data') {
      uploadDir = path.join(__dirname, 'data');
    } else if (file.fieldname === 'metadata') {
      uploadDir = path.join(__dirname, 'metadata');
    } else {
      uploadDir = path.join(__dirname, 'uploads');
    }
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 500 * 1024 * 1024 }
});

// In-memory device state for dashboard
const deviceStates = new Map();

// MQTT Broker Setup
const mqttServer = createServer(aedes.handle);

// WebSocket MQTT for browser clients
const httpServer = http.createServer();
const wsServer = new ws.Server({ server: httpServer });
wsServer.on('connection', (socket) => {
  const stream = ws.createWebSocketStream(socket);
  aedes.handle(stream);
});

// MQTT Event Handlers
aedes.on('client', (client) => {
  writeToLog(`📱 MQTT Client connected: ${client.id}`);
});

aedes.on('clientDisconnect', (client) => {
  writeToLog(`📴 MQTT Client disconnected: ${client.id}`);
});

aedes.on('publish', (packet, client) => {
  if (client) {
    const topic = packet.topic;
    const payload = packet.payload.toString();

    // Skip system topics
    if (topic.startsWith('$SYS')) return;

    try {
      const data = JSON.parse(payload);

      // Update device state for dashboard
      const deviceId = topic.split('/')[2];
      if (!deviceStates.has(deviceId)) {
        deviceStates.set(deviceId, {});
      }
      const deviceState = deviceStates.get(deviceId);

      if (topic.includes('/location')) {
        writeToLog(`📍 ${deviceId} | Lat: ${data.lat?.toFixed(6)}, Lon: ${data.lon?.toFixed(6)} | Acc: ${data.accuracy}m, Speed: ${data.speed?.toFixed(1)}m/s`);
        deviceState.location = data;
        deviceState.lastUpdate = Date.now();
      } else if (topic.includes('/status')) {
        writeToLog(`📊 ${deviceId} | Rec: ${data.is_recording}, Moving: ${data.is_moving} | Orient: ${data.orientation}`);
        deviceState.status = data;
      } else if (topic.includes('/proximity')) {
        writeToLog(`⚠️  ${deviceId} | ${data.proximity_level} | Distance: ${data.distance_to_hazard}m | Hazard: ${data.hazard_label} (sev: ${data.hazard_severity})`);
        deviceState.proximity = data;
      } else if (topic.includes('/heartbeat')) {
        writeToLog(`💓 ${deviceId} | Battery: ${data.battery_level}% ${data.is_charging ? '⚡' : ''} | Storage: ${data.available_storage_mb}MB`);
        deviceState.heartbeat = data;
      } else if (topic.includes('/recording')) {
        writeToLog(`🎥 ${deviceId} | Recording ${data.state}`);
        deviceState.recording = data;
      }
    } catch (e) {
      // Not JSON or parsing error - skip
    }
  }
});

// HTTP Endpoints
let heartbeatCount = 0;

app.post('/heartbeat', (req, res) => {
  heartbeatCount++;
  const { timestamp, status, upload_queue_size } = req.body;
  console.log(`\n💓 HTTP Heartbeat #${heartbeatCount} received:`);
  console.log(`   Timestamp: ${timestamp}`);
  console.log(`   Status: ${status}`);
  console.log(`   Upload Queue Size: ${upload_queue_size}`);
  res.status(200).json({
    success: true,
    message: 'Heartbeat received',
    heartbeat_count: heartbeatCount,
    server_time: new Date().toISOString()
  });
});

app.post('/upload', upload.fields([
  { name: 'video', maxCount: 1 },
  { name: 'csv', maxCount: 1 },
  { name: 'data', maxCount: 1 },
  { name: 'metadata', maxCount: 1 }
]), (req, res) => {
  if (!req.files || !req.files.video) {
    console.log('❌ Upload failed: No video file provided');
    return res.status(400).json({
      success: false,
      error: 'No video file provided'
    });
  }

  const { timestamp, file_size } = req.body;
  const videoFile = req.files.video[0];
  const csvFile = req.files.csv ? req.files.csv[0] : req.files.data ? req.files.data[0] : null;
  const metadataFile = req.files.metadata ? req.files.metadata[0] : null;

  console.log(`\n📤 Upload received:`);
  console.log(`   Video: ${videoFile.originalname} (${(videoFile.size / 1024 / 1024).toFixed(2)} MB)`);
  if (csvFile) console.log(`   CSV Data: ${csvFile.originalname} (${(csvFile.size / 1024).toFixed(2)} KB)`);
  if (metadataFile) console.log(`   Metadata: ${metadataFile.originalname}`);

  const videoUrl = `http://localhost:${HTTP_PORT}/videos/${videoFile.filename}`;

  // Store association
  const baseId = Date.now() + '-' + Math.round(Math.random() * 1E9);
  const associationFile = path.join(__dirname, 'data', `${baseId}-association.json`);
  const association = {
    video: videoFile.filename,
    csv: csvFile ? csvFile.filename : null,
    metadata: metadataFile ? metadataFile.filename : null,
    timestamp: timestamp,
    upload_time: new Date().toISOString()
  };
  fs.writeFileSync(associationFile, JSON.stringify(association, null, 2));

  res.status(200).json({
    success: true,
    message: 'Files uploaded successfully',
    video_url: videoUrl,
    file_size: videoFile.size,
    has_csv: !!csvFile,
    has_metadata: !!metadataFile,
    upload_time: new Date().toISOString()
  });
});

app.use('/videos', express.static(path.join(__dirname, 'uploads')));

app.post('/get_hazards', (req, res) => {
  const { lat, lon, radius_km } = req.body;

  console.log(`\n⚠️ Hazards requested:`);
  console.log(`   Location: ${lat}, ${lon}`);
  console.log(`   Radius: ${radius_km}km`);

  const mockHazards = [
    {
      lon: lon,
      lat: lat,
      zone_m: 100,
      last_detected: '2025-10-11T10:30:00Z',
      times_detected_6mos: 23,
      severity: 8,
      labels: ['severe washboard', 'bumps', 'rough terrain'],
      driver_notes: [
        {
          datetime: '2025-10-10T14:22:00Z',
          notes: 'Very rough section, slow down',
          driver_name: 'Driver A'
        }
      ]
    },
    {
      lon: lon,
      lat: lat + 0.0018,
      zone_m: 50,
      last_detected: '2025-10-11T09:00:00Z',
      times_detected_6mos: 15,
      severity: 9,
      labels: ['potholes', 'bumps', 'high risk area'],
      driver_notes: []
    },
    {
      lon: lon - 0.008,
      lat: lat + 0.002,
      zone_m: 30,
      last_detected: '2025-10-10T16:45:00Z',
      times_detected_6mos: 15,
      severity: 7,
      labels: ['potholes', 'bumps'],
      driver_notes: []
    }
  ];

  console.log(`   → Returning ${mockHazards.length} hazards`);

  res.status(200).json({
    success: true,
    hazards: mockHazards,
    count: mockHazards.length,
    query_location: { lat, lon },
    radius_km: radius_km,
    fetch_time: new Date().toISOString()
  });
});

// Dashboard endpoint
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// API endpoint for device states
app.get('/api/devices', (req, res) => {
  const devices = Array.from(deviceStates.entries()).map(([id, state]) => ({
    id,
    ...state
  }));
  res.json({ devices });
});

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>TerrainIQ Server with MQTT</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
          h1 { color: #1E88E5; }
          .btn {
            display: inline-block;
            padding: 12px 24px;
            background: #1E88E5;
            color: white;
            border-radius: 4px;
            text-decoration: none;
            margin: 10px 10px 10px 0;
            font-weight: bold;
          }
          .btn:hover { background: #1976D2; }
          .btn.primary { background: #4CAF50; font-size: 18px; }
          .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
          .method { font-weight: bold; color: #4CAF50; }
        </style>
      </head>
      <body>
        <h1>🚗 TerrainIQ Server with MQTT</h1>
        <p>Server is running with real-time MQTT communication.</p>

        <a href="/dashboard" class="btn primary">🗺️ Open Live Map Dashboard</a>
        <a href="/files" class="btn">📁 Browse Files</a>
        <a href="/status" class="btn">📊 View Status</a>

        <h2>MQTT Endpoints:</h2>
        <div class="endpoint">
          <strong>TCP MQTT:</strong> mqtt://localhost:${MQTT_PORT}<br>
          <strong>WebSocket MQTT:</strong> ws://localhost:${MQTT_WS_PORT}
        </div>

        <h3>MQTT Topics:</h3>
        <div class="endpoint">
          <code>terrainiq/device/{deviceId}/location</code> - GPS updates (every 5s)
        </div>
        <div class="endpoint">
          <code>terrainiq/device/{deviceId}/status</code> - Status updates (every 5s)
        </div>
        <div class="endpoint">
          <code>terrainiq/device/{deviceId}/proximity</code> - Hazard proximity alerts
        </div>
        <div class="endpoint">
          <code>terrainiq/device/{deviceId}/heartbeat</code> - Health pulse (every 60s)
        </div>
        <div class="endpoint">
          <code>terrainiq/device/{deviceId}/recording</code> - Recording state changes
        </div>

        <h2>HTTP Endpoints:</h2>
        <div class="endpoint">
          <span class="method">POST</span> /heartbeat - Heartbeat signals
        </div>
        <div class="endpoint">
          <span class="method">POST</span> /upload - Video uploads
        </div>
        <div class="endpoint">
          <span class="method">POST</span> /get_hazards - Fetch hazards
        </div>

        <h2>Statistics:</h2>
        <p>HTTP Heartbeats: ${heartbeatCount}</p>
        <p>Connected Devices: ${deviceStates.size}</p>
      </body>
    </html>
  `);
});

// Start servers
mqttServer.listen(MQTT_PORT, () => {
  console.log('🚀 TerrainIQ Server with MQTT');
  console.log('═══════════════════════════════════════');
  console.log(`📡 HTTP Server:     http://localhost:${HTTP_PORT}`);
  console.log(`🗺️  Dashboard:       http://localhost:${HTTP_PORT}/dashboard`);
  console.log(`📊 MQTT Broker:     mqtt://localhost:${MQTT_PORT}`);
  console.log(`🌐 MQTT WebSocket:  ws://localhost:${MQTT_WS_PORT}`);
  console.log('═══════════════════════════════════════\n');
  console.log('Waiting for connections...\n');
});

httpServer.listen(MQTT_WS_PORT, () => {
  console.log(`✅ MQTT WebSocket broker ready on port ${MQTT_WS_PORT}`);
});

app.listen(HTTP_PORT, () => {
  console.log(`✅ HTTP server ready on port ${HTTP_PORT}`);
});
