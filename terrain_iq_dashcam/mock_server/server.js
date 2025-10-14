/**
 * Mock Server for TerrainIQ Dashcam Testing
 *
 * This simple Express server simulates the backend API for testing:
 * - Heartbeat endpoint
 * - Video upload endpoint
 *
 * To run:
 * 1. Install Node.js if not already installed
 * 2. Run: npm install express multer
 * 3. Run: node server.js
 * 4. Server will start on http://localhost:3000
 */

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

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
  limits: { fileSize: 500 * 1024 * 1024 } // 500MB max file size
});

// Heartbeat counter
let heartbeatCount = 0;

/**
 * Heartbeat Endpoint
 * POST /heartbeat
 *
 * Receives heartbeat signals from the dashcam app
 */
app.post('/heartbeat', (req, res) => {
  heartbeatCount++;
  const { timestamp, status, upload_queue_size } = req.body;

  console.log(`\n💓 Heartbeat #${heartbeatCount} received:`);
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

/**
 * Video Upload Endpoint
 * POST /upload
 *
 * Receives video files, CSV data, and metadata from the dashcam app
 * Returns a mock video URL
 */
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
  if (metadataFile) console.log(`   Metadata: ${metadataFile.originalname} (${(metadataFile.size / 1024).toFixed(2)} KB)`);
  console.log(`   Timestamp: ${timestamp}`);

  // Generate a mock video URL
  const videoUrl = `http://localhost:${PORT}/videos/${videoFile.filename}`;

  // Store association between files
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

/**
 * Serve uploaded videos
 * GET /videos/:filename
 */
app.use('/videos', express.static(path.join(__dirname, 'uploads')));

/**
 * Status Endpoint
 * GET /status
 *
 * Returns server status information
 */
app.get('/status', (req, res) => {
  const uploadDir = path.join(__dirname, 'uploads');
  let uploadedFiles = [];
  let totalSize = 0;

  if (fs.existsSync(uploadDir)) {
    uploadedFiles = fs.readdirSync(uploadDir);
    uploadedFiles.forEach(file => {
      const stats = fs.statSync(path.join(uploadDir, file));
      totalSize += stats.size;
    });
  }

  res.status(200).json({
    status: 'running',
    uptime: process.uptime(),
    heartbeat_count: heartbeatCount,
    uploaded_videos: uploadedFiles.length,
    total_storage_mb: (totalSize / 1024 / 1024).toFixed(2),
    files: uploadedFiles
  });
});

/**
 * Files Browser Endpoint
 * GET /files
 */
app.get('/files', (req, res) => {
  const uploadDir = path.join(__dirname, 'uploads');
  const dataDir = path.join(__dirname, 'data');
  const metadataDir = path.join(__dirname, 'metadata');
  let uploadedFiles = [];
  let totalSize = 0;

  // Find all associations
  const associations = {};
  if (fs.existsSync(dataDir)) {
    fs.readdirSync(dataDir)
      .filter(f => f.endsWith('-association.json'))
      .forEach(file => {
        const assoc = JSON.parse(fs.readFileSync(path.join(dataDir, file), 'utf8'));
        associations[assoc.video] = assoc;
      });
  }

  if (fs.existsSync(uploadDir)) {
    uploadedFiles = fs.readdirSync(uploadDir).map(filename => {
      const filePath = path.join(uploadDir, filename);
      const stats = fs.statSync(filePath);
      totalSize += stats.size;

      const assoc = associations[filename];
      let csvData = null;
      let metadata = null;

      if (assoc) {
        if (assoc.csv && fs.existsSync(path.join(dataDir, assoc.csv))) {
          csvData = fs.readFileSync(path.join(dataDir, assoc.csv), 'utf8');
        }
        if (assoc.metadata && fs.existsSync(path.join(metadataDir, assoc.metadata))) {
          metadata = JSON.parse(fs.readFileSync(path.join(metadataDir, assoc.metadata), 'utf8'));
        }
      }

      return {
        name: filename,
        size: stats.size,
        sizeStr: (stats.size / 1024 / 1024).toFixed(2) + ' MB',
        modified: stats.mtime.toLocaleString(),
        url: `/videos/${filename}`,
        csvData: csvData,
        metadata: metadata,
        hasData: !!(csvData || metadata)
      };
    }).sort((a, b) => b.modified.localeCompare(a.modified));
  }

  const fileRows = uploadedFiles.map((file, idx) => {
    // Parse CSV data into table
    let csvTable = '';
    if (file.csvData) {
      const lines = file.csvData.trim().split('\n');
      const headers = lines[0].split(',');
      const rows = lines.slice(1);

      csvTable = `
        <table class="csv-table">
          <thead>
            <tr>${headers.map(h => `<th>${h}</th>`).join('')}</tr>
          </thead>
          <tbody>
            ${rows.slice(0, 100).map(row => {
              const cells = row.split(',');
              return `<tr>${cells.map(c => `<td>${c}</td>`).join('')}</tr>`;
            }).join('')}
          </tbody>
        </table>
        ${rows.length > 100 ? `<p style="color: #666; font-size: 12px;">Showing first 100 of ${rows.length} rows</p>` : ''}
      `;
    }

    let metadataSection = '';
    if (file.metadata) {
      metadataSection = `<pre class="metadata">${JSON.stringify(file.metadata, null, 2)}</pre>`;
    }

    return `
      <tr>
        <td>
          ${file.hasData ? `<button class="expand-btn" onclick="toggleRow('row-${idx}')">▶</button>` : ''}
          <a href="${file.url}" target="_blank">${file.name}</a>
        </td>
        <td>${file.sizeStr}</td>
        <td>${file.modified}</td>
        <td>
          <a href="${file.url}" download class="btn">Download</a>
          <button class="btn" onclick="openVideoPopup('${file.url}', '${file.name}')">View</button>
        </td>
      </tr>
      ${file.hasData ? `
      <tr id="row-${idx}" class="detail-row" style="display: none;">
        <td colspan="4">
          <div class="detail-content">
            ${file.metadata ? `
              <div class="detail-section">
                <h3>📊 Metadata</h3>
                ${metadataSection}
              </div>
            ` : ''}
            ${file.csvData ? `
              <div class="detail-section">
                <h3>📈 Sensor Data</h3>
                ${csvTable}
              </div>
            ` : ''}
          </div>
        </td>
      </tr>
      ` : ''}
    `;
  }).join('');

  res.send(`
    <html>
      <head>
        <title>File Browser - TerrainIQ Dashcam</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 1400px;
            margin: 30px auto;
            padding: 20px;
            background: #f5f5f5;
          }
          h1 { color: #1E88E5; }
          .stats {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
          }
          .stat-box {
            text-align: center;
          }
          .stat-value {
            font-size: 32px;
            font-weight: bold;
            color: #1E88E5;
          }
          .stat-label {
            color: #666;
            font-size: 14px;
          }
          table {
            width: 100%;
            background: white;
            border-collapse: collapse;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
          }
          th {
            background: #1E88E5;
            color: white;
            font-weight: bold;
          }
          tr:hover:not(.detail-row) { background: #f5f5f5; }
          a { color: #1E88E5; text-decoration: none; }
          a:hover { text-decoration: underline; }
          .btn {
            display: inline-block;
            padding: 6px 12px;
            background: #1E88E5;
            color: white !important;
            border-radius: 4px;
            margin-right: 8px;
            text-decoration: none !important;
          }
          .btn:hover { background: #1976D2; }
          .empty {
            text-align: center;
            padding: 40px;
            color: #999;
          }
          .refresh {
            float: right;
            background: #4CAF50;
          }
          .expand-btn {
            background: none;
            border: none;
            color: #1E88E5;
            cursor: pointer;
            font-size: 14px;
            margin-right: 8px;
            padding: 4px;
            transition: transform 0.2s;
          }
          .expand-btn.expanded {
            transform: rotate(90deg);
          }
          .detail-row {
            background: #f9f9f9;
          }
          .detail-content {
            padding: 20px;
          }
          .detail-section {
            margin-bottom: 20px;
          }
          .detail-section h3 {
            color: #1E88E5;
            margin-top: 0;
          }
          .csv-table {
            width: 100%;
            font-size: 12px;
            margin-top: 10px;
          }
          .csv-table th {
            background: #666;
            font-size: 11px;
          }
          .csv-table td {
            padding: 6px;
          }
          .metadata {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
            font-size: 13px;
          }
        </style>
        <script>
          function toggleRow(rowId) {
            const row = document.getElementById(rowId);
            const btn = event.target;

            if (row.style.display === 'none') {
              row.style.display = 'table-row';
              btn.classList.add('expanded');
              btn.textContent = '▼';
            } else {
              row.style.display = 'none';
              btn.classList.remove('expanded');
              btn.textContent = '▶';
            }
          }

          function openVideoPopup(videoUrl, fileName) {
            const popup = window.open('', 'Video Player', 'width=900,height=700,resizable=yes,scrollbars=yes');
            popup.document.write(\`
              <!DOCTYPE html>
              <html>
                <head>
                  <title>\${fileName}</title>
                  <style>
                    body {
                      margin: 0;
                      padding: 0;
                      background: #1a1a1a;
                      font-family: Arial, sans-serif;
                      color: #fff;
                    }
                    .container {
                      max-width: 100%;
                      padding: 20px;
                    }
                    .header {
                      text-align: center;
                      padding: 15px 0;
                      border-bottom: 1px solid #333;
                    }
                    h2 {
                      margin: 0;
                      font-size: 18px;
                      color: #1E88E5;
                    }
                    .video-container {
                      display: flex;
                      justify-content: center;
                      padding: 20px 0;
                      background: #000;
                    }
                    video {
                      max-width: 100%;
                      max-height: 500px;
                      border-radius: 4px;
                    }
                    .info-section {
                      background: #2a2a2a;
                      padding: 20px;
                      margin: 20px 0;
                      border-radius: 8px;
                    }
                    .info-section h3 {
                      margin-top: 0;
                      color: #1E88E5;
                      font-size: 16px;
                    }
                    .info-row {
                      display: flex;
                      justify-content: space-between;
                      padding: 8px 0;
                      border-bottom: 1px solid #333;
                    }
                    .info-row:last-child {
                      border-bottom: none;
                    }
                    .info-label {
                      color: #999;
                      font-size: 14px;
                    }
                    .info-value {
                      color: #fff;
                      font-size: 14px;
                      font-weight: 500;
                    }
                    .button-container {
                      text-align: center;
                      padding: 20px 0 30px;
                    }
                    .close-btn {
                      padding: 12px 40px;
                      background: #1E88E5;
                      color: white;
                      border: none;
                      border-radius: 4px;
                      cursor: pointer;
                      font-size: 16px;
                      font-weight: 500;
                    }
                    .close-btn:hover {
                      background: #1976D2;
                    }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <div class="header">
                      <h2>\${fileName}</h2>
                    </div>
                    <div class="video-container">
                      <video controls autoplay>
                        <source src="\${videoUrl}" type="video/mp4">
                        Your browser does not support the video tag.
                      </video>
                    </div>
                    <div class="info-section">
                      <h3>Video Information</h3>
                      <div class="info-row">
                        <span class="info-label">Filename:</span>
                        <span class="info-value">\${fileName}</span>
                      </div>
                      <div class="info-row">
                        <span class="info-label">Source:</span>
                        <span class="info-value">TerrainIQ Dashcam</span>
                      </div>
                    </div>
                    <div class="button-container">
                      <button class="close-btn" onclick="window.close()">Close Window</button>
                    </div>
                  </div>
                </body>
              </html>
            \`);
          }

          // Auto-refresh disabled when rows are expanded
          let refreshEnabled = true;
          setInterval(() => {
            const expandedRows = document.querySelectorAll('.detail-row[style*="table-row"]');
            if (expandedRows.length === 0 && refreshEnabled) {
              location.reload();
            }
          }, 30000); // Auto-refresh every 30 seconds if no rows expanded
        </script>
      </head>
      <body>
        <h1>📁 File Browser</h1>
        <a href="/" class="btn">← Back to Home</a>
        <a href="/files" class="btn refresh">🔄 Refresh</a>

        <div class="stats">
          <div class="stats-grid">
            <div class="stat-box">
              <div class="stat-value">${uploadedFiles.length}</div>
              <div class="stat-label">Total Files</div>
            </div>
            <div class="stat-box">
              <div class="stat-value">${(totalSize / 1024 / 1024).toFixed(2)} MB</div>
              <div class="stat-label">Total Storage</div>
            </div>
            <div class="stat-box">
              <div class="stat-value">${heartbeatCount}</div>
              <div class="stat-label">Heartbeats</div>
            </div>
          </div>
        </div>

        ${uploadedFiles.length > 0 ? `
        <table>
          <thead>
            <tr>
              <th>Filename</th>
              <th>Size</th>
              <th>Modified</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            ${fileRows}
          </tbody>
        </table>
        ` : `
        <div class="empty">
          <h2>No files uploaded yet</h2>
          <p>Files will appear here once uploaded from the app</p>
        </div>
        `}

        <p style="margin-top: 20px; color: #666; font-size: 12px;">
          Auto-refreshing every 10 seconds
        </p>
      </body>
    </html>
  `);
});

/**
 * Log Upload Endpoint
 * POST /logs
 *
 * Receives device log files from the dashcam app
 */
app.post('/logs', upload.single('log'), (req, res) => {
  if (!req.file) {
    console.log('❌ Log upload failed: No log file provided');
    return res.status(400).json({
      success: false,
      error: 'No log file provided'
    });
  }

  const { timestamp, file_size, file_name } = req.body;
  const logFile = req.file;

  // Move log file to logs directory
  const logsDir = path.join(__dirname, 'logs');
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
  }

  const logFilePath = path.join(logsDir, logFile.originalname || logFile.filename);
  fs.renameSync(logFile.path, logFilePath);

  console.log(`\n📝 Log file uploaded:`);
  console.log(`   File: ${file_name || logFile.originalname} (${(logFile.size / 1024).toFixed(2)} KB)`);
  console.log(`   Timestamp: ${timestamp}`);
  console.log(`   Saved to: logs/${path.basename(logFilePath)}`);

  res.status(200).json({
    success: true,
    message: 'Log file uploaded successfully',
    file_name: path.basename(logFilePath),
    file_size: logFile.size,
    upload_time: new Date().toISOString()
  });
});

/**
 * Get Hazards Endpoint
 * POST /get_hazards
 *
 * Returns hazard zones within a specified radius of the given location
 */
app.post('/get_hazards', (req, res) => {
  const { lat, lon, radius_km } = req.body;

  console.log(`\n⚠️ Hazards requested:`);
  console.log(`   Location: ${lat}, ${lon}`);
  console.log(`   Radius: ${radius_km}km`);

  // Get mock hazards
  const mockHazards = getMockHazards(lat, lon);

  console.log(`   → Returning ${mockHazards.length} mock hazards`);

  // Load custom hazards from file and merge with mock hazards
  const customHazards = loadCustomHazards();
  const allHazards = [...mockHazards, ...customHazards];

  res.status(200).json({
    success: true,
    hazards: allHazards,
    count: allHazards.length,
    query_location: { lat, lon },
    radius_km: radius_km,
    fetch_time: new Date().toISOString()
  });
});

/**
 * Add Hazard Endpoint
 * POST /add_hazard
 *
 * Adds a new hazard to the persistent storage
 */
app.post('/add_hazard', (req, res) => {
  const { lat, lon, severity, labels, zone_m, notes } = req.body;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  const newHazard = {
    id: Date.now() + '-' + Math.round(Math.random() * 1E9),
    lon: parseFloat(lon),
    lat: parseFloat(lat),
    zone_m: zone_m || 50,
    last_detected: new Date().toISOString(),
    times_detected_6mos: 1,
    severity: severity || 5,
    labels: labels || ['custom hazard'],
    driver_notes: notes ? [{
      datetime: new Date().toISOString(),
      notes: notes,
      driver_name: 'Admin'
    }] : []
  };

  const customHazards = loadCustomHazards();
  customHazards.push(newHazard);
  saveCustomHazards(customHazards);

  console.log(`\n✅ Hazard added at ${lat}, ${lon}`);

  res.status(200).json({
    success: true,
    message: 'Hazard added successfully',
    hazard: newHazard
  });
});

/**
 * Remove Hazard Endpoint
 * DELETE /remove_hazard/:id
 *
 * Removes a hazard from persistent storage
 */
app.delete('/remove_hazard/:id', (req, res) => {
  const { id } = req.params;

  const customHazards = loadCustomHazards();
  const filteredHazards = customHazards.filter(h => h.id !== id);

  if (filteredHazards.length === customHazards.length) {
    return res.status(404).json({
      success: false,
      error: 'Hazard not found'
    });
  }

  saveCustomHazards(filteredHazards);

  console.log(`\n🗑️ Hazard removed: ${id}`);

  res.status(200).json({
    success: true,
    message: 'Hazard removed successfully'
  });
});

/**
 * Get All Hazards Endpoint
 * GET /all_hazards
 *
 * Returns all hazards (mock + custom) without location filtering
 */
app.get('/all_hazards', (req, res) => {
  const customHazards = loadCustomHazards();
  const mockHazards = getMockHazards(0, 0); // Get all mock hazards

  res.status(200).json({
    success: true,
    hazards: [...mockHazards, ...customHazards],
    count: mockHazards.length + customHazards.length
  });
});

// Helper functions for hazard storage
function loadCustomHazards() {
  const hazardsFile = path.join(__dirname, 'custom_hazards.json');
  if (fs.existsSync(hazardsFile)) {
    try {
      const data = fs.readFileSync(hazardsFile, 'utf8');
      return JSON.parse(data);
    } catch (e) {
      console.error('Error loading custom hazards:', e);
      return [];
    }
  }
  return [];
}

function saveCustomHazards(hazards) {
  const hazardsFile = path.join(__dirname, 'custom_hazards.json');
  fs.writeFileSync(hazardsFile, JSON.stringify(hazards, null, 2));
}

function getMockHazards(lat, lon) {
  return [
    // HAZARD AT FIXED TEST LOCATION (80m from user's house)
    {
      id: 'mock-1',
      lon: -119.492921,
      lat: 49.820725,
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
    // HAZARD ENDPOINT - End of test route
    {
      id: 'mock-2',
      lon: -119.494069,
      lat: 49.821020,
      zone_m: 50,
      last_detected: '2025-10-11T09:00:00Z',
      times_detected_6mos: 15,
      severity: 9,
      labels: ['potholes', 'bumps', 'high risk area'],
      driver_notes: [
        {
          datetime: '2025-10-10T14:00:00Z',
          notes: 'Large pothole ahead, extreme caution',
          driver_name: 'Driver B'
        }
      ]
    },
    {
      id: 'mock-3',
      lon: lat ? (lon - 0.008) : -119.500921,
      lat: lat ? (lat + 0.002) : 49.822725,
      zone_m: 30,
      last_detected: '2025-10-10T16:45:00Z',
      times_detected_6mos: 15,
      severity: 7,
      labels: ['potholes', 'bumps'],
      driver_notes: [
        {
          datetime: '2025-10-09T08:15:00Z',
          notes: 'Watch for large pothole on right side',
          driver_name: 'Driver B'
        }
      ]
    }
  ];
}

/**
 * Hazard Map Interface
 * GET /hazard-map
 *
 * Interactive map for viewing and managing hazards
 */
app.get('/hazard-map', (req, res) => {
  res.sendFile(path.join(__dirname, 'hazard_map.html'));
});

/**
 * App Simulator Endpoint
 * GET /app_simulator.html
 */
app.get('/app_simulator.html', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'app_simulator.html'));
});

