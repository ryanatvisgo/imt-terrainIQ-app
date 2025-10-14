/**
 * TerrainIQ Dashcam Server v2.0
 *
 * Features:
 * - Chunked video uploads with resume support
 * - Metadata registration (JSON + CSV)
 * - Upload progress tracking
 * - Web UI for viewing uploads and data
 */

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Storage directories
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const METADATA_DIR = path.join(__dirname, 'metadata');
const CHUNKS_DIR = path.join(__dirname, 'chunks');
const DATA_DIR = path.join(__dirname, 'data');

// Create directories if they don't exist
[UPLOAD_DIR, METADATA_DIR, CHUNKS_DIR, DATA_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// In-memory upload tracking
const uploads = new Map();
let heartbeatCount = 0;

// Configure multer for metadata files
const metadataStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadId = req.params.upload_id || crypto.randomUUID();
    const uploadDir = path.join(METADATA_DIR, uploadId);
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  }
});

const metadataUpload = multer({ storage: metadataStorage });

/**
 * Heartbeat Endpoint (unchanged)
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
 * Register Upload - Step 1
 * POST /upload/register
 *
 * Accept metadata.json and sensors.csv, return upload_id
 */
app.post('/upload/register', metadataUpload.fields([
  { name: 'metadata', maxCount: 1 },
  { name: 'csv', maxCount: 1 }
]), (req, res) => {
  try {
    const uploadId = crypto.randomUUID();
    const files = req.files;

    if (!files || !files.metadata || !files.csv) {
      return res.status(400).json({
        success: false,
        error: 'Missing required files (metadata.json and sensors.csv)'
      });
    }

    const metadataFile = files.metadata[0];
    const csvFile = files.csv[0];

    // Read and parse metadata
    const metadataContent = JSON.parse(fs.readFileSync(metadataFile.path, 'utf8'));
    const videoFilename = metadataContent.video.filename;
    const videoSize = metadataContent.video.size_bytes;

    // Calculate chunk info
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const totalChunks = Math.ceil(videoSize / chunkSize);

    // Create upload tracking entry
    const upload = {
      upload_id: uploadId,
      filename: videoFilename,
      size_bytes: videoSize,
      chunk_size: chunkSize,
      total_chunks: totalChunks,
      chunks_received: [],
      status: 'pending',
      progress: 0,
      metadata: metadataContent,
      csv_path: csvFile.path,
      metadata_path: metadataFile.path,
      registered_at: new Date().toISOString(),
      chunks_dir: path.join(CHUNKS_DIR, uploadId),
    };

    // Create chunks directory
    if (!fs.existsSync(upload.chunks_dir)) {
      fs.mkdirSync(upload.chunks_dir, { recursive: true });
    }

    uploads.set(uploadId, upload);

    console.log(`\n📋 Upload Registered:`);
    console.log(`   Upload ID: ${uploadId}`);
    console.log(`   Filename: ${videoFilename}`);
    console.log(`   Size: ${(videoSize / 1024 / 1024).toFixed(2)} MB`);
    console.log(`   Total Chunks: ${totalChunks}`);
    console.log(`   Metadata: ${metadataFile.originalname}`);
    console.log(`   CSV: ${csvFile.originalname}`);

    res.status(200).json({
      success: true,
      upload_id: uploadId,
      chunk_size: chunkSize,
      total_chunks: totalChunks,
      ready: true,
      message: 'Upload registered successfully'
    });

  } catch (error) {
    console.error('❌ Error registering upload:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Upload Chunk - Step 2
 * POST /upload/chunk/:upload_id
 *
 * Accept a chunk of video data
 */
app.post('/upload/chunk/:upload_id', express.raw({ limit: '10mb', type: 'application/octet-stream' }), (req, res) => {
  try {
    const { upload_id } = req.params;
    const chunkIndex = parseInt(req.headers['x-chunk-index'] || '0');
    const totalChunks = parseInt(req.headers['x-total-chunks'] || '0');

    const upload = uploads.get(upload_id);
    if (!upload) {
      return res.status(404).json({
        success: false,
        error: 'Upload not found'
      });
    }

    // Save chunk
    const chunkPath = path.join(upload.chunks_dir, `chunk_${chunkIndex}`);
    fs.writeFileSync(chunkPath, req.body);

    // Update tracking
    if (!upload.chunks_received.includes(chunkIndex)) {
      upload.chunks_received.push(chunkIndex);
      upload.chunks_received.sort((a, b) => a - b);
    }

    upload.progress = (upload.chunks_received.length / upload.total_chunks) * 100;
    upload.status = 'uploading';
    upload.last_chunk_at = new Date().toISOString();

    console.log(`\n📦 Chunk Received:`);
    console.log(`   Upload ID: ${upload_id}`);
    console.log(`   Chunk: ${chunkIndex + 1}/${totalChunks}`);
    console.log(`   Progress: ${upload.progress.toFixed(1)}%`);

    res.status(200).json({
      success: true,
      received: true,
      chunk_index: chunkIndex,
      progress: upload.progress,
      chunks_received: upload.chunks_received.length,
      total_chunks: upload.total_chunks,
      next_chunk: chunkIndex + 1 < upload.total_chunks ? chunkIndex + 1 : null
    });

  } catch (error) {
    console.error('❌ Error receiving chunk:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Complete Upload - Step 3
 * POST /upload/complete/:upload_id
 *
 * Finalize upload and combine chunks
 */
app.post('/upload/complete/:upload_id', async (req, res) => {
  try {
    const { upload_id } = req.params;
    const upload = uploads.get(upload_id);

    if (!upload) {
      return res.status(404).json({
        success: false,
        error: 'Upload not found'
      });
    }

    // Verify all chunks received
    if (upload.chunks_received.length !== upload.total_chunks) {
      return res.status(400).json({
        success: false,
        error: `Incomplete upload: ${upload.chunks_received.length}/${upload.total_chunks} chunks`,
        missing_chunks: Array.from(
          { length: upload.total_chunks },
          (_, i) => i
        ).filter(i => !upload.chunks_received.includes(i))
      });
    }

    // Combine chunks into final video file
    const finalPath = path.join(UPLOAD_DIR, upload.filename);
    const writeStream = fs.createWriteStream(finalPath);

    for (let i = 0; i < upload.total_chunks; i++) {
      const chunkPath = path.join(upload.chunks_dir, `chunk_${i}`);
      const chunkData = fs.readFileSync(chunkPath);
      writeStream.write(chunkData);
    }

    writeStream.end();

    // Wait for write to complete
    await new Promise((resolve, reject) => {
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });

    // Move CSV to data directory
    const csvFinalPath = path.join(DATA_DIR, path.basename(upload.filename).replace('.mp4', '.csv'));
    fs.copyFileSync(upload.csv_path, csvFinalPath);

    // Move metadata to data directory
    const metadataFinalPath = path.join(DATA_DIR, path.basename(upload.filename).replace('.mp4', '.json'));
    fs.copyFileSync(upload.metadata_path, metadataFinalPath);

    // Clean up chunks
    fs.rmSync(upload.chunks_dir, { recursive: true, force: true });

    // Update upload status
    upload.status = 'complete';
    upload.progress = 100;
    upload.video_path = finalPath;
    upload.csv_path = csvFinalPath;
    upload.metadata_path = metadataFinalPath;
    upload.completed_at = new Date().toISOString();

    const videoUrl = `http://localhost:${PORT}/videos/${upload.filename}`;
    const csvUrl = `http://localhost:${PORT}/data/${path.basename(csvFinalPath)}`;
    const metadataUrl = `http://localhost:${PORT}/data/${path.basename(metadataFinalPath)}`;

    console.log(`\n✅ Upload Complete:`);
    console.log(`   Upload ID: ${upload_id}`);
    console.log(`   Video: ${videoUrl}`);
    console.log(`   CSV: ${csvUrl}`);
    console.log(`   Metadata: ${metadataUrl}`);

    res.status(200).json({
      success: true,
      upload_id: upload_id,
      video_url: videoUrl,
      csv_url: csvUrl,
      metadata_url: metadataUrl,
      completed_at: upload.completed_at
    });

  } catch (error) {
    console.error('❌ Error completing upload:', error);
    const upload = uploads.get(req.params.upload_id);
    if (upload) {
      upload.status = 'failed';
      upload.error = error.message;
    }
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get Upload Status
 * GET /upload/status/:upload_id
 */
app.get('/upload/status/:upload_id', (req, res) => {
  const { upload_id } = req.params;
  const upload = uploads.get(upload_id);

  if (!upload) {
    return res.status(404).json({
      success: false,
      error: 'Upload not found'
    });
  }

  res.status(200).json({
    success: true,
    upload_id: upload_id,
    filename: upload.filename,
    status: upload.status,
    progress: upload.progress,
    chunks_received: upload.chunks_received.length,
    total_chunks: upload.total_chunks,
    size_bytes: upload.size_bytes,
    registered_at: upload.registered_at,
    last_chunk_at: upload.last_chunk_at,
    completed_at: upload.completed_at,
  });
});

/**
 * List All Uploads
 * GET /uploads
 */
app.get('/uploads', (req, res) => {
  const uploadsList = Array.from(uploads.values()).map(u => ({
    upload_id: u.upload_id,
    filename: u.filename,
    status: u.status,
    progress: u.progress,
    size_mb: (u.size_bytes / 1024 / 1024).toFixed(2),
    registered_at: u.registered_at,
    completed_at: u.completed_at,
  }));

  res.status(200).json({
    success: true,
    total: uploadsList.length,
    uploads: uploadsList
  });
});

// Serve static files
app.use('/videos', express.static(UPLOAD_DIR));
app.use('/data', express.static(DATA_DIR));
app.use(express.static(path.join(__dirname, 'public')));

/**
 * Get all recordings with CSV and metadata
 * GET /api/recordings
 */
app.get('/api/recordings', (req, res) => {
  try {
    const recordings = [];
    const videoFiles = fs.existsSync(UPLOAD_DIR) ? fs.readdirSync(UPLOAD_DIR) : [];
    const dataFiles = fs.existsSync(DATA_DIR) ? fs.readdirSync(DATA_DIR) : [];

    // Group files by base name
    const fileMap = new Map();

    videoFiles.forEach(file => {
      if (file.endsWith('.mp4')) {
        const baseName = file.replace('.mp4', '');
        fileMap.set(baseName, { video: file });
      }
    });

    dataFiles.forEach(file => {
      const baseName = file.replace(/\.(csv|json)$/, '');
      if (!fileMap.has(baseName)) {
        fileMap.set(baseName, {});
      }
      const record = fileMap.get(baseName);
      if (file.endsWith('.csv')) {
        record.csv = file;
      } else if (file.endsWith('.json')) {
        record.metadata = file;
      }
    });

    // Build recording objects
    for (const [baseName, files] of fileMap) {
      if (files.video) {
        const videoPath = path.join(UPLOAD_DIR, files.video);
        const stats = fs.statSync(videoPath);

        const recording = {
          filename: files.video,
          baseName: baseName,
          videoUrl: `/videos/${files.video}`,
          csvUrl: files.csv ? `/data/${files.csv}` : null,
          metadataUrl: files.metadata ? `/data/${files.metadata}` : null,
          size: `${(stats.size / 1024 / 1024).toFixed(2)} MB`,
          uploadedAt: stats.mtime,
        };

        // Try to get metadata if it exists
        if (files.metadata) {
          try {
            const metadataPath = path.join(DATA_DIR, files.metadata);
            const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
            recording.duration = metadata.video?.duration_seconds
              ? `${Math.floor(metadata.video.duration_seconds / 60)}:${String(metadata.video.duration_seconds % 60).padStart(2, '0')}`
              : null;
          } catch (e) {
            // Ignore metadata parsing errors
          }
        }

        recordings.push(recording);
      }
    }

    // Sort by upload time (newest first)
    recordings.sort((a, b) => new Date(b.uploadedAt) - new Date(a.uploadedAt));

    res.json(recordings);
  } catch (error) {
    console.error('Error listing recordings:', error);
    res.status(500).json({ error: error.message });
  }
});

// Web UI (will create comprehensive UI next)
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>TerrainIQ Server v2.0</title>
        <style>
          body { font-family: Arial; max-width: 1200px; margin: 50px auto; padding: 20px; }
          h1 { color: #1E88E5; }
          .big-link { display: inline-block; margin: 20px 10px; padding: 15px 30px; background: #1E88E5; color: white; text-decoration: none; border-radius: 5px; }
          .big-link:hover { background: #1565C0; }
        </style>
      </head>
      <body>
        <h1>🚗 TerrainIQ Dashcam Server v2.0</h1>
        <p>Server running with chunked upload support</p>

        <a href="/viewer.html" class="big-link">📺 View Videos & CSVs</a>

        <h2>Endpoints:</h2>
        <ul>
          <li>POST /upload/register - Register new upload</li>
          <li>POST /upload/chunk/:id - Upload video chunk</li>
          <li>POST /upload/complete/:id - Complete upload</li>
          <li>GET /upload/status/:id - Check upload status</li>
          <li>GET /uploads - List all uploads</li>
          <li>GET /api/recordings - List all recordings with CSV data</li>
          <li><a href="/viewer.html">📺 Video & CSV Viewer</a></li>
        </ul>
      </body>
    </html>
  `);
});

// Start server
app.listen(PORT, () => {
  console.log('\n🚀 TerrainIQ Dashcam Server v2.0');
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`📂 Upload directory: ${UPLOAD_DIR}`);
  console.log(`📊 Metadata directory: ${METADATA_DIR}`);
  console.log(`📦 Chunks directory: ${CHUNKS_DIR}\n`);
  console.log('Ready to accept uploads!\n');
});
