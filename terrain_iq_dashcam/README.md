# TerrainIQ Dashcam

A cross-platform mobile dashcam app built with Flutter that provides intelligent video recording with real-time sensor data logging, GPS tracking, automatic upload capabilities, and comprehensive error tracking for road intelligence analysis.

## Features

### ✅ Implemented
- **Camera Integration**: Full camera functionality with video recording
- **Permission Management**: Handles camera, microphone, location, and storage permissions
- **File Management**: Local storage with automatic file organization
- **Recording Controls**: Start/stop recording with visual indicators
- **Recording List**: View and manage recorded videos (Sending/Sent tabs)
- **Storage Limits**: Configurable storage limits with automatic cleanup
- **Material Design**: Modern, intuitive UI
- **CSV Data Logging**: Real-time sensor data tracking (accelerometer, gyroscope, roughness, GPS)
- **Auto-Record on Motion**: Automatic recording based on vehicle movement detection
- **Server Upload System**: Automatic video and data upload with WiFi-only mode
- **Device Logging System**: Comprehensive error tracking and crash reporting
- **Video Playback**: Play recorded videos within the app
- **Metadata Generation**: JSON metadata files with trip summaries

### 🚧 In Progress
- **Settings Screen**: Video quality, storage management, and app preferences
- **Video Sharing**: Share recordings via various platforms

### 🔄 Planned
- **Background Recording**: Continuous recording when app is backgrounded
- **Cloud Sync**: Optional cloud storage integration
- **Crash Detection**: Automatic recording triggers
- **Speed Tracking**: Speed-based recording features

## Getting Started

### Prerequisites
- Flutter 3.35.5 or higher
- Android Studio or VS Code
- Android SDK (for Android development)
- Xcode (for iOS development)
- CocoaPods (for iOS dependencies)

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/ryan-bookmarked/platform/intellimass/TerrainIQ/terrain_iq_dashcam
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Testing on Developer iPhone

### Prerequisites for iOS Development
- **Xcode** installed from App Store (free, ~15GB download)
- **CocoaPods** installed via Homebrew: `brew install cocoapods`
- **iPhone** connected via USB cable
- **Apple ID** for code signing

### Step-by-Step iPhone Setup

#### 1. Install Xcode
```bash
# Open App Store and search for "Xcode"
open -a "App Store"
# Download and install Xcode (this takes 30-60 minutes)
```

#### 2. Install CocoaPods
```bash
# Using Homebrew (recommended)
brew install cocoapods

# Alternative: Using RubyGems
sudo gem install cocoapods
```

#### 3. Set up Xcode
```bash
# Set Xcode command line tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept Xcode license and install components
sudo xcodebuild -runFirstLaunch
```

#### 4. Connect and Pair iPhone
1. **Connect iPhone** via USB cable
2. **Trust computer** when prompted on iPhone
3. **Open Xcode**
4. Go to **Window** → **Devices and Simulators** (or `Shift+Cmd+2`)
5. Click on your iPhone in the left sidebar
6. Click **"Use for Development"**
7. **Sign in with Apple ID** when prompted
8. **Trust computer** on iPhone if asked again

#### 5. Verify Setup
```bash
# Check if iPhone is detected
flutter devices

# You should see something like:
# iPhone (mobile) • [device-id] • ios • iOS 17.x (emulator)
```

#### 6. Run on iPhone
```bash
# Navigate to project directory
cd /Users/ryan-bookmarked/platform/intellimass/TerrainIQ/terrain_iq_dashcam

# Run on iPhone
flutter run -d ios

# Or specify your device ID
flutter run -d [your-device-id]
```

### What to Expect on iPhone

#### First Launch:
1. **Code signing prompt** - Xcode will ask to sign the app
2. **Permission prompts** - iPhone will ask for:
   - Camera access
   - Microphone access
   - Location access (if enabled)
3. **Trust developer** - Go to Settings → General → VPN & Device Management → Developer App → Trust

