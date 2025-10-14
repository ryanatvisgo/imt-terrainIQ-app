# TerrainIQ Dashcam - Screen Architecture

**Last Updated:** 2025-10-13
**Version:** 1.0.0

This document provides a comprehensive screen-by-screen breakdown of the TerrainIQ Dashcam application including widget trees, state management, service dependencies, and navigation flows.

---

## Table of Contents

1. [Navigation Architecture](#navigation-architecture)
2. [Screen Details](#screen-details)
3. [Widget Tree Diagrams](#widget-tree-diagrams)
4. [State Management](#state-management)
5. [Service Dependencies](#service-dependencies)
6. [Performance Considerations](#performance-considerations)

---

## Navigation Architecture

### Navigation Type

**Pattern:** Navigator 1.0 (imperative navigation)
**Root Widget:** MaterialApp

### Navigation Hierarchy

```
MaterialApp
  └─ MultiProvider (Service Providers)
      └─ MaterialApp (with routes)
          └─ SplashScreen (initial route: '/')
              └─ DrivingModeScreen (pushReplacement)
                  ├─ SettingsScreen (push)
                  └─ [Back to DrivingModeScreen] (pop)
```

### Route Table

| Route | Screen | Type | Entry Point |
|-------|--------|------|-------------|
| `/` | SplashScreen | Root | App launch |
| N/A | DrivingModeScreen | Replace | After splash |
| N/A | SettingsScreen | Push | Back button from DrivingMode |
| N/A | PreviewModeScreen | Direct | Web preview only (conditional) |

**Note:** The app doesn't use named routes; navigation is handled programmatically.

---

## Screen Details

### 1. SplashScreen

**File:** `lib/screens/splash_screen.dart`

#### Purpose
- Display branding while initializing services
- Upload pending crash logs from previous sessions
- Transition to main app when ready

#### Lifecycle

```
initState()
  └─ Start pulse animation
  └─ Call _navigateToHome()
      ├─ Check if preview mode → skip initialization
      ├─ Initialize ServerService
      ├─ Initialize CameraService
      ├─ Initialize LocationService → startTracking()
      ├─ Initialize HazardService
      ├─ Initialize MqttService
      ├─ Upload pending logs (with 10s timeout)
      ├─ Clean up old logs
      ├─ Wait minimum 2.5 seconds
      └─ Navigate to DrivingModeScreen (pushReplacement)

dispose()
  └─ Dispose pulse animation controller
```

#### Widget Tree

```
Scaffold
  └─ body: Stack
      ├─ Container (gradient background #0A0E1A → #000000)
      ├─ CustomPaint (GPS grid pattern via GridPainter)
      └─ Center
          └─ Column
              ├─ AnimatedBuilder (pulsing glow effect)
              │   └─ Container (circle with shadow)
              │       └─ Image.asset('assets/splash_logo.png')
              ├─ SizedBox(height: 50)
              ├─ ShaderMask (gradient text effect)
              │   └─ Text('TerrainIQ', 48pt, Light, letterSpacing: 4)
              ├─ SizedBox(height: 8)
              ├─ Text('Road Intelligence System', 14pt, Blue)
              ├─ SizedBox(height: 4)
              ├─ Text('by IntelliMass.ai', 12pt, Gray)
              ├─ SizedBox(height: 70)
              └─ SizedBox (loading indicator)
                  └─ Stack
                      ├─ CircularProgressIndicator (outer ring, 50x50, thin)
                      └─ CircularProgressIndicator (inner spinner, 35x35)
```

#### State Management

**Local State:**
- `_pulseController` - AnimationController for logo pulse

**No Provider Consumers** (initializes services directly)

#### Service Dependencies

| Service | Action | Error Handling |
|---------|--------|----------------|
| DeviceLoggerService | Get pending logs | Non-blocking |
| ServerService | Initialize, upload logs | Catch & log, continue |
| CameraService | Initialize camera | Catch & log, continue (optional) |
| LocationService | Initialize & start tracking | Await |
| HazardService | Initialize | Await |
| MqttService | Initialize | Await |

#### Performance Notes
- Uses `const` constructors where possible
- Animations cached and reused
- Service initialization happens in background
- Minimum splash time prevents flickering (2.5s)

---

### 2. DrivingModeScreen

**File:** `lib/screens/driving_mode_screen.dart`

#### Purpose
- Main app screen with hazard warnings and camera view
- Two-page architecture (Hazard HUD / Camera View)
- Auto-record management and manual recording controls

#### Lifecycle

```
initState()
  └─ Initialize PageController (page 0)
  └─ Initialize flash AnimationController (800ms, repeat)
  └─ Start proximity check timer (1 second interval)
  └─ Start motion check timer (1 second interval)

Timer (proximityCheck, 1s)
  └─ hazardService.updateProximity()

Timer (motionCheck, 1s)
  └─ _checkAutoRecordConditions()
      ├─ If should start → _startRecording()
      └─ If should stop → _stopRecording()

_startRecording()
  ├─ Set _isRecordingInProgress = true
  ├─ cameraService.startRecording()
  ├─ dataLoggerService.startLogging(filename)
  ├─ deviceLogger.logRecordingStarted()
  ├─ serverService.setRecordingStatus(true)
  ├─ Start data log timer (100ms interval)
  ├─ Start countdown update timer (1s interval)
  ├─ Show snackbar "Recording started!"
  └─ Set _isRecordingInProgress = false

_stopRecording()
  ├─ Set _isRecordingInProgress = true
  ├─ Cancel data log timer
  ├─ Cancel countdown timer
  ├─ cameraService.stopRecording() → get filePath
  ├─ dataLoggerService.stopLogging()
  ├─ serverService.setRecordingStatus(false)
  ├─ storageService.addRecording(filePath)
  ├─ deviceLogger.logRecordingEnded()
  ├─ serverService.queueVideoUpload(recording)
  ├─ Show snackbar "Recording saved and queued for upload!"
  └─ Set _isRecordingInProgress = false

dispose()
  └─ Cancel all timers
  └─ Dispose animation controllers
  └─ Dispose PageController
```

#### Widget Tree - Page 1 (Hazard HUD)

```
Scaffold
  └─ body: SafeArea
      └─ Stack
          ├─ PageView (controller: _pageController)
          │   ├─ Page 1: _buildHazardPage()
          │   │   └─ Container (dynamic background color)
          │   │       └─ Stack
          │   │           ├─ Positioned.fill (_buildHUDDisplay)
          │   │           │   └─ [If hasActiveWarning]
          │   │           │       └─ Center → Padding → Column
          │   │           │           ├─ [If not insideZone] _buildDirectionalArrow()
          │   │           │           ├─ SizedBox(height: 16)
          │   │           │           ├─ Icon(warning_rounded, 100pt)
          │   │           │           ├─ SizedBox(height: 24)
          │   │           │           ├─ [If insideZone] Text('IN KNOWN HAZARD ZONE')
          │   │           │           │   [Else] Column
          │   │           │           │       ├─ Text('HAZARD AHEAD', 32pt, bold)
          │   │           │           │       └─ Text('XXXm', 80pt, bold)
          │   │           │           ├─ SizedBox(height: 24)
          │   │           │           ├─ Container (hazard info card)
          │   │           │           │   └─ Column
          │   │           │           │       ├─ Text(hazard.primaryLabel, 28pt)
          │   │           │           │       └─ Row (severity display)
          │   │           │           └─ [If multiple labels] Wrap (additional labels)
          │   │           │   └─ [Else no warning]
          │   │           │       └─ Stack
          │   │           │           ├─ Center → Column
          │   │           │           │   ├─ Icon(check_circle_outline, 120pt)
          │   │           │           │   ├─ Text('No known hazards', 32pt)
          │   │           │           │   └─ Text(lastRecorded, 18pt, 70% opacity)
          │   │           │           └─ [If nextHazard] _buildNextHazardIndicator()
          │   │           │               [Else] _buildLocationStatusIndicator()
          │   │           └─ Positioned (bottom: 80, right: 20)
          │   │               └─ _buildStatusIndicators()
          │   │                   └─ Container (dark overlay, rounded)
          │   │                       └─ Row
          │   │                           ├─ _buildStatusDot(recording icon)
          │   │                           ├─ _buildStatusDot(motion icon)
          │   │                           ├─ _buildStatusDot(orientation icon)
          │   │                           └─ _buildEnhancedRoughnessIndicator()
          │   │
          │   └─ Page 2: _buildCameraPage()
          │       └─ [See below]
          │
          ├─ Positioned (top: 20, left: 20) - Back button
          │   └─ GestureDetector
          │       └─ Container (circular, black 50%)
          │           └─ Icon(arrow_back, 28pt)
          │
          └─ Positioned (bottom: 20, center) - Page indicators
              └─ Row
                  ├─ _buildPageIndicator(0)
                  └─ _buildPageIndicator(1)
```

#### Widget Tree - Page 2 (Camera View)

```
Page 2: _buildCameraPage()
  └─ Container (color: black)
      └─ Stack
          ├─ CameraPreview(cameraService.controller)
          │
          ├─ Positioned (top: 20, left: 60, right: 60) - Camera info
          │   └─ Container (dark overlay, rounded)
          │       └─ Column
          │           ├─ Text('REAR → NW', 16pt, bold)
          │           └─ Text('45 km/h', 14pt, 70% opacity)
          │
          ├─ [If !isRecording] _buildAutoRecordToggle()
          │   └─ Positioned (top: 100, left: 20, right: 20)
          │       └─ Container (dark overlay, border)
          │           └─ [If portrait] _buildExpandedAutoRecordToggle()
          │               └─ Column
          │                   ├─ Row (label + switch)
          │                   ├─ [If warming up] Container (warming progress)
          │                   │   └─ Column
          │                   │       ├─ Row (icon + text)
          │                   │       └─ LinearProgressIndicator
          │                   ├─ Row (motion status)
          │                   ├─ Row (orientation status)
          │                   └─ Row (roughness status)
          │           └─ [Else landscape] _buildCompactAutoRecordToggle()
          │               └─ Row
          │                   ├─ Switch (scaled 0.8x)
          │                   ├─ [If warming] CircularProgress + text
          │                   ├─ [Else] Status dots (motion, orientation)
          │                   └─ Roughness indicator
          │
          ├─ [If isRecording] FadeTransition (REC indicator)
          │   └─ Positioned (top: 100, right: 20)
          │       └─ Container (red badge)
          │           └─ Row
          │               ├─ Icon(fiber_manual_record, 12pt)
          │               └─ Text('REC', 14pt, bold)
          │
          └─ Positioned (bottom: 80, center) - Record button
              └─ _buildRecordButton()
                  └─ GestureDetector
                      └─ Container (80x80, circle, shadow)
                          └─ Icon (videocam or stop, 40pt)
```

#### State Management

**Local State:**
- `_currentPage` - Current PageView page (0 or 1)
- `_autoRecordEnabled` - Auto-record toggle state (default: true)
- `_isRecordingInProgress` - Prevent double-clicks
- `_wasMovingLastCheck` - Track motion state changes

**Provider Consumers:**
```dart
Consumer4<CameraService, HazardService, LocationService, MotionService>(
  builder: (context, cameraService, hazardService, locationService, motionService, child) {
    return Scaffold(...);
  },
)
```

#### Service Dependencies

| Service | Usage | Update Frequency |
|---------|-------|------------------|
| CameraService | Camera control, recording status | On-demand |
| HazardService | Proximity calculation, hazard data | 1s (proximity), 15min (fetch) |
| LocationService | GPS, heading, speed | 5s |
| MotionService | Movement, orientation, roughness | Continuous |
| DataLoggerService | CSV logging during recording | 100ms |
| StorageService | Save recordings | On-demand |
| ServerService | Upload queue, recording status | On-demand |
| DeviceLoggerService | Error logging | On-demand |

#### Performance Notes
- Uses `Consumer4` to minimize unnecessary rebuilds
- Timers run independently of UI rebuilds
- Double-click prevention with `_isRecordingInProgress` flag
- PageView lazy loads pages
- Animation controllers disposed properly

---

### 3. SettingsScreen

**File:** `lib/screens/settings_screen.dart`

#### Purpose
- Configure app settings (proximity threshold, upload behavior, motion detection)
- Launch Driving Mode from settings
- View current configuration

#### Lifecycle

```
No initState (StatelessWidget)

build()
  └─ Render settings UI with Provider consumers
```

#### Widget Tree

```
Scaffold
  ├─ appBar: AppBar
  │   └─ title: Text('Settings')
  │
  └─ body: ListView
      ├─ _buildDrivingModeSection()
      │   └─ Consumer<HazardService>
      │       └─ ExpansionTile
      │           ├─ title: 'Driving Mode'
      │           └─ children:
      │               ├─ ListTile ('Hazard Warning HUD', onTap: navigate)
      │               ├─ Padding (features list)
      │               └─ Padding (Proximity slider)
      │                   └─ Column
      │                       ├─ Row (label + value)
      │                       ├─ Row (slider with labels)
      │                       └─ Text (explanation)
      │
      ├─ Divider
      │
      ├─ _buildGeneralSettings()
      │   └─ Consumer<ServerService>
      │       └─ ExpansionTile
      │           ├─ title: 'General'
      │           └─ children:
      │               ├─ SwitchListTile (WiFi-Only Uploads)
      │               └─ SwitchListTile (Delete After Upload)
      │
      ├─ Divider
      │
      ├─ _buildRecordingSettings()
      │   └─ ExpansionTile
      │       ├─ title: 'Recording'
      │       └─ children:
      │           ├─ ListTile (Auto-Record info)
      │           └─ ListTile (Auto-Stop info)
      │
      ├─ Divider
      │
      └─ _buildAdvancedSettings()
          └─ Consumer<MotionService>
              └─ ExpansionTile
                  ├─ title: 'Advanced'
                  └─ children:
                      ├─ SwitchListTile (Allow Flat Orientation)
                      └─ Padding (Motion thresholds info)
```

#### State Management

**Local State:** None (StatelessWidget)

**Provider Consumers:**
- `Consumer<HazardService>` - Proximity threshold slider
- `Consumer<ServerService>` - Upload settings
- `Consumer<MotionService>` - Orientation override

#### Service Dependencies

| Service | Usage | Update Trigger |
|---------|-------|----------------|
| HazardService | Read/write proximityThresholdMeters | Slider change |
| ServerService | Read/write wifiOnlyMode, deleteAfterUpload | Switch toggle |
| MotionService | Read/write ignoreFlatOrientation | Switch toggle |

#### Performance Notes
- StatelessWidget (no state to manage)
- Uses Consumer widgets to minimize rebuilds
- Slider updates notifyListeners() only on change
- ExpansionTiles manage their own expand/collapse state

---

### 4. PreviewModeScreen (Web Only)

**File:** `lib/screens/preview_mode_screen.dart`

#### Purpose
- Web-based preview mode for monitoring devices via MQTT
- Display real-time device status without full app initialization

#### Lifecycle

```
initState()
  └─ Initialize MqttPreviewService
      └─ Connect to MQTT broker via WebSocket
      └─ Subscribe to device topics
      └─ Update UI on messages received

dispose()
  └─ Disconnect MQTT preview service
```

#### Widget Tree

```
Scaffold
  ├─ appBar: AppBar
  │   └─ title: Text('TerrainIQ Preview Mode')
  │
  └─ body: Consumer<MqttPreviewService>
      └─ Center
          └─ Column
              ├─ Text('MQTT Status: {connected/disconnected}')
              ├─ Container (device info card)
              │   └─ Column
              │       ├─ Text('Device: {deviceId}')
              │       ├─ Text('Location: {lat}, {lon}')
              │       ├─ Text('Speed: {speed} km/h')
              │       ├─ Text('Recording: {yes/no}')
              │       └─ Text('Last Update: {time}')
              └─ [If hazard warning]
                  └─ Container (hazard info card)
                      └─ Text('Hazard: {type} @ {distance}m')
```

#### State Management

**Local State:** None

**Provider Consumer:**
- `Consumer<MqttPreviewService>` - MQTT connection & data

#### Service Dependencies

| Service | Usage |
|---------|-------|
| MqttPreviewService (web-specific) | MQTT WebSocket connection, data display |

---

## Widget Tree Diagrams

### Overall App Structure

```
MaterialApp
  └─ builder: (context, child)
      └─ MultiProvider
          ├─ ChangeNotifierProvider(CameraService)
          ├─ ChangeNotifierProvider(PermissionService)
          ├─ ChangeNotifierProvider(StorageService)
          ├─ ChangeNotifierProvider(DataLoggerService)
          ├─ ChangeNotifierProvider(DeviceLoggerService)
          ├─ ChangeNotifierProvider(MetadataService)
          ├─ ChangeNotifierProvider(ServerService)
          ├─ ChangeNotifierProvider(MqttPublisherService)
          ├─ ChangeNotifierProxyProvider(LocationService)
          ├─ ChangeNotifierProxyProvider(MqttService)
          ├─ ChangeNotifierProxyProvider2(HazardService)
          ├─ ChangeNotifierProvider(MotionService)
          └─ [If kIsWeb] ChangeNotifierProvider(MqttPreviewService)
          └─ child (Navigator)
```

---

## State Management

### Provider Pattern

**Architecture:** Provider package with ChangeNotifier

**Service Hierarchy:**

```
Independent Services (no dependencies):
  - CameraService
  - PermissionService
  - StorageService
  - DataLoggerService
  - DeviceLoggerService
  - MetadataService
  - ServerService
  - MqttPublisherService
  - MotionService

Dependent Services (use ProxyProvider):
  - LocationService (depends on PermissionService)
  - MqttService (depends on LocationService, MqttPublisherService)
  - HazardService (depends on LocationService, MqttService)
```

### State Update Flow

```
User Action
    ↓
Widget (Consumer)
    ↓
Service Method Call
    ↓
Service State Update
    ↓
notifyListeners()
    ↓
Consumer Rebuilds
    ↓
UI Updates
```

### Example: Proximity Threshold Change

```
User moves slider in SettingsScreen
    ↓
Slider onChanged callback
    ↓
hazardService.setProximityThreshold(value)
    ↓
HazardService:
  - Update _proximityThresholdMeters
  - Call notifyListeners()
    ↓
Consumer<HazardService> in SettingsScreen rebuilds
    ↓
Slider value updates in UI
    ↓
DrivingModeScreen Consumer4 rebuilds (uses HazardService)
    ↓
Proximity checks use new threshold
```

---

## Service Dependencies

### Dependency Graph

```
PermissionService (no deps)
    ↓
LocationService
    ↓
    ├─→ MqttPublisherService (no deps)
    │       ↓
    │   MqttService
    ├─→ HazardService
    │
    └─→ MotionService (no deps)

CameraService (no deps)
StorageService (no deps)
DataLoggerService (uses LocationService, MotionService via params)
ServerService (no deps)
DeviceLoggerService (no deps)
```

### Service Initialization Order (SplashScreen)

1. **ServerService.initialize()**
2. **CameraService.initializeCamera()** (optional, catch errors)
3. **LocationService.initialize() → startTracking()**
4. **HazardService.initialize()** (depends on LocationService)
5. **MqttService.initialize()** (depends on LocationService)

---

## Performance Considerations

### Rendering Performance

#### Widget Rebuild Optimization

**Problem:** Rebuilding entire screen on every state change

**Solutions:**
- Use `Consumer` widgets instead of `Provider.of<T>(context)`
- Limit Consumer scope to smallest widget subtree
- Use `Consumer4` for multiple services in single builder
- Use `const` constructors for static widgets

**Example:**
```dart
// ❌ Bad: Rebuilds entire screen on any service change
Widget build(BuildContext context) {
  final cameraService = Provider.of<CameraService>(context);
  final hazardService = Provider.of<HazardService>(context);
  return Scaffold(...);  // Entire Scaffold rebuilds
}

// ✅ Good: Only rebuilds Consumer subtree
Widget build(BuildContext context) {
  return Scaffold(
    body: Consumer2<CameraService, HazardService>(
      builder: (context, camera, hazard, child) {
        return statusWidget;  // Only this rebuilds
      },
    ),
  );
}
```

---

### Memory Management

#### Timer Cleanup

All timers must be cancelled in `dispose()`:

```dart
@override
void dispose() {
  _proximityCheckTimer?.cancel();
  _motionCheckTimer?.cancel();
  _dataLogTimer?.cancel();
  _countdownUpdateTimer?.cancel();
  _flashController.dispose();
  _pageController.dispose();
  super.dispose();
}
```

**Impact:** Prevents memory leaks and zombie timers

---

#### Animation Controller Disposal

```dart
@override
void dispose() {
  _pulseController.dispose();
  _flashController.dispose();
  super.dispose();
}
```

**Impact:** Frees GPU resources, prevents memory leaks

---

### Network Performance

#### Chunked Upload Strategy

**Problem:** Large video files timeout or fail to upload

**Solution:** Chunked upload with resume support
- Chunk size: 5MB
- Retry failed chunks
- Track progress
- Resume interrupted uploads

**Implementation:** `ServerService.uploadVideoChunked()`

---

### Battery Optimization

#### Service Update Frequencies

| Service | Frequency | Battery Impact |
|---------|-----------|----------------|
| Location | 5 seconds | Medium |
| Proximity Check | 1 second | Low (calculation only) |
| Hazard Fetch | 15 minutes | Very Low |
| MQTT Heartbeat | 60 seconds | Very Low |
| MQTT Status | 5 seconds | Low |
| CSV Logging | 100ms | Medium (during recording only) |
| Motion Sensors | Continuous | Medium (hardware accelerated) |

**Optimization:**
- Location updates use system batching
- Timers only run when screen active
- CSV logging only during recording
- Motion sensors use hardware filtering

---

## Navigation Patterns

### Standard Navigation

```dart
// Push
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => SettingsScreen()),
);

// Pop
Navigator.of(context).pop();

// Push Replacement
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) => DrivingModeScreen()),
);
```

### In-Screen Navigation (PageView)

```dart
// Programmatic page change
_pageController.animateToPage(
  1,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
);

// Swipe gesture (built-in to PageView)
PageView(
  controller: _pageController,
  onPageChanged: (index) {
    setState(() => _currentPage = index);
  },
  children: [page1, page2],
)
```

---

## Testing Considerations

### Widget Testing

**Key Widgets to Test:**
- Page navigation (swipe, page indicators)
- Button interactions (record, back, settings)
- Toggle switches (auto-record, settings)
- Slider updates (proximity threshold)

**Example Test Structure:**
```dart
testWidgets('Record button starts and stops recording', (tester) async {
  // Pump widget with mocked services
  await tester.pumpWidget(createTestApp());

  // Find record button
  final recordButton = find.byIcon(Icons.videocam);

  // Tap button
  await tester.tap(recordButton);
  await tester.pump();

  // Verify recording started
  expect(mockCameraService.isRecording, true);
});
```

---

### Integration Testing

**Test Scenarios:**
1. **App Launch:** Splash → DrivingMode transition
2. **Auto-Record:** Motion detected → Recording starts
3. **Hazard Warning:** Enter proximity threshold → Warning displays
4. **Upload Queue:** Recording stops → Video queued for upload
5. **Settings Persist:** Change setting → Restart app → Setting persists

---

## Future Architecture Improvements

### 1. Named Routes

**Current:** Imperative navigation
**Future:** Named routes with route guards

```dart
MaterialApp(
  initialRoute: '/',
  routes: {
    '/': (context) => SplashScreen(),
    '/driving': (context) => DrivingModeScreen(),
    '/settings': (context) => SettingsScreen(),
  },
)
```

---

### 2. State Management Migration

**Current:** Provider
**Future Options:**
- **Riverpod** - Improved Provider with better testing
- **Bloc** - More structured state management
- **GetX** - Simpler API, built-in navigation

---

### 3. Modular Architecture

**Current:** Monolithic screens
**Future:** Feature-based modules

```
lib/
  ├─ features/
  │   ├─ hazard_warning/
  │   │   ├─ screens/
  │   │   ├─ widgets/
  │   │   ├─ services/
  │   │   └─ models/
  │   ├─ recording/
  │   └─ settings/
  └─ shared/
```

---

*This document should be referenced when modifying screen layouts, adding navigation, or restructuring the application architecture.*
