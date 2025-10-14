# How CSV Files Relate to Videos - Quick Summary

## 📹 The Relationship

**Each video recording creates 3 files with the SAME base name:**

```
recording_1760223000000.mp4    ← Your video
recording_1760223000000.csv    ← Sensor data collected DURING the video
recording_1760223000000.json   ← Metadata about the recording
```

**The CSV contains what happened WHILE the video was recording:**
- Accelerometer readings (how the phone moved)
- Gyroscope readings (how the phone rotated)
- GPS coordinates (where you were)
- Road roughness calculations (how bumpy the road was)
- Timestamps (synced to the video timeline)

## 🎬 Example: 30-Second Video

```
Video: recording_123.mp4
  - Duration: 30 seconds
  - Shows the road/scene

CSV: recording_123.csv
  - 300 rows of data (10 readings per second)
  - Row 1: data at 0.0s (start of video)
  - Row 100: data at 10.0s (10 seconds into video)
  - Row 300: data at 30.0s (end of video)
  - Each row shows:
    * How much the phone was shaking (accelerometer)
    * Where you were (GPS)
    * How rough the road was (calculated value)
```

## 🔍 Viewing Together

### Option 1: Web Viewer (Best!) 📺

```bash
cd mock_server
node server_v2.js
```

Then open: **http://localhost:3000/viewer.html**

**You'll see:**
```
┌─────────────────────────────────────────┐
│  VIDEO PLAYER                           │
│  (Watch the recording)                  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  CSV DATA TABLE                         │
│  timestamp    | accel_x | latitude      │
│  10:00:00.0   | 1.0000  | 37.774900     │
│  10:00:00.1   | 1.1000  | 37.775000     │
│  10:00:00.2   | 1.2000  | 37.775100     │
└─────────────────────────────────────────┘
```

### Option 2: Terminal List

```bash
cd mock_server
node list_files.js
```

**Output:**
```
1. recording_1760223000000
━━━━━━━━━━━━━━━━━━━━━━━━━━
🎥 Video:    ✓ recording_1760223000000.mp4 (5.23 MB)
📊 CSV:      ✓ recording_1760223000000.csv (12.45 KB, 300 rows)
📋 Metadata: ✓ recording_1760223000000.json (2.13 KB)
```

## 📊 What's In The CSV?

| Time in Video | What CSV Shows |
|---------------|----------------|
| 0:00 | Starting GPS coordinates, phone flat and still |
| 0:05 | Phone started moving, detecting vibrations |
| 0:10 | Bumpy section - high roughness values |
| 0:15 | Smooth section - low roughness values |
| 0:20 | Sharp turn - gyroscope shows rotation |
| 0:30 | End GPS coordinates |

## 💡 Use Cases

**Scenario 1: Road Quality Analysis**
- Watch video at timestamp 10s → see bumpy road
- Look at CSV row 100 (10s) → see roughness = 2.5 (high)
- Confirm: video shows bumps, data proves it

**Scenario 2: GPS Route Tracking**
- CSV column "latitude" and "longitude"
- Plot on map to see exact route driven
- Match to video to see what each location looks like

**Scenario 3: Accident Analysis**
- Watch video moment of impact
- Check CSV at that timestamp
- See exact acceleration forces and speed

## ⚡ Quick Access

```bash
# Start server
cd mock_server && node server_v2.js

# View in browser
open http://localhost:3000/viewer.html

# Download CSV for Excel
open http://localhost:3000/data/recording_1760223000000.csv

# List all files
node list_files.js
```

## 📋 File Locations

**On Device:**
```
App Documents/videos/
  ├── recording_1760223000000.mp4
  ├── recording_1760223000000.csv
  └── recording_1760223000000.json
```

**After Upload:**
```
mock_server/
  ├── uploads/
  │   └── recording_1760223000000.mp4    ← Video
  └── data/
      ├── recording_1760223000000.csv    ← CSV (sensor data)
      └── recording_1760223000000.json   ← Metadata
```

## 🎯 Key Points

1. **Same Name** = Files belong together
2. **CSV timestamps** = Video timeline
3. **10 rows/second** = Very detailed sensor data
4. **Web viewer** = See both together
5. **Download CSV** = Analyze in Excel/Python

---

**More Details:** See `HOW_TO_VIEW_CSV_DATA.md` for complete guide