#### App Features on Real Device:
- ✅ **Live camera preview** (not available in emulator)
- ✅ **Actual video recording** with audio
- ✅ **Video files saved** to iPhone Photos app
- ✅ **GPS location** embedded in recordings
- ✅ **Real-time recording** indicators

### Troubleshooting iPhone Setup

#### iPhone Not Detected:
```bash
# Check Flutter doctor
flutter doctor

# Common issues:
# - Xcode not fully installed
# - iPhone not trusted
# - USB cable not data-capable
# - iPhone locked during pairing
```

#### Code Signing Issues:
1. **Open Xcode**
2. Go to **Preferences** → **Accounts**
3. **Add your Apple ID**
4. **Download certificates** if prompted
5. **Try running again**

#### Permission Issues:
- Go to **iPhone Settings** → **Privacy & Security**
- **Camera** → Allow TerrainIQ Dashcam
- **Microphone** → Allow TerrainIQ Dashcam
- **Location Services** → Allow TerrainIQ Dashcam

#### App Won't Launch:
1. **Trust the developer app**:
   - Settings → General → VPN & Device Management
   - Find "Developer App" section
   - Tap your Apple ID → Trust
2. **Restart the app** after trusting

### Development Workflow

#### Hot Reload on iPhone:
```bash
# After initial run, use hot reload
r  # Press 'r' in terminal for hot reload
R  # Press 'R' for hot restart
q  # Press 'q' to quit
```

#### Debugging:
- **Flutter DevTools** automatically opens in browser
- **Xcode console** shows device logs
- **iPhone Settings** → **Privacy & Security** → **Developer** for debugging options

### Alternative Testing Methods

#### iOS Simulator (Limited):
```bash
# List available simulators
flutter emulators

# Launch iPhone simulator
flutter emulators --launch apple_ios_simulator

# Run on simulator (no camera access)
flutter run -d ios
```

#### Build for Distribution:
```bash
# Build iOS app for TestFlight/App Store
flutter build ios --release

# Archive in Xcode for distribution
open ios/Runner.xcworkspace
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**iOS (requires macOS and Xcode):**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                      # App entry point with global error handlers
├── models/
│   └── video_recording.dart       # Video recording data model
├── screens/
│   ├── splash_screen.dart         # Splash screen with log upload
│   └── simple_dashcam_screen.dart # Main dashcam screen
└── services/
    ├── camera_service.dart        # Camera functionality
    ├── storage_service.dart       # Local file storage management
    ├── permission_service.dart    # Permission management
    ├── motion_service.dart        # Accelerometer/gyroscope motion detection
    ├── data_logger_service.dart   # CSV sensor data logging
    ├── device_logger_service.dart # Device-level error/event logging
    ├── server_service.dart        # Server communication & uploads
    └── metadata_service.dart      # JSON metadata generation
```

## Key Dependencies

- **camera**: Camera functionality and video recording
- **permission_handler**: Permission management
- **geolocator**: GPS location tracking
- **sensors_plus**: Accelerometer and gyroscope data
- **path_provider**: File system access
- **device_info_plus**: Device information
- **connectivity_plus**: Network connectivity detection
- **http**: Server communication
- **csv**: CSV file generation
- **video_player**: Video playback
- **provider**: State management

## Data Logging & Upload System

### CSV Sensor Data Tracking

Each video recording generates a corresponding CSV file with real-time sensor data logged at 10Hz (every 100ms):

**CSV Columns:**
- `timestamp` - ISO 8601 timestamp
- `accel_x/y/z` - Accelerometer readings (m/s²)
- `gyro_x/y/z` - Gyroscope readings (rad/s)
- `roughness` - Calculated road roughness metric
- `roughness_level` - Text classification (Smooth/Moderate/Rough/Very Rough)
- `orientation` - Device orientation (Landscape/Portrait/etc)
- `is_moving` - Vehicle movement detection
- `latitude/longitude/altitude` - GPS coordinates (sampled every 1 second)
- `speed_mps` - Speed in meters per second
- `accuracy` - GPS accuracy in meters

### File Organization

