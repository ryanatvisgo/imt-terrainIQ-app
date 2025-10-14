# Quick Test Guide - CSV Upload Verification

## TL;DR - Run All Tests

```bash
cd terrain_iq_dashcam
./test_csv_upload_e2e.sh
```

That's it! The script handles everything.

---

## Manual Testing (If You Prefer)

### 1. Test Server Endpoints

```bash
# Terminal 1: Start the server
cd terrain_iq_dashcam/mock_server
node server_v2.js

# Terminal 2: Run server tests
cd terrain_iq_dashcam/mock_server
node test_server.js
```

**Expected Output:**
```
✅ Test 1: Server Heartbeat
✅ Test 2: Upload Registration with CSV
✅ Test 3: CSV File Validation
✅ Test 4: Large CSV Upload
✅ Test 5: CSV Column Consistency
✅ Test 6: Multiple File Upload
✅ Test 7: CSV Data Integrity

📊 Total Tests: 7
✅ Passed: 7
```

### 2. Test CSV Generation (Flutter)

```bash
cd terrain_iq_dashcam
flutter test test/services/data_logger_service_test.dart
```

**Expected Output:**
```
00:02 +8: All tests passed!
```

### 3. Test CSV Upload Integration (Flutter)

```bash
cd terrain_iq_dashcam
flutter test test/services/server_service_csv_test.dart
```

**Expected Output:**
```
00:01 +9: All tests passed!
```

---

## What Gets Tested?

| Component | What's Verified |
|-----------|----------------|
| **CSV Generation** | File creation, data formatting, GPS points |
| **CSV Format** | 16 columns, proper headers, numeric precision |
| **CSV Validation** | Column consistency, data integrity |
| **Server Upload** | Multipart upload, file association |
| **Server Endpoints** | Registration, chunks, completion |

---

## Common Issues

### "Server is not running"
**Solution:** Start server in separate terminal:
```bash
cd terrain_iq_dashcam/mock_server
node server_v2.js
```

### "Port 3000 already in use"
**Solution:** Find and kill the process:
```bash
lsof -i :3000
kill -9 <PID>
```

### Tests fail with PathProvider errors
**Solution:** Clean and rebuild:
```bash
cd terrain_iq_dashcam
flutter clean
flutter pub get
flutter test
```

---

## Verify CSV Upload Manually

### Step 1: Start Server
```bash
cd terrain_iq_dashcam/mock_server
node server_v2.js
```

### Step 2: Create Test Files

Create `test_metadata.json`:
```json
{
  "device": {"model": "Test Device"},
  "video": {
    "filename": "test.mp4",
    "size_bytes": 1024000
  }
}
```

Create `test_sensors.csv`:
```csv
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00
```

### Step 3: Register Upload
```bash
curl -X POST http://localhost:3000/upload/register \
  -F "metadata=@test_metadata.json" \
  -F "csv=@test_sensors.csv"
```

**Expected Response:**
```json
{
  "success": true,
  "upload_id": "abc123...",
  "chunk_size": 5242880,
  "total_chunks": 1
}
```

### Step 4: Check Server Data Directory
```bash
ls terrain_iq_dashcam/mock_server/metadata/
ls terrain_iq_dashcam/mock_server/data/
```

You should see your uploaded CSV and metadata files.

---

## Test File Locations

```
terrain_iq_dashcam/
├── test_csv_upload_e2e.sh          # 🔵 Run this for complete test
├── QUICK_TEST_GUIDE.md             # ⬅️ You are here
├── TEST_DOCUMENTATION.md           # Full documentation
├── test/
│   └── services/
│       ├── data_logger_service_test.dart      # CSV generation tests
│       └── server_service_csv_test.dart       # CSV upload tests
└── mock_server/
    ├── server_v2.js                # Server to test against
    └── test_server.js              # Server endpoint tests
```

---

## Quick Verification Checklist

- [ ] Server starts successfully on port 3000
- [ ] Server responds to heartbeat
- [ ] CSV files are created with 16 columns
- [ ] CSV data has proper numeric precision
- [ ] Upload registration returns upload_id
- [ ] CSV files appear in server data directory
- [ ] All test suites pass

---

## Next Steps After Testing

Once all tests pass, you can:

1. **Run the app** and verify CSV creation during recording
2. **Check actual CSV files** in app documents directory
3. **Test real upload** from device to server
4. **Verify CSV data** in server data directory
5. **Analyze sensor data** from the CSV files

---

## Need Help?

1. Check `TEST_DOCUMENTATION.md` for detailed info
2. Review server logs: `/tmp/terrainiq_server.log`
3. Check test report: `test_report_*.txt`
4. Run individual tests to isolate issues