/**
 * Root Endpoint
 * GET /
 */
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>TerrainIQ Dashcam Mock Server</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
          h1 { color: #1E88E5; }
          .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
          .method { font-weight: bold; color: #4CAF50; }
          .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #1E88E5;
            color: white;
            border-radius: 4px;
            text-decoration: none;
            margin: 10px 10px 10px 0;
          }
          .btn:hover { background: #1976D2; }
        </style>
      </head>
      <body>
        <h1>🚗 TerrainIQ Dashcam Mock Server</h1>
        <p>Server is running and ready to accept requests.</p>

        <a href="/files" class="btn">📁 Browse Files</a>
        <a href="/status" class="btn">📊 View Status</a>
        <a href="/hazard-map" class="btn">🗺️ Hazard Map</a>
        <a href="/app_simulator.html" class="btn">📱 App Simulator</a>

        <h2>Available Endpoints:</h2>

        <div class="endpoint">
          <span class="method">POST</span> /heartbeat
          <p>Receives heartbeat signals from the app</p>
        </div>

        <div class="endpoint">
          <span class="method">POST</span> /upload
          <p>Receives video file uploads (multipart/form-data)</p>
        </div>

        <div class="endpoint">
          <span class="method">GET</span> /files
          <p>Browse uploaded files with a web interface</p>
        </div>

        <div class="endpoint">
          <span class="method">GET</span> /status
          <p>View server status and uploaded files (JSON)</p>
        </div>

        <div class="endpoint">
          <span class="method">GET</span> /videos/:filename
          <p>Access uploaded video files</p>
        </div>

        <h2>Statistics:</h2>
        <p>Heartbeats received: ${heartbeatCount}</p>
      </body>
    </html>
  `);
});

// Start server - bind to 0.0.0.0 to accept connections from all network interfaces
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n🚀 TerrainIQ Dashcam Mock Server');
  console.log(`📡 Server running on http://0.0.0.0:${PORT}`);
  console.log(`📡 Access from iPhone using: http://192.168.8.105:${PORT}`);
  console.log(`📂 Upload directory: ${path.join(__dirname, 'uploads')}\n`);
  console.log('Endpoints:');
  console.log(`  POST http://192.168.8.105:${PORT}/heartbeat`);
  console.log(`  POST http://192.168.8.105:${PORT}/upload`);
  console.log(`  GET  http://192.168.8.105:${PORT}/status`);
  console.log(`  GET  http://192.168.8.105:${PORT}/videos/:filename`);
  console.log('\nWaiting for requests...\n');
});
