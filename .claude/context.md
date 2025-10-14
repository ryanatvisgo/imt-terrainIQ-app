# TerrainIQ Dashcam - Quick Context

**Last Updated:** 2025-10-13

## Project Type
Cross-platform mobile dashcam application built with Flutter

## Core Purpose
Video recording app with GPS tracking, sensor data logging (CSV), file management, and storage optimization for iOS and Android devices

## Current Status
**Version:** 1.0.0+1
**Stage:** Active Development
**Primary Focus:** CSV data logging, upload automation, and test verification

## Architecture Pattern
**Flutter Mobile App**
```
UI Layer (Widgets) → Services Layer → Platform APIs
     ↓                    ↓              ↓
  Screens/Widgets    Camera/Storage   iOS/Android
```

## Key Technologies
- **Framework:** Flutter 3.9.2 (Dart)
- **State Management:** Provider pattern
- **Camera:** camera package (0.10.6)
- **Storage:** path_provider, shared_preferences
- **Location:** geolocator (13.0.1), geocoding (3.0.0)
- **Permissions:** permission_handler (11.3.1)
- **Sensors:** sensors_plus (6.0.1) - accelerometer, gyroscope
- **Data Export:** csv (6.0.0) - sensor data logging
- **Network:** http (1.2.2), connectivity_plus (6.0.5)

## Project Structure
```
terrain_iq_dashcam/
├── lib/
│   ├── main.dart                       # App entry point
│   ├── models/                         # Data models
│   │   └── video_recording.dart
│   ├── screens/                        # UI screens
│   │   ├── dashcam_screen.dart
│   │   └── simple_dashcam_screen.dart
│   ├── services/                       # Business logic
│   │   ├── camera_service.dart
│   │   ├── permission_service.dart
│   │   ├── storage_service.dart
│   │   ├── data_logger_service.dart    # CSV sensor data logging
│   │   ├── server_service.dart         # Server upload & heartbeat
│   │   └── device_logger_service.dart  # Device logging
│   └── widgets/                        # Reusable UI components
├── test/                               # Test suite
│   └── services/
│       ├── data_logger_service_test.dart     # CSV generation tests
│       └── server_service_csv_test.dart      # Upload integration tests
├── mock_server/                        # Node.js test server
│   ├── server_v2.js                    # Upload server with CSV support
│   ├── test_server.js                  # Server endpoint tests
│   ├── list_files.js                   # CLI file listing tool
│   └── public/
│       └── viewer.html                 # Web viewer for videos + CSVs
├── test_csv_upload_e2e.sh             # End-to-end test automation
├── HOW_TO_VIEW_CSV_DATA.md            # CSV viewing guide
├── TEST_DOCUMENTATION.md               # Test suite documentation
└── pubspec.yaml                        # Dependencies
```

## Implemented Features
- Camera integration with video recording
- Permission management (camera, mic, location, storage)
- Local file storage with automatic organization
- Recording controls with visual indicators
- Recording list and playback
- Configurable storage limits with auto-cleanup
- Material Design UI
- **CSV Sensor Data Logging** (NEW)
  - Accelerometer & gyroscope data collection
  - GPS tracking with coordinates
  - Road roughness detection
  - 16-column CSV format with 10Hz sampling rate
- **Server Upload System** (NEW)
  - Chunked video upload with resume support
  - Automatic CSV + metadata upload alongside videos
  - WiFi-only mode with upload queue management
  - Heartbeat monitoring
- **Comprehensive Test Automation** (NEW)
  - 26 automated tests (100% pass rate)
  - Flutter unit tests for CSV generation
  - Server endpoint tests
  - Integration tests for upload workflow
  - End-to-end test automation script
- **Web-Based Viewer** (NEW)
  - View uploaded videos with CSV data side-by-side
  - CSV data preview with download options
  - Real-time file listing and monitoring

## In Progress
- Settings screen (video quality, storage management)
- Video playback within app
- Video sharing functionality

## Planned
- Background recording
- Cloud sync integration
- Crash detection with auto-recording
- Speed-based recording features

## Development Platforms
- **Primary:** iOS (iPhone testing)
- **Secondary:** Android
- **Supported:** macOS, Linux, Windows, Web

## Git Status
**Repository:** Not initialized (directory is not a Git repo)
**Recommendation:** Initialize Git for version control

## Critical Notes
- App requires physical device for camera testing (not emulator)
- iOS requires Xcode and code signing with Apple ID
- Video files stored in app documents directory
- Default storage limit: 10GB with auto-delete
- Background recording temporarily disabled (plugin compatibility)

## Quick Commands
```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Check for issues
flutter doctor

# Build release
flutter build apk --release     # Android
flutter build ios --release     # iOS

# Testing
flutter test                                     # Run all tests
flutter test test/services/data_logger_service_test.dart  # CSV tests
./test_csv_upload_e2e.sh                        # Complete test suite

# Server
cd mock_server
node server_v2.js                               # Start upload server
node list_files.js                              # List uploaded files
# Web viewer: http://localhost:3000/viewer.html
```

## CSV Data & File Association
**File Naming Convention:**
- Video: `recording_1760223000000.mp4`
- CSV: `recording_1760223000000.csv` (same base name)
- Metadata: `recording_1760223000000.json` (same base name)

**CSV Format:** 16 columns with sensor data
- Timestamp, 3-axis accelerometer, 3-axis gyroscope
- Road roughness (score + level)
- Device orientation, movement status
- GPS (latitude, longitude, altitude, speed, accuracy)
- Sampling rate: 10Hz (every 100ms)

**Viewing CSVs:**
- Web viewer: http://localhost:3000/viewer.html
- CLI tool: `node mock_server/list_files.js`
- Direct access: http://localhost:3000/data/<filename>.csv
- See `HOW_TO_VIEW_CSV_DATA.md` for complete guide

## Testing
**Test Suite:** 26 automated tests (100% pass rate verified 2025-10-11)
- 10 CSV generation tests (DataLoggerService)
- 9 CSV upload integration tests (ServerService)
- 7 server endpoint tests (Node.js)

**Run Tests:**
```bash
./test_csv_upload_e2e.sh  # Complete automated test suite
```

## Comprehensive Documentation

**NEW:** Complete UI/UX and API documentation now available:

1. **UI_REQUIREMENTS_MATRIX.md** - Comprehensive feature matrix
   - Screen-by-screen breakdown of all UI features
   - UI vs. background process categorization
   - User interaction flows and component inventory
   - Background services matrix with timers and dependencies

2. **API_SPECIFICATION.md** - Complete REST API & MQTT documentation
   - All REST endpoints with request/response schemas
   - MQTT protocol specification (topics, payloads, QoS)
   - Data models (Metadata, CSV, Hazard schemas)
   - Error handling and authentication guidelines

3. **UI_DESIGN_SYSTEM.md** - Visual design language
   - Color system (primary, semantic, safety status)
   - Typography scale (display, headline, body, caption)
   - Spacing & layout patterns (8pt grid system)
   - Component library (buttons, indicators, cards)
   - Animation & motion guidelines
   - Iconography with usage map

4. **SCREEN_ARCHITECTURE.md** - Screen implementation details
   - Navigation architecture and hierarchy
   - Widget tree diagrams for each screen
   - State management patterns (Provider)
   - Service dependencies and interaction matrix
   - Performance optimization strategies

## Entry Points for AI Assistance
1. Read `.claude/analysis.md` for system overview
2. Read `.claude/AGENT_RULES.md` for behavioral guidelines
3. Review `terrain_iq_dashcam/README.md` for setup instructions
4. Check `terrain_iq_dashcam/REQUIREMENTS.md` for functional requirements
5. Check `terrain_iq_dashcam/UI_REQUIREMENTS_MATRIX.md` for UI feature matrix
6. Check `terrain_iq_dashcam/API_SPECIFICATION.md` for API documentation
7. Check `terrain_iq_dashcam/UI_DESIGN_SYSTEM.md` for design guidelines
8. Check `terrain_iq_dashcam/SCREEN_ARCHITECTURE.md` for screen implementation
9. Check `HOW_TO_VIEW_CSV_DATA.md` for CSV viewing guide
10. Check `TEST_DOCUMENTATION.md` for testing information
11. Check `terrain_iq_dashcam/lib/services/` for service implementation
