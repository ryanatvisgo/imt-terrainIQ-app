# TerrainIQ Dashcam - System Analysis

**Generated:** 2025-10-10
**Version:** 1.0.0+1
**Platform:** Flutter (Dart)

---

## 📋 TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Core Components](#core-components)
4. [Data Flow](#data-flow)
5. [File Structure](#file-structure)
6. [Dependencies](#dependencies)
7. [Platform-Specific Implementation](#platform-specific-implementation)
8. [State Management](#state-management)
9. [Storage Strategy](#storage-strategy)
10. [Permission Handling](#permission-handling)
11. [Development Workflow](#development-workflow)
12. [Known Issues & Limitations](#known-issues--limitations)
13. [Future Roadmap](#future-roadmap)

---

## EXECUTIVE SUMMARY

**Project Name:** TerrainIQ Dashcam
**Type:** Cross-platform mobile application
**Primary Language:** Dart (Flutter framework)
**Supported Platforms:** iOS, Android, macOS, Linux, Windows, Web
**Primary Use Case:** Video dashcam with GPS tracking and intelligent storage management

### Key Features
- Real-time video recording with camera preview
- GPS location tracking and geocoding
- Automatic storage management with configurable limits
- Multi-platform support (iOS/Android focus)
- Material Design 3 UI with dark theme
- Permission management across platforms

### Current Development Stage
**Status:** Active Development
**Completed:** Camera integration, basic recording, file management
**In Progress:** GPS integration, settings UI, video playback
**Planned:** Background recording, cloud sync, crash detection

---

## ARCHITECTURE OVERVIEW

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Widgets)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Screens    │  │   Widgets    │  │    Theme     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│               State Management (Provider)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │CameraService │  │StorageService│  │PermService   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Platform Layer (Flutter Plugins)            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Camera     │  │  Geolocator  │  │Path Provider │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Native Platform APIs (iOS/Android)          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  AVFoundation│  │ CLLocation   │  │ File System  │  │
│  │  (iOS)       │  │ Services     │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Design Patterns

1. **Service Layer Pattern**: Business logic separated into service classes
2. **Provider Pattern**: State management using ChangeNotifier
3. **Repository Pattern**: Storage service abstracts file operations
4. **Observer Pattern**: Widgets listen to service state changes

---

## CORE COMPONENTS

### 1. CameraService (`lib/services/camera_service.dart`)

**Responsibility:** Manages camera initialization, video recording lifecycle

**Key Features:**
- Camera initialization with rear camera preference
- High-resolution video recording (ResolutionPreset.high)
- Audio recording enabled
- Recording state management
- File path generation with timestamps

**State Properties:**
```dart
- _controller: CameraController?      // Camera controller instance
- _cameras: List<CameraDescription>   // Available cameras
- _isRecording: bool                  // Recording status
- _isInitialized: bool                // Camera ready status
- _currentRecordingPath: String?      // Active recording path
```

**Public Methods:**
- `initializeCamera()` - Sets up camera controller
- `startRecording()` - Begins video recording
- `stopRecording()` - Ends recording and returns file path
- `toggleRecording()` - Convenience toggle method
- `dispose()` - Cleanup camera resources

**Error Handling:**
- Camera not available exception
- Camera already in use handling
- Initialization failure recovery
- Recording failure logging

### 2. StorageService (`lib/services/storage_service.dart`)

**Responsibility:** File management, storage limits, recording metadata

**Key Features:**
- Automatic storage limit enforcement (default: 10GB)
- Auto-delete oldest recordings when limit exceeded
- Recording list management with metadata
- Persistent settings via SharedPreferences
- Storage usage tracking

**State Properties:**
```dart
- _recordings: List<VideoRecording>   // Recording metadata list
- _recordingsDirectory: String?       // Base recordings path
- _maxStorageGB: int                  // Storage limit
- _autoDeleteOldRecordings: bool      // Auto-cleanup flag
```

**Public Methods:**
- `initialize()` - Setup directories and load data
- `addRecording(path)` - Register new recording
- `deleteRecording(recording)` - Remove recording
- `getTotalStorageUsed()` - Calculate total size
- `updateMaxStorage(gb)` - Change storage limit
- `clearAllRecordings()` - Delete all files

**Storage Logic:**
- Creates `/recordings` subdirectory in app documents
- Sorts recordings by creation date (newest first)
- Automatically enforces storage limits on new recordings
- Persists settings to SharedPreferences

### 3. PermissionService (`lib/services/permission_service.dart`)

**Responsibility:** Cross-platform permission management

**Required Permissions:**
- Camera (video recording)
- Microphone (audio recording)
- Location (GPS tracking - planned)
- Storage (file management)

**Platform-Specific:**
- iOS: Info.plist entries required
- Android: AndroidManifest.xml declarations
- Handles permission denied states
- Provides deep-link to settings when needed

### 4. VideoRecording Model (`lib/models/video_recording.dart`)

**Responsibility:** Recording metadata representation

**Properties:**
- `filePath: String` - Full path to video file
- `fileName: String` - Display name
- `createdAt: DateTime` - Recording timestamp
- `fileSize: int` - File size in bytes
- `duration: Duration?` - Video length (if available)
- `location: Position?` - GPS coordinates (planned)

**Factory:**
- `VideoRecording.fromFile(File)` - Creates instance from file

### 5. UI Components

#### SimpleDashcamScreen (`lib/screens/simple_dashcam_screen.dart`)
- Main app screen
- Integrates camera preview and controls
- Manages service lifecycle

#### CameraPreview Widget (`lib/widgets/camera_preview.dart`)
- Displays live camera feed
- Handles aspect ratio and sizing
- Shows camera initialization status

#### RecordingControls Widget (`lib/widgets/recording_controls.dart`)
- Record/stop button
- Visual recording indicator
- Recording timer display

#### RecordingList Widget (`lib/widgets/recording_list.dart`)
- Displays saved recordings
- Playback controls
- Delete functionality

---

## DATA FLOW

### Recording Workflow

```
1. App Launch
   ↓
2. SimpleDashcamScreen.initState()
   ↓
3. PermissionService.checkPermissions()
   ├─ Granted → Continue
   └─ Denied → Request permissions
   ↓
4. CameraService.initializeCamera()
   ├─ Success → Show preview
   └─ Failure → Show error
   ↓
5. StorageService.initialize()
   ├─ Load settings
   ├─ Create recordings directory
   └─ Load existing recordings
   ↓
6. User taps Record Button
   ↓
7. CameraService.startRecording()
   ├─ Generate timestamp filename
   ├─ Create file path
   └─ Start camera recording
   ↓
8. User taps Stop Button
   ↓
9. CameraService.stopRecording()
   ├─ Stop camera recording
   ├─ Save file to path
   └─ Return file path
   ↓
10. StorageService.addRecording(path)
    ├─ Create VideoRecording instance
    ├─ Add to recordings list
    ├─ Check storage limits
    └─ Auto-delete old if needed
    ↓
11. UI Updates via notifyListeners()
    └─ RecordingList shows new recording
```

### State Management Flow

```
User Action → Widget → Service Method → State Change → notifyListeners() → Widget Rebuild
```

Example:
```
Tap Record → RecordingControls → cameraService.startRecording()
→ _isRecording = true → notifyListeners() → Button changes to Stop
```

---

## FILE STRUCTURE

```
TerrainIQ/
├── .claude/                          # Claude Code project documentation
│   ├── analysis/                     # Analysis documents
│   │   ├── architecture/
│   │   ├── dependencies/
│   │   ├── performance/
│   │   └── ui/
│   ├── context/                      # Context files
│   ├── tmp/                          # Temporary files
│   │   ├── exports/
│   │   ├── reports/
│   │   └── backups/
│   ├── workflows/                    # Workflow documentation
│   ├── context.md                    # Quick project context
│   ├── analysis.md                   # This file
│   ├── AGENT_RULES.md                # AI behavioral rules
│   └── ai_session_initialization.md  # AI session guide
│
├── docs/                             # Project documentation
│   ├── api/
│   ├── architecture/
│   ├── deployment/
│   └── mobile/
│
├── terrain_iq_dashcam/               # Flutter app root
│   ├── android/                      # Android platform code
│   │   ├── app/
│   │   │   └── src/main/
│   │   │       ├── AndroidManifest.xml
│   │   │       └── kotlin/
│   │   └── build.gradle
│   │
│   ├── ios/                          # iOS platform code
│   │   ├── Runner/
│   │   │   ├── Info.plist
│   │   │   └── AppDelegate.swift
│   │   └── Podfile
│   │
│   ├── lib/                          # Dart source code
│   │   ├── main.dart                 # App entry point
│   │   ├── models/                   # Data models
│   │   │   └── video_recording.dart
│   │   ├── screens/                  # UI screens
│   │   │   ├── dashcam_screen.dart
│   │   │   └── simple_dashcam_screen.dart
│   │   ├── services/                 # Business logic
│   │   │   ├── camera_service.dart
│   │   │   ├── permission_service.dart
│   │   │   └── storage_service.dart
│   │   └── widgets/                  # Reusable UI components
│   │       ├── camera_preview.dart
│   │       ├── recording_controls.dart
│   │       └── recording_list.dart
│   │
│   ├── test/                         # Unit & widget tests
│   ├── pubspec.yaml                  # Dependencies & metadata
│   ├── pubspec.lock                  # Locked dependency versions
│   └── README.md                     # Project documentation
│
└── lib/                              # Shared libraries (if any)
```

---

## DEPENDENCIES

### Core Dependencies (pubspec.yaml)

**UI Framework:**
- `flutter` - Flutter SDK
- `cupertino_icons ^1.0.8` - iOS-style icons

**Camera & Media:**
- `camera ^0.10.6` - Camera access and video recording
- `video_player ^2.9.2` - Video playback functionality

**Location Services:**
- `geolocator ^13.0.1` - GPS position tracking
- `geocoding ^3.0.0` - Reverse geocoding (address from coordinates)

**File Management:**
- `path_provider ^2.1.4` - Platform-specific directory paths
- `path ^1.9.0` - Path manipulation utilities
- `shared_preferences ^2.3.2` - Persistent key-value storage

**Permissions:**
- `permission_handler ^11.3.1` - Cross-platform permission management

**State Management:**
- `provider ^6.1.2` - State management using ChangeNotifier

**Utilities:**
- `intl ^0.19.0` - Internationalization and date formatting
- `share_plus ^10.0.2` - Cross-platform file sharing

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints ^5.0.0` - Dart linting rules

### Platform Requirements
- **Dart SDK:** ^3.9.2
- **Flutter:** 3.35.5 or higher
- **iOS Deployment Target:** iOS 12.0+
- **Android Min SDK:** API 21 (Android 5.0)

---

## PLATFORM-SPECIFIC IMPLEMENTATION

### iOS Configuration

**Info.plist Permissions:**
```xml
<key>NSCameraUsageDescription</key>
<string>Required for dashcam video recording</string>

<key>NSMicrophoneUsageDescription</key>
<string>Required for audio recording</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Required for GPS tracking in recordings</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save recordings to photo library</string>
```

**Requirements:**
- Xcode 14+ for development
- CocoaPods for dependency management
- Apple Developer account for device testing
- Code signing certificate

**Build Configuration:**
- Deployment target: iOS 12.0
- Swift version: 5.0
- Architecture: arm64, armv7

### Android Configuration

**AndroidManifest.xml Permissions:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**Requirements:**
- Android SDK API 21+ (Lollipop 5.0)
- Gradle 7.0+
- Android Studio for development

**Build Configuration:**
- Min SDK: 21
- Target SDK: 33
- Kotlin version: 1.7.10

---

## STATE MANAGEMENT

### Provider Pattern Implementation

**App-Level Providers:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CameraService()),
    ChangeNotifierProvider(create: (_) => StorageService()),
    ChangeNotifierProvider(create: (_) => PermissionService()),
  ],
  child: TerrainIQDashcamApp(),
)
```

**Service State Notification:**
```dart
class CameraService extends ChangeNotifier {
  // State changes trigger notifyListeners()
  Future<void> startRecording() async {
    // ... recording logic
    _isRecording = true;
    notifyListeners(); // Triggers UI rebuild
  }
}
```

**Widget State Consumption:**
```dart
class RecordingControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cameraService = Provider.of<CameraService>(context);
    // Rebuilds when cameraService.notifyListeners() is called
    return IconButton(
      icon: cameraService.isRecording ? StopIcon : RecordIcon,
      onPressed: cameraService.toggleRecording,
    );
  }
}
```

### State Lifecycle

1. **Initialization:** Services created by Provider
2. **Usage:** Widgets access via `Provider.of<T>(context)`
3. **Update:** Services call `notifyListeners()` on state change
4. **Rebuild:** Widgets listening to service rebuild
5. **Disposal:** Services disposed when provider removed

---

## STORAGE STRATEGY

### Directory Structure

```
Application Documents Directory/
└── recordings/
    ├── recording_1696876543210.mp4
    ├── recording_1696876789456.mp4
    └── recording_1696877012345.mp4
```

### File Naming Convention
`recording_[timestamp_in_milliseconds].mp4`

Example: `recording_1696876543210.mp4`

### Storage Limits

**Default Configuration:**
- Max storage: 10 GB
- Auto-delete: Enabled
- Delete strategy: Oldest first (FIFO)

**User Configurable:**
- Storage limit (via settings - planned)
- Auto-delete toggle (via settings - planned)

**Enforcement Logic:**
1. On new recording added
2. Calculate total storage used
3. If > limit and auto-delete enabled
4. Delete oldest recordings until under limit
5. Update recordings list

### Storage Calculation

```dart
Future<int> _getTotalStorageUsed() async {
  int totalSize = 0;
  for (final recording in _recordings) {
    final File file = File(recording.filePath);
    if (await file.exists()) {
      totalSize += await file.length();
    }
  }
  return totalSize;
}
```

---

## PERMISSION HANDLING

### Permission Flow

```
App Launch
   ↓
Check Permissions
   ├─ All Granted → Continue
   ├─ Some Denied → Request
   │   ├─ Granted → Continue
   │   └─ Denied → Show Rationale
   │       ├─ Request Again
   │       └─ Direct to Settings
   └─ Permanently Denied → Settings Deep-Link
```

### Permission States

1. **Not Determined** - Never requested
2. **Granted** - User allowed permission
3. **Denied** - User denied permission (can request again)
4. **Permanently Denied** - User denied with "Don't ask again"
5. **Restricted** - System-level restriction (iOS)

### Critical Permissions

**Required for Core Functionality:**
- Camera (video recording)
- Microphone (audio recording)

**Optional for Enhanced Features:**
- Location (GPS tracking)
- Storage (file access on Android < 10)

### Permission Request Strategy

1. **Request on first use** (lazy requesting)
2. **Show rationale** before requesting
3. **Graceful degradation** for optional permissions
4. **Settings deep-link** for permanently denied

---

## DEVELOPMENT WORKFLOW

### Setup Development Environment

```bash
# 1. Install Flutter SDK
flutter doctor

# 2. Navigate to project
cd /Users/ryan-bookmarked/platform/intellimass/TerrainIQ/terrain_iq_dashcam

# 3. Install dependencies
flutter pub get

# 4. Check connected devices
flutter devices

# 5. Run on device
flutter run
```

### Development Commands

```bash
# Hot reload during development
r  # Reload code changes
R  # Hot restart app
q  # Quit

# Clean build
flutter clean
flutter pub get

# Build for release
flutter build apk --release     # Android
flutter build ios --release     # iOS

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### Debugging

**Flutter DevTools:**
- Performance profiling
- Widget inspector
- Memory analysis
- Network monitoring

**Platform-Specific Logs:**
- iOS: Xcode Console
- Android: Android Studio Logcat

**Debug Prints:**
```dart
debugPrint('Message'); // Preferred over print()
```

---

## KNOWN ISSUES & LIMITATIONS

### Current Limitations

1. **Background Recording Disabled**
   - Plugin compatibility issues
   - Would require foreground service (Android)
   - iOS requires background modes configuration

2. **No Git Repository**
   - Project not version controlled
   - Recommendation: Initialize Git for tracking

3. **GPS Integration Incomplete**
   - Location permissions defined
   - Geolocator package installed
   - Integration with recordings not implemented

4. **Settings UI Missing**
   - Storage limits hardcoded
   - No user-facing settings screen
   - SharedPreferences backend ready

5. **Video Playback Basic**
   - video_player package included
   - Full playback UI not implemented

### Platform Constraints

**iOS:**
- Requires physical device for camera testing
- Code signing required for device deployment
- App Store review needed for distribution

**Android:**
- Storage permissions complex on Android 10+
- Background recording requires foreground service
- Various OEM camera API quirks

**Web:**
- Limited camera API support
- File system access restricted
- Not primary target platform

---

## FUTURE ROADMAP

### Short-Term (Next Sprint)

1. **Complete GPS Integration**
   - Embed location data in VideoRecording model
   - Display coordinates in recording list
   - Geocode to addresses

2. **Settings Screen**
   - Storage limit configuration
   - Auto-delete toggle
   - Video quality settings
   - About/version info

3. **Enhanced Video Playback**
   - Full-screen playback
   - Scrubbing controls
   - Playback speed controls

4. **Git Initialization**
   - Initialize repository
   - Create .gitignore
   - Initial commit

### Medium-Term (1-2 Months)

1. **Background Recording**
   - Foreground service (Android)
   - Background modes (iOS)
   - Battery optimization handling

2. **Cloud Sync**
   - Firebase Storage integration
   - Automatic upload on WiFi
   - Cloud backup management

3. **Crash Detection**
   - Accelerometer monitoring
   - Auto-save on impact detection
   - Emergency contact notification

4. **Speed Tracking**
   - Speed overlay on recordings
   - Speed-based auto-recording
   - Speeding alerts

### Long-Term (3-6 Months)

1. **Advanced Features**
   - Time-lapse mode
   - Multiple camera support
   - External camera integration

2. **AI/ML Integration**
   - Object detection
   - License plate recognition
   - Incident classification

3. **Social Features**
   - Share to social media
   - Community incident reporting
   - Journey sharing

4. **Enterprise Features**
   - Fleet management
   - Driver behavior analysis
   - Compliance reporting

---

## TECHNICAL DEBT

### Areas for Improvement

1. **Error Handling**
   - More robust error recovery
   - User-friendly error messages
   - Retry mechanisms

2. **Testing**
   - Unit test coverage
   - Widget tests
   - Integration tests
   - Platform-specific tests

3. **Code Documentation**
   - Add dartdoc comments
   - API documentation
   - Architecture decision records

4. **Performance**
   - Optimize camera preview rendering
   - Lazy loading for recording list
   - Memory management improvements

5. **Accessibility**
   - Screen reader support
   - Voice control integration
   - High contrast mode

---

## PERFORMANCE CONSIDERATIONS

### Camera Performance
- ResolutionPreset.high may impact lower-end devices
- Consider adaptive quality based on device capabilities
- Monitor memory usage during long recordings

### Storage Operations
- File I/O on main thread for small operations
- Consider background thread for large file operations
- Optimize recording list loading for many files

### UI Rendering
- Camera preview is resource-intensive
- Minimize widget rebuilds
- Use const constructors where possible

---

## SECURITY CONSIDERATIONS

### Data Privacy
- Videos stored locally only (no cloud by default)
- No analytics or tracking
- User controls all data

### Permission Security
- Request minimum necessary permissions
- Explain permission usage clearly
- Handle denied permissions gracefully

### File Security
- App-scoped storage (sandboxed)
- No world-readable files
- Secure deletion of removed recordings

---

**End of Analysis Document**

*For questions or updates, refer to `.claude/context.md` or contact the development team.*