```
app_documents/
├── videos/
│   ├── recording_1234567890.mp4       # Video file
│   ├── recording_1234567890.csv       # Sensor data
│   └── recording_1234567890.json      # Metadata summary
└── device_logs/
    ├── pending/
    │   └── log_20250110.jsonl         # Pending device logs
    └── uploaded/
        └── log_20250109.jsonl         # Uploaded logs (kept 30 days)
```

### Device-Level Logging

The app maintains independent device logs that track:
- **App Lifecycle**: Startup, initialization, crashes
- **Recording Events**: Start/stop with timestamps and metadata
- **Upload Activity**: Success/failure with durations
- **Errors & Exceptions**: Full stack traces with context
- **Device Info**: Model, OS version, platform

**Log Format:** JSON Lines (`.jsonl`) for easy parsing and streaming

**Log Rotation:** Automatic rotation when files exceed 1MB

**Upload Priority:** Logs are uploaded on app startup BEFORE main app initialization to ensure crash logs from previous sessions are captured

### Server Upload System

**Features:**
- WiFi-only mode (configurable)
- Automatic queue management
- Retry logic with countdown
- Upload progress tracking
- Multipart form uploads (video + CSV + metadata + logs)

**Endpoints:**
- `POST /upload` - Upload video recordings with associated data
- `POST /logs` - Upload device logs
- `POST /heartbeat` - Status updates (every 60s when recording, 5min when idle)

**Upload Flow:**
1. Recording completes → Added to upload queue
2. Check connectivity (WiFi required if enabled)
3. Upload video, CSV, and metadata as multipart request
4. Mark as uploaded, optionally delete local file
5. On failure: Keep in queue, retry after 60 seconds

**Log Upload Flow:**
1. App starts → Splash screen loads
2. Check for pending logs in `device_logs/pending/`
3. Upload all pending logs (timeout: 10 seconds)
4. Move uploaded logs to `uploaded/` folder
5. Continue app initialization

### Auto-Record on Motion

The app can automatically start/stop recording based on vehicle motion:

**Triggers:**
- **Start**: Device is moving AND in valid recording orientation (landscape)
- **Stop**: Device is stationary OR invalid orientation for 30+ seconds

**Motion Detection:**
- Uses accelerometer magnitude to detect movement
- Orientation tracking to ensure proper mounting
- Configurable sensitivity thresholds

## Usage

### Basic Recording
1. **First Launch**: Grant all required permissions (camera, microphone, location, storage)
2. **Manual Recording**: Tap the red record button to start/stop recording
3. **Auto-Record**: Toggle "Auto-Record on Motion" to automatically record when vehicle is moving
4. **View Recordings**: Switch to "Recordings" tab with two sections:
   - **Sending**: Videos queued for upload or currently uploading
   - **Sent**: Successfully uploaded videos organized by month

### Recording Features
- **Picture-in-Picture**: During recording, swipe right on the small camera preview to view fullscreen
- **Upload Status**: Real-time upload progress with file size and percentage
- **Retry Logic**: Failed uploads automatically retry after 60 seconds
- **WiFi Mode**: Configure app to only upload on WiFi (recommended)

### Monitoring & Debugging
- Device logs are automatically uploaded on app startup
- View upload queue size in "Sending" tab badge
- Connection status indicator shows: Idle, Connecting, Uploading, or Error state

## Permissions Required

- **Camera**: For video recording
- **Microphone**: For audio recording
- **Location**: For GPS tracking with recordings
- **Storage**: For saving video files and logs
- **Motion Sensors**: For auto-record and road quality detection

## Development Notes

### Architecture
- **State Management**: Provider pattern for reactive state
- **Error Handling**: Global error handlers catch all Flutter and Dart exceptions
- **Logging Strategy**: Separate device logs from sensor data logs
- **Upload Strategy**: Queue-based with automatic retry and connectivity checking

### Data Storage
- Video files stored in app's documents directory: `videos/`
- Device logs stored separately: `device_logs/pending/` and `device_logs/uploaded/`
- Storage limits configurable (default: 10GB)
- Automatic cleanup of old uploaded logs (30+ days)

