# How to View CSVs in Relation to Videos

## File Association Structure

Each video recording has 3 associated files that share the same base name:

```
recording_1760223000000.mp4    ← Video file
recording_1760223000000.csv    ← Sensor data (accelerometer, gyro, GPS)
recording_1760223000000.json   ← Metadata (device info, timestamps, etc.)
```

**Key Point:** The CSV file has the **exact same name** as the video, just with `.csv` extension instead of `.mp4`

---

## 📁 File Locations

### On Device (iOS/Android)
```
App Documents/
  └── videos/
      ├── recording_1760223000000.mp4
      ├── recording_1760223000000.csv
      └── recording_1760223000000.json
```

### On Server (After Upload)
```
mock_server/
  ├── uploads/
  │   └── recording_1760223000000.mp4     ← Videos
  └── data/
      ├── recording_1760223000000.csv     ← CSV files
      └── recording_1760223000000.json    ← Metadata
```

---

## 🎥 Viewing Options

### Option 1: Web Viewer (Recommended) 📺

**Start the server:**
```bash
cd mock_server
node server_v2.js
```

**Open in browser:**
```
http://localhost:3000/viewer.html
```

**Features:**
- ✅ Watch videos directly in browser
- ✅ See CSV data preview side-by-side
- ✅ View metadata information
- ✅ Download video, CSV, or metadata
- ✅ Auto-refresh every 10 seconds

### Option 2: Command Line Listing 📋

**List all recordings with their files:**
```bash
cd mock_server
node list_files.js
```

**Output example:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. recording_1760223000000
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎥 Video:    ✓ recording_1760223000000.mp4 (5.23 MB)
   Path:     /path/to/uploads/recording_1760223000000.mp4
📊 CSV:      ✓ recording_1760223000000.csv (12.45 KB, 120 rows)
   Path:     /path/to/data/recording_1760223000000.csv
   Preview:
   timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z...
   2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000...
📋 Metadata: ✓ recording_1760223000000.json (2.13 KB)
   Path:     /path/to/data/recording_1760223000000.json
```

### Option 3: Direct File Access 📂

**Download CSV via browser:**
```
http://localhost:3000/data/recording_1760223000000.csv
```

**Download video via browser:**
```
http://localhost:3000/videos/recording_1760223000000.mp4
```

**Download metadata:**
```
http://localhost:3000/data/recording_1760223000000.json
```

### Option 4: File Explorer 🗂️

**On macOS/Linux:**
```bash
# Navigate to server data directory
cd mock_server
open data/              # Opens in Finder/File Manager
open uploads/           # Opens video directory
```

**On Windows:**
```cmd
cd mock_server
explorer data
explorer uploads
```

---

## 📊 CSV Data Format

### CSV Columns (16 total)

| Column | Description | Example | Precision |
|--------|-------------|---------|-----------|
| `timestamp` | ISO 8601 timestamp | `2025-10-11T10:00:00.000Z` | - |
| `accel_x` | Accelerometer X-axis | `1.0000` | 4 decimals |
| `accel_y` | Accelerometer Y-axis | `2.0000` | 4 decimals |
| `accel_z` | Accelerometer Z-axis | `3.0000` | 4 decimals |
| `gyro_x` | Gyroscope X-axis | `0.1000` | 4 decimals |
| `gyro_y` | Gyroscope Y-axis | `0.2000` | 4 decimals |
| `gyro_z` | Gyroscope Z-axis | `0.3000` | 4 decimals |
| `roughness` | Road roughness score | `0.5000` | 4 decimals |
| `roughness_level` | Roughness category | `smooth` | - |
| `orientation` | Device orientation | `portrait` | - |
| `is_moving` | Movement status | `true` | - |
| `latitude` | GPS latitude | `37.774900` | 6 decimals |
| `longitude` | GPS longitude | `-122.419400` | 6 decimals |
| `altitude` | Elevation in meters | `100.00` | 2 decimals |
| `speed_mps` | Speed in m/s | `10.00` | 2 decimals |
| `accuracy` | GPS accuracy in meters | `5.00` | 2 decimals |

### Sample CSV Content

```csv
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00
2025-10-11T10:00:00.100Z,1.1000,2.1000,3.1000,0.1100,0.2100,0.3100,0.5100,smooth,portrait,true,37.775000,-122.419300,100.10,10.10,5.10
2025-10-11T10:00:00.200Z,1.2000,2.2000,3.2000,0.1200,0.2200,0.3200,0.5200,rough,portrait,true,37.775100,-122.419200,100.20,10.20,5.20
```

**Data collection rate:** Every 100ms (10 rows per second)

---

## 🔍 Finding Your CSV Files

### On Physical Device

**iOS (via Xcode):**
1. Connect device
2. Open Xcode → Window → Devices and Simulators
3. Select your device
4. Find your app
5. Download container → Browse to `Documents/videos/`

**Android (via adb):**
```bash
# List files
adb shell run-as com.example.terrain_iq_dashcam ls files/videos/

# Pull CSV file
adb shell run-as com.example.terrain_iq_dashcam cat files/videos/recording_*.csv > local_file.csv
```

### On iOS Simulator

**Path:**
```
~/Library/Developer/CoreSimulator/Devices/
  [DEVICE-ID]/data/Containers/Data/Application/
  [APP-ID]/Documents/videos/
```

**Find it quickly:**
```bash
find ~/Library/Developer/CoreSimulator -name "*.csv" -type f
```

---

## 💡 Viewing Tips

### 1. Use Web Viewer for Best Experience

The web viewer shows:
- Video playback
- CSV data table (first 10 rows)
- Row count and column count
- Download buttons for all files
- Real-time updates

### 2. Open CSV in Spreadsheet Software

**Excel / Numbers / Google Sheets:**
- Download CSV from web viewer
- Open in your favorite spreadsheet app
- Create charts from sensor data
- Analyze GPS coordinates
- Filter by roughness levels

### 3. Programmatic Access

**Python example:**
```python
import pandas as pd

# Read CSV
df = pd.read_csv('recording_1760223000000.csv')

# Show summary
print(df.describe())

# Plot accelerometer data
import matplotlib.pyplot as plt
df[['accel_x', 'accel_y', 'accel_z']].plot()
plt.show()

# Plot GPS route
plt.plot(df['longitude'], df['latitude'])
plt.xlabel('Longitude')
plt.ylabel('Latitude')
plt.title('GPS Route')
plt.show()
```

**JavaScript example:**
```javascript
// Fetch CSV via API
const response = await fetch('http://localhost:3000/data/recording_1760223000000.csv');
const csvText = await response.text();

// Parse CSV
const lines = csvText.split('\n');
const headers = lines[0].split(',');
const data = lines.slice(1).map(line => {
    const values = line.split(',');
    return headers.reduce((obj, header, i) => {
        obj[header] = values[i];
        return obj;
    }, {});
});

console.log(`Loaded ${data.length} data points`);
```

---

## 🎯 Quick Reference

| Task | Command/URL |
|------|-------------|
| View all recordings | `http://localhost:3000/viewer.html` |
| List files in terminal | `node mock_server/list_files.js` |
| Download specific CSV | `http://localhost:3000/data/<filename>.csv` |
| View server home | `http://localhost:3000` |
| API: Get all recordings | `http://localhost:3000/api/recordings` |

---

## 📝 Example Workflow

1. **Record a video** on the device (CSV automatically created)
2. **Upload to server** (video, CSV, and metadata are uploaded together)
3. **Open web viewer** at `http://localhost:3000/viewer.html`
4. **Click on a recording** to see:
   - Video player
   - CSV data preview
   - Metadata info
   - Download buttons
5. **Download CSV** for analysis in Excel/Python
6. **Analyze sensor data** to identify road conditions

---

## 🚀 Next Steps

- **Analyze Data:** Use Python/Excel to analyze road roughness patterns
- **Visualize Routes:** Plot GPS coordinates on a map
- **Machine Learning:** Train models on sensor data for automated detection
- **Export Reports:** Generate PDF reports with video thumbnails and data summaries

---

**Questions?** Check the main documentation or run the test suite to verify everything is working!
