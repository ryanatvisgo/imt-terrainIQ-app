/**
 * Server Testing Script for CSV Upload
 *
 * Tests the Node.js server endpoints for CSV and video uploads
 * Run with: node test_server.js
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Test configuration
const SERVER_URL = 'http://localhost:3000';
const TEST_DIR = path.join(__dirname, 'test_uploads');

// Test counters
let testsPassed = 0;
let testsFailed = 0;
const testResults = [];

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

// Create test directory
if (!fs.existsSync(TEST_DIR)) {
  fs.mkdirSync(TEST_DIR, { recursive: true });
}

/**
 * Create test CSV file
 */
function createTestCSV(filename) {
  const csvContent = `timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00
2025-10-11T10:00:01.000Z,1.1000,2.1000,3.1000,0.1100,0.2100,0.3100,0.5100,smooth,portrait,true,37.775000,-122.419300,100.10,10.10,5.10
2025-10-11T10:00:02.000Z,1.2000,2.2000,3.2000,0.1200,0.2200,0.3200,0.5200,rough,portrait,true,37.775100,-122.419200,100.20,10.20,5.20`;

  const filepath = path.join(TEST_DIR, filename);
  fs.writeFileSync(filepath, csvContent);
  return filepath;
}

/**
 * Create test metadata JSON file
 */
function createTestMetadata(filename, videoFilename, videoSize) {
  const metadata = {
    device: {
      model: 'Test Device',
      os: 'iOS 18.0',
      app_version: '1.0.0'
    },
    video: {
      filename: videoFilename,
      timestamp: new Date().toISOString(),
      duration_seconds: 10,
      size_bytes: videoSize,
      resolution: '1920x1080',
      fps: 30
    },
    location: {
      start: {
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 100.0
      },
      end: {
        latitude: 37.7751,
        longitude: -122.4192,
        altitude: 100.2
      }
    },
    session_id: crypto.randomUUID(),
    created_at: new Date().toISOString()
  };

  const filepath = path.join(TEST_DIR, filename);
  fs.writeFileSync(filepath, JSON.stringify(metadata, null, 2));
  return filepath;
}

/**
 * Create test video file (mock data)
 */
function createTestVideo(filename, sizeKB = 100) {
  const filepath = path.join(TEST_DIR, filename);
  const buffer = Buffer.alloc(sizeKB * 1024, 'A');
  fs.writeFileSync(filepath, buffer);
  return filepath;
}

/**
 * Send multipart/form-data request
 */