### Error Handling & Crash Reporting
The app implements comprehensive error tracking:

1. **Global Error Handlers** (`main.dart`):
   - `FlutterError.onError` - Catches Flutter framework errors
   - `runZonedGuarded` - Catches uncaught Dart exceptions
   - All errors logged with full stack traces

2. **Log Upload on Startup** (`splash_screen.dart`):
   - Runs BEFORE main app initialization
   - Uploads pending logs from previous session (including crashes)
   - Timeout-protected (10 seconds) to prevent blocking startup
   - Non-blocking: App continues even if upload fails

3. **Event Logging** (throughout app):
   - App startup and initialization
   - Recording start/stop with durations
   - Upload success/failure with error details
   - Service initialization failures
   - All exceptions with context

4. **Log Format** (JSON Lines):
   ```json
   {
     "timestamp": "2025-01-10T14:30:00.000Z",
     "device_id": "ABC123...",
     "event_type": "recording_started",
     "level": "info",
     "message": "Recording started: recording_1234567890",
     "metadata": {
       "file_name": "recording_1234567890",
       "is_auto_recording": false
     },
     "device_info": {
       "platform": "iOS",
       "model": "iPhone 15",
       "os_version": "17.2"
     }
   }
   ```

### Server Configuration
- **Base URL**: Configure in `ServerService._baseUrl` (default: `http://192.168.8.105:3000`)
- **Heartbeat Intervals**: 60s during recording, 300s when idle
- **Upload Timeout**: 5 minutes for video uploads, 30 seconds for log uploads
- **Retry Delay**: 60 seconds after upload failure

## Troubleshooting

### Build Issues
- Ensure Flutter is properly installed and configured
- Run `flutter doctor` to check for issues
- Clean build cache: `flutter clean && flutter pub get`
- iOS: Ensure CocoaPods is installed and run `pod install` in `ios/` directory

### Permission Issues
- Make sure to grant all required permissions
- On Android, check app settings for permission status
- On iOS, check Privacy & Security settings
- Motion sensors may require device to not be in low-power mode

### Camera Issues
- Ensure device has a working camera
- Check if another app is using the camera
- Restart the app if camera fails to initialize
- Check logs in `device_logs/pending/` for camera initialization errors

### Upload Issues
- **Videos stuck in "Sending" tab**:
  - Check WiFi connection if WiFi-only mode is enabled
  - View connection status indicator at top of Sending tab
  - Check device logs for upload errors
  - Verify server is running and accessible at configured URL

- **Logs not uploading**:
  - Logs upload on app startup (splash screen)
  - Check console output for "Splash: Found X pending log files"
  - Timeout is 10 seconds - may fail on slow connections
  - Logs remain in `pending/` folder until successfully uploaded

- **Server connection errors**:
  - Verify server URL in `ServerService._baseUrl`
  - Ensure server has endpoints: `/upload`, `/logs`, `/heartbeat`
  - Check firewall/network settings
  - Test server with: `curl http://YOUR_SERVER:3000/heartbeat`

### Auto-Record Issues
- **Not starting automatically**:
  - Enable "Auto-Record on Motion" toggle
  - Check device is in landscape orientation
  - Ensure device is actually moving (accelerometer threshold)
  - View motion status indicators (car icon and phone orientation)

- **Stopping unexpectedly**:
  - Device may have detected it's stationary
  - Check orientation - will stop if device is in portrait for 30+ seconds
  - Motion service requires movement above threshold

### Debugging Tips
- Enable Flutter DevTools: `flutter run` automatically opens DevTools in browser
- View device logs: Check `app_documents/device_logs/pending/` for detailed logs
- Console output: All services print debug messages with emojis for easy filtering:
  - 🔵 = Info/Debug
  - ✅ = Success
  - ❌ = Error
  - ⚠️ = Warning
  - 📤 = Upload related
  - 📝 = Logging related
  - 💓 = Heartbeat
  - 🚗 = Auto-record

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the TerrainIQ platform. All rights reserved.