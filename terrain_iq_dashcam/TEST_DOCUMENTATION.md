# TerrainIQ CSV Upload Testing Documentation

## Overview

This document describes the comprehensive test automation suite for verifying CSV file generation and upload functionality in the TerrainIQ Dashcam application.

## Test Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Test Suite Architecture                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────┐        ┌──────────────────┐        │
│  │  Flutter App    │  CSV   │   Mock Server    │        │
│  │  (Client)       │───────▶│   (Node.js)      │        │
│  └─────────────────┘        └──────────────────┘        │
│         │                            │                   │
│         │                            │                   │
│         ▼                            ▼                   │
│  ┌─────────────────┐        ┌──────────────────┐        │
│  │  Unit Tests     │        │  Server Tests    │        │
│  │  - DataLogger   │        │  - Endpoint      │        │
│  │  - ServerService│        │  - CSV Parsing   │        │
│  └─────────────────┘        └──────────────────┘        │
│                                                           │
│  ┌───────────────────────────────────────────┐          │
│  │     End-to-End Test Orchestration         │          │
│  │     (Automated test runner)               │          │
│  └───────────────────────────────────────────┘          │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Test Components

### 1. Flutter Unit Tests

#### DataLoggerService Tests
**Location:** `test/services/data_logger_service_test.dart`

Tests CSV file generation functionality:
- ✅ CSV file creation and initialization
- ✅ Data point logging with sensor data
- ✅ GPS point collection and storage
- ✅ CSV format validation (headers, columns, data types)
- ✅ Numeric precision (4 decimal places)
- ✅ Handling missing GPS data
- ✅ Large file generation (1000+ rows)
- ✅ Column count consistency
- ✅ File size reporting

**Run:**
```bash
cd terrain_iq_dashcam
flutter test test/services/data_logger_service_test.dart
```

#### ServerService CSV Tests
**Location:** `test/services/server_service_csv_test.dart`

Tests CSV upload integration:
- ✅ CSV file creation for upload
- ✅ Video-CSV file association
- ✅ CSV content format validation
- ✅ Multipart upload preparation
- ✅ File discovery from video path
- ✅ Data integrity verification
- ✅ Large CSV handling
- ✅ Column consistency validation

**Run:**
```bash
cd terrain_iq_dashcam
flutter test test/services/server_service_csv_test.dart
```

### 2. Server Endpoint Tests

**Location:** `mock_server/test_server.js`

Tests Node.js server CSV handling:
- ✅ Server heartbeat
- ✅ Upload registration with CSV
- ✅ CSV file validation
- ✅ Large CSV upload (1000+ rows)
- ✅ CSV column consistency
- ✅ Multiple file upload (video + CSV + metadata)
- ✅ CSV data integrity

**Run:**
```bash
cd terrain_iq_dashcam/mock_server
node test_server.js
```

**Prerequisites:**
- Server must be running on port 3000
- Start server first: `node server_v2.js`

### 3. End-to-End Test Script

**Location:** `test_csv_upload_e2e.sh`

Automated test orchestration that:
1. ✅ Checks prerequisites (Node.js, Flutter)
2. ✅ Starts mock server automatically
3. ✅ Runs server endpoint tests
4. ✅ Runs Flutter unit tests
5. ✅ Runs Flutter integration tests
6. ✅ Generates test report
7. ✅ Cleans up resources

**Run:**
```bash
./test_csv_upload_e2e.sh
```

## Quick Start

### Option 1: Run Everything (Recommended)

```bash
# Make script executable (first time only)
chmod +x test_csv_upload_e2e.sh

# Run complete test suite
./test_csv_upload_e2e.sh
```

This will:
- Automatically start the server
- Run all tests
- Generate a report
- Clean up resources

### Option 2: Run Tests Individually

#### Server Tests Only

```bash
# Terminal 1: Start server
cd terrain_iq_dashcam/mock_server
node server_v2.js

# Terminal 2: Run tests
cd terrain_iq_dashcam/mock_server
node test_server.js
```

#### Flutter Tests Only

```bash
cd terrain_iq_dashcam

# Run specific test file
flutter test test/services/data_logger_service_test.dart
flutter test test/services/server_service_csv_test.dart

# Or run all tests
flutter test
```

## Test Data

### CSV Format

The tests validate this CSV structure:

```csv
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00
```

**Columns (16 total):**
- `timestamp` - ISO 8601 format
- `accel_x`, `accel_y`, `accel_z` - Accelerometer (4 decimals)
- `gyro_x`, `gyro_y`, `gyro_z` - Gyroscope (4 decimals)
- `roughness` - Road roughness score (4 decimals)
- `roughness_level` - Categorical level (smooth/rough/very_rough)
- `orientation` - Device orientation (portrait/landscape)
- `is_moving` - Movement status (true/false)
- `latitude`, `longitude` - GPS coordinates (6 decimals)
- `altitude` - Elevation in meters (2 decimals)
- `speed_mps` - Speed in m/s (2 decimals)
- `accuracy` - GPS accuracy in meters (2 decimals)

### Upload Process

The tests validate this upload flow:

```
1. Register Upload
   POST /upload/register
   Body: metadata.json + sensors.csv
   Response: upload_id, chunk_size, total_chunks

2. Upload Video Chunks
   POST /upload/chunk/:upload_id
   Body: video chunk data
   Headers: x-chunk-index, x-total-chunks
   Response: progress, next_chunk

3. Complete Upload
   POST /upload/complete/:upload_id
   Response: video_url, csv_url, metadata_url
```

## Test Coverage

### What's Tested

✅ **CSV Generation**
- File creation and writing
- Header generation
- Data row formatting
- Numeric precision
- Missing data handling

✅ **CSV Validation**
- Column count consistency
- Data type validation
- Format compliance
- Content integrity

✅ **Upload Process**
- Multipart form data
- File association (video + CSV + metadata)
- Large file handling
- Error handling

✅ **Server Endpoints**
- Registration endpoint
- Chunk upload endpoint
- Completion endpoint
- Status checking

### What's NOT Tested

❌ Physical device sensors (requires real device)
❌ Actual network conditions
❌ iOS/Android platform-specific behavior
❌ Camera integration
❌ Real-time GPS data collection
❌ Storage limits and cleanup

## Interpreting Results

### Success Output

```
╔════════════════════════════════════════════════════════╗
║   Test Results Summary                                 ║
╚════════════════════════════════════════════════════════╝
✅ Test 1: Server Heartbeat
✅ Test 2: Upload Registration with CSV
✅ Test 3: CSV File Validation
✅ Test 4: Large CSV Upload
✅ Test 5: CSV Column Consistency
✅ Test 6: Multiple File Upload
✅ Test 7: CSV Data Integrity

📊 Total Tests: 7
✅ Passed: 7
❌ Failed: 0
📈 Pass Rate: 100.0%
```

### Test Report

A detailed report is saved after each run:
```
test_report_YYYYMMDD_HHMMSS.txt
```

Contains:
- Test execution summary
- Pass/fail counts
- Environment details
- Server configuration
- Notes and observations

## Troubleshooting

### Server Not Starting

**Problem:** `Server failed to start`

**Solution:**
```bash
# Check if port 3000 is in use
lsof -i :3000

# Kill existing process
kill -9 <PID>

# Or use different port in server_v2.js
```

### Flutter Tests Failing

**Problem:** `PathProvider` errors

**Solution:**
```bash
# Clean and rebuild
cd terrain_iq_dashcam
flutter clean
flutter pub get
flutter test
```

### CSV Format Errors

**Problem:** Column count mismatch

**Check:**
1. CSV header has 16 columns
2. All data rows have 16 values
3. No extra commas or line breaks
4. Empty values are represented as empty strings, not null

### Upload Failures

**Problem:** Multipart upload fails

**Check:**
1. Server is running and accessible
2. Files exist and are readable
3. File paths are correct
4. Content-Type headers are set correctly

## Continuous Integration

### GitHub Actions Example

```yaml
name: CSV Upload Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.5'

      - name: Run Tests
        run: ./test_csv_upload_e2e.sh
```

## Development Workflow

### Adding New CSV Columns

1. Update `DataLoggerService._csvHeaders` in `data_logger_service.dart`
2. Update `logDataPoint()` method to include new data
3. Add test case in `data_logger_service_test.dart`
4. Update validation in `test_server.js`
5. Run tests: `./test_csv_upload_e2e.sh`

### Modifying Upload Format

1. Update server endpoint in `server_v2.js`
2. Update client code in `server_service.dart`
3. Add test case in `test_server.js`
4. Add integration test in `server_service_csv_test.dart`
5. Run tests: `./test_csv_upload_e2e.sh`

## Performance Benchmarks

Typical test execution times:

| Test Suite | Duration | Notes |
|------------|----------|-------|
| DataLoggerService tests | 5-10s | Includes file I/O |
| ServerService CSV tests | 3-5s | Mock file operations |
| Server endpoint tests | 10-15s | Requires server running |
| End-to-end suite | 30-45s | Complete workflow |

## Best Practices

1. **Run tests before committing**
   ```bash
   ./test_csv_upload_e2e.sh
   ```

2. **Keep tests fast**
   - Use small test files when possible
   - Mock external dependencies
   - Clean up resources

3. **Test edge cases**
   - Empty CSV files
   - Missing columns
   - Invalid data types
   - Very large files

4. **Maintain test data**
   - Keep sample CSV files up to date
   - Document expected formats
   - Version control test data

## Additional Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Node.js Testing Best Practices](https://github.com/goldbergyoni/nodebestpractices#3-code-patterns-and-style-practices)
- [CSV Format Specification](https://tools.ietf.org/html/rfc4180)
- [Multipart Form Data](https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2)

## Support

For issues or questions:
1. Check this documentation
2. Review test output and logs
3. Check server logs: `/tmp/terrainiq_server.log`
4. Review test report file

## Changelog

**2025-10-11**
- Initial test suite creation
- Added DataLoggerService unit tests
- Added ServerService integration tests
- Created server endpoint tests
- Developed end-to-end test automation
- Generated documentation