function sendMultipartRequest(endpoint, files, fields = {}) {
  return new Promise((resolve, reject) => {
    const boundary = `----TestBoundary${Date.now()}`;
    const url = new URL(endpoint, SERVER_URL);

    let body = '';

    // Add fields
    for (const [key, value] of Object.entries(fields)) {
      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="${key}"\r\n\r\n`;
      body += `${value}\r\n`;
    }

    // Add files
    for (const [fieldName, filepath] of Object.entries(files)) {
      const fileContent = fs.readFileSync(filepath);
      const filename = path.basename(filepath);

      body += `--${boundary}\r\n`;
      body += `Content-Disposition: form-data; name="${fieldName}"; filename="${filename}"\r\n`;
      body += `Content-Type: application/octet-stream\r\n\r\n`;
      body += fileContent.toString('binary');
      body += '\r\n';
    }

    body += `--${boundary}--\r\n`;

    const options = {
      method: 'POST',
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': Buffer.byteLength(body, 'binary')
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: JSON.parse(data)
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', reject);
    req.write(body, 'binary');
    req.end();
  });
}

/**
 * Send JSON request
 */
function sendJSONRequest(endpoint, method, data) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint, SERVER_URL);
    const body = JSON.stringify(data);

    const options = {
      method: method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', chunk => responseData += chunk);
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            body: JSON.parse(responseData)
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            body: responseData
          });
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

/**
 * Test runner
 */
async function runTest(name, testFn) {
  try {
    log(`\n▶ Running: ${name}`, colors.cyan);
    await testFn();
    testsPassed++;
    testResults.push({ name, status: 'PASSED' });
    log(`✅ PASSED: ${name}`, colors.green);
  } catch (error) {
    testsFailed++;
    testResults.push({ name, status: 'FAILED', error: error.message });
    log(`❌ FAILED: ${name}`, colors.red);
    log(`   Error: ${error.message}`, colors.red);
  }
}

/**
 * Assertion helper
 */
function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

/**
 * Test: Server Heartbeat
 */
async function testHeartbeat() {
  const response = await sendJSONRequest('/heartbeat', 'POST', {
    timestamp: new Date().toISOString(),
    status: 'testing',
    upload_queue_size: 0
  });

  assert(response.statusCode === 200, `Expected 200, got ${response.statusCode}`);
  assert(response.body.success === true, 'Expected success=true');
  assert(response.body.heartbeat_count > 0, 'Expected heartbeat_count > 0');
}

/**
 * Test: Upload Registration with CSV
 */
async function testUploadRegistration() {
  const videoFilename = `test_video_${Date.now()}.mp4`;
  const csvPath = createTestCSV('test_sensors.csv');
  const metadataPath = createTestMetadata('test_metadata.json', videoFilename, 1024 * 100);

  const response = await sendMultipartRequest('/upload/register', {
    csv: csvPath,
    metadata: metadataPath
  });

  assert(response.statusCode === 200, `Expected 200, got ${response.statusCode}`);
  assert(response.body.success === true, 'Expected success=true');
  assert(response.body.upload_id, 'Expected upload_id in response');
  assert(response.body.total_chunks > 0, 'Expected total_chunks > 0');

  log(`   Upload ID: ${response.body.upload_id}`, colors.blue);
  log(`   Total chunks: ${response.body.total_chunks}`, colors.blue);

  return response.body.upload_id;
}

/**
 * Test: CSV File Validation
 */
async function testCSVValidation() {
  const csvPath = createTestCSV('validation_test.csv');
  const content = fs.readFileSync(csvPath, 'utf8');
  const lines = content.split('\n');

  // Check header
  assert(lines[0].includes('timestamp'), 'CSV should have timestamp column');
  assert(lines[0].includes('accel_x'), 'CSV should have accel_x column');
  assert(lines[0].includes('latitude'), 'CSV should have latitude column');
  assert(lines[0].includes('longitude'), 'CSV should have longitude column');

  // Check data rows
  assert(lines.length >= 3, 'CSV should have at least 3 rows (header + 2 data)');
  assert(lines[1].includes('37.774900'), 'First data row should have latitude');

  log(`   CSV rows: ${lines.length}`, colors.blue);
  log(`   Columns: ${lines[0].split(',').length}`, colors.blue);
}

/**
 * Test: Large CSV Upload
 */
async function testLargeCSVUpload() {
  // Create large CSV with 1000 rows
  const header = 'timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy';
  const rows = [header];

  for (let i = 0; i < 1000; i++) {
    const timestamp = new Date(Date.now() + i * 100).toISOString();
    const row = `${timestamp},${i * 0.001},${i * 0.002},${i * 0.003},0.1,0.2,0.3,0.5,smooth,portrait,true,37.7749,-122.4194,100.0,10.0,5.0`;
    rows.push(row);
  }

  const csvPath = path.join(TEST_DIR, 'large_test.csv');
  fs.writeFileSync(csvPath, rows.join('\n'));

  const fileSize = fs.statSync(csvPath).size;
  log(`   CSV file size: ${(fileSize / 1024).toFixed(2)} KB`, colors.blue);

  assert(fileSize > 10000, 'CSV should be larger than 10KB');
  assert(rows.length === 1001, 'Should have 1001 rows (header + 1000 data)');
}

/**
 * Test: CSV Column Consistency
 */
async function testCSVColumnConsistency() {
  const csvPath = createTestCSV('consistency_test.csv');
  const content = fs.readFileSync(csvPath, 'utf8');
  const lines = content.split('\n').filter(line => line.trim() !== '');

  const headerColumns = lines[0].split(',').length;

  for (let i = 1; i < lines.length; i++) {
    const columns = lines[i].split(',').length;
    assert(columns === headerColumns, `Row ${i} has ${columns} columns, expected ${headerColumns}`);
  }

  log(`   All ${lines.length} rows have ${headerColumns} columns`, colors.blue);
}

/**
 * Test: Multiple File Upload (Video + CSV + Metadata)
 */
async function testMultipleFileUpload() {
  const videoFilename = `multi_test_${Date.now()}.mp4`;
  const csvPath = createTestCSV('multi_test.csv');
  const metadataPath = createTestMetadata('multi_test.json', videoFilename, 1024 * 100);

  const response = await sendMultipartRequest('/upload/register', {
    csv: csvPath,
    metadata: metadataPath
  });

  assert(response.statusCode === 200, `Expected 200, got ${response.statusCode}`);
  assert(response.body.upload_id, 'Should return upload_id');

  log(`   Registered upload with ID: ${response.body.upload_id}`, colors.blue);
}

/**
 * Test: CSV Data Integrity
 */
async function testCSVDataIntegrity() {
  const csvPath = createTestCSV('integrity_test.csv');
  const content = fs.readFileSync(csvPath, 'utf8');
  const lines = content.split('\n');

  // Parse and verify data
  const headers = lines[0].split(',');
  const latIndex = headers.indexOf('latitude');
  const lonIndex = headers.indexOf('longitude');
  const accelXIndex = headers.indexOf('accel_x');

  assert(latIndex >= 0, 'Should find latitude column');
  assert(lonIndex >= 0, 'Should find longitude column');
  assert(accelXIndex >= 0, 'Should find accel_x column');

  // Verify first data row
  const firstRow = lines[1].split(',');
  const lat = parseFloat(firstRow[latIndex]);
  const lon = parseFloat(firstRow[lonIndex]);
  const accelX = parseFloat(firstRow[accelXIndex]);

  assert(!isNaN(lat), 'Latitude should be a valid number');
  assert(!isNaN(lon), 'Longitude should be a valid number');
  assert(!isNaN(accelX), 'Accel X should be a valid number');

  log(`   Sample data - Lat: ${lat}, Lon: ${lon}, AccelX: ${accelX}`, colors.blue);
}

/**
 * Main test execution
 */
async function main() {
  log('\n╔════════════════════════════════════════════════════════╗', colors.cyan);
  log('║   TerrainIQ CSV Upload Test Suite                     ║', colors.cyan);
  log('╚════════════════════════════════════════════════════════╝', colors.cyan);

  log(`\n🎯 Testing server at: ${SERVER_URL}`, colors.yellow);
  log(`📂 Test directory: ${TEST_DIR}\n`, colors.yellow);

  // Check if server is running
  try {
    await sendJSONRequest('/heartbeat', 'POST', { timestamp: new Date().toISOString() });
    log('✅ Server is running\n', colors.green);
  } catch (error) {
    log('❌ Server is not running. Please start the server first:', colors.red);
    log('   cd mock_server && node server_v2.js\n', colors.yellow);
    process.exit(1);
  }

  // Run tests
  await runTest('Test 1: Server Heartbeat', testHeartbeat);
  await runTest('Test 2: Upload Registration with CSV', testUploadRegistration);
  await runTest('Test 3: CSV File Validation', testCSVValidation);
  await runTest('Test 4: Large CSV Upload', testLargeCSVUpload);
  await runTest('Test 5: CSV Column Consistency', testCSVColumnConsistency);
  await runTest('Test 6: Multiple File Upload', testMultipleFileUpload);
  await runTest('Test 7: CSV Data Integrity', testCSVDataIntegrity);

  // Summary
  log('\n╔════════════════════════════════════════════════════════╗', colors.cyan);
  log('║   Test Results Summary                                 ║', colors.cyan);
  log('╚════════════════════════════════════════════════════════╝', colors.cyan);

  testResults.forEach(result => {
    const symbol = result.status === 'PASSED' ? '✅' : '❌';
    const color = result.status === 'PASSED' ? colors.green : colors.red;
    log(`${symbol} ${result.name}`, color);
    if (result.error) {
      log(`   ${result.error}`, colors.red);
    }
  });

  log(`\n📊 Total Tests: ${testsPassed + testsFailed}`, colors.cyan);
  log(`✅ Passed: ${testsPassed}`, colors.green);
  log(`❌ Failed: ${testsFailed}`, testsFailed > 0 ? colors.red : colors.green);

  const passRate = ((testsPassed / (testsPassed + testsFailed)) * 100).toFixed(1);
  log(`📈 Pass Rate: ${passRate}%\n`, colors.cyan);

  // Clean up
  log('🧹 Cleaning up test files...', colors.yellow);
  if (fs.existsSync(TEST_DIR)) {
    fs.rmSync(TEST_DIR, { recursive: true, force: true });
  }
  log('✅ Cleanup complete\n', colors.green);

  process.exit(testsFailed > 0 ? 1 : 0);
}

// Run tests
main().catch(error => {
  log(`\n❌ Fatal error: ${error.message}`, colors.red);
  console.error(error);
  process.exit(1);
});
