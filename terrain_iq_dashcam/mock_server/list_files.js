/**
 * List all videos and their associated CSV files
 * Shows the relationship between video files and sensor data
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const UPLOADS_DIR = path.join(__dirname, 'uploads');

console.log('\n╔════════════════════════════════════════════════════════╗');
console.log('║   TerrainIQ - Video & CSV File Listing                ║');
console.log('╚════════════════════════════════════════════════════════╝\n');

// Check if directories exist
if (!fs.existsSync(DATA_DIR) && !fs.existsSync(UPLOADS_DIR)) {
    console.log('❌ No data found. Upload some videos first!\n');
    process.exit(0);
}

// Get all files
const dataFiles = fs.existsSync(DATA_DIR) ? fs.readdirSync(DATA_DIR) : [];
const videoFiles = fs.existsSync(UPLOADS_DIR) ? fs.readdirSync(UPLOADS_DIR) : [];

// Group files by base name
const recordings = new Map();

videoFiles.forEach(file => {
    if (file.endsWith('.mp4')) {
        const baseName = file.replace('.mp4', '');
        recordings.set(baseName, {
            video: file,
            csv: null,
            metadata: null,
            videoPath: path.join(UPLOADS_DIR, file),
            csvPath: null,
            metadataPath: null
        });
    }
});

dataFiles.forEach(file => {
    const baseName = file.replace(/\.(csv|json)$/, '');

    if (!recordings.has(baseName)) {
        recordings.set(baseName, {
            video: null,
            csv: null,
            metadata: null,
            videoPath: null,
            csvPath: null,
            metadataPath: null
        });
    }

    const recording = recordings.get(baseName);

    if (file.endsWith('.csv')) {
        recording.csv = file;
        recording.csvPath = path.join(DATA_DIR, file);
    } else if (file.endsWith('.json')) {
        recording.metadata = file;
        recording.metadataPath = path.join(DATA_DIR, file);
    }
});

if (recordings.size === 0) {
    console.log('📂 No recordings found.\n');
    process.exit(0);
}

console.log(`📊 Found ${recordings.size} recording(s)\n`);

// Display each recording
let index = 1;
for (const [baseName, recording] of recordings) {
    console.log(`\x1b[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m`);
    console.log(`\x1b[1m${index}. ${baseName}\x1b[0m`);
    console.log(`\x1b[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m`);

    // Video
    if (recording.video) {
        const stats = fs.statSync(recording.videoPath);
        const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
        console.log(`🎥 Video:    \x1b[32m✓\x1b[0m ${recording.video} (${sizeMB} MB)`);
        console.log(`   Path:     ${recording.videoPath}`);
    } else {
        console.log(`🎥 Video:    \x1b[31m✗\x1b[0m Not found`);
    }

    // CSV
    if (recording.csv) {
        const stats = fs.statSync(recording.csvPath);
        const sizeKB = (stats.size / 1024).toFixed(2);

        // Count rows
        const csvContent = fs.readFileSync(recording.csvPath, 'utf8');
        const rowCount = csvContent.split('\n').length - 1; // Subtract header

        console.log(`📊 CSV:      \x1b[32m✓\x1b[0m ${recording.csv} (${sizeKB} KB, ${rowCount} rows)`);
        console.log(`   Path:     ${recording.csvPath}`);

        // Show first few lines
        const lines = csvContent.split('\n');
        console.log(`   \x1b[90mPreview:\x1b[0m`);
        console.log(`   \x1b[90m${lines[0]}\x1b[0m`); // Header
        if (lines.length > 1) {
            console.log(`   \x1b[90m${lines[1]}\x1b[0m`); // First data row
        }
    } else {
        console.log(`📊 CSV:      \x1b[31m✗\x1b[0m Not found`);
    }

    // Metadata
    if (recording.metadata) {
        const stats = fs.statSync(recording.metadataPath);
        const sizeKB = (stats.size / 1024).toFixed(2);
        console.log(`📋 Metadata: \x1b[32m✓\x1b[0m ${recording.metadata} (${sizeKB} KB)`);
        console.log(`   Path:     ${recording.metadataPath}`);
    } else {
        console.log(`📋 Metadata: \x1b[31m✗\x1b[0m Not found`);
    }

    console.log();
    index++;
}

console.log(`\x1b[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m`);
console.log(`\n\x1b[1mSummary:\x1b[0m`);
console.log(`Total Recordings: ${recordings.size}`);
console.log(`Videos: ${Array.from(recordings.values()).filter(r => r.video).length}`);
console.log(`CSV Files: ${Array.from(recordings.values()).filter(r => r.csv).length}`);
console.log(`Metadata Files: ${Array.from(recordings.values()).filter(r => r.metadata).length}`);
console.log();

// Provide viewing instructions
console.log(`\x1b[33m💡 Viewing Options:\x1b[0m`);
console.log(`1. Web Viewer: http://localhost:3000/viewer.html`);
console.log(`2. Download CSV: http://localhost:3000/data/<filename>.csv`);
console.log(`3. Download Video: http://localhost:3000/videos/<filename>.mp4`);
console.log();
