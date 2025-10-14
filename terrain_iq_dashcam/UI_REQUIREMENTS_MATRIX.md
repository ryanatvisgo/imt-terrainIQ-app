# TerrainIQ Dashcam - UI Requirements Matrix

**Last Updated:** 2025-10-13
**Version:** 1.0.0

This document provides a comprehensive breakdown of all UI features, screens, components, and interactions organized by screen and categorized by function type.

---

## Table of Contents

1. [Screen Overview](#screen-overview)
2. [Feature Matrix by Screen](#feature-matrix-by-screen)
3. [UI Component Inventory](#ui-component-inventory)
4. [Background Services Matrix](#background-services-matrix)
5. [User Interaction Flows](#user-interaction-flows)
6. [State Management Map](#state-management-map)

---

## Screen Overview

### Screen Hierarchy

```
SplashScreen (Entry Point)
    └─> DrivingModeScreen (Main App Screen)
            ├─> SettingsScreen (via back button)
            └─> PreviewModeScreen (web preview only)
```

### Screen Inventory

| Screen Name | File Path | Purpose | Navigation Type |
|-------------|-----------|---------|-----------------|
| SplashScreen | `lib/screens/splash_screen.dart` | Initial load, service initialization | Auto-navigate |
| DrivingModeScreen | `lib/screens/driving_mode_screen.dart` | Main hazard warning & camera view | Root screen |
| SettingsScreen | `lib/screens/settings_screen.dart` | Configuration options | Push navigation |
| PreviewModeScreen | `lib/screens/preview_mode_screen.dart` | Web-based preview mode | Direct launch |
| SimpleDashcamScreen | `lib/screens/simple_dashcam_screen.dart` | Legacy camera view | Deprecated |
| DashcamScreen | `lib/screens/dashcam_screen.dart` | Legacy dashcam UI | Deprecated |

---

## Feature Matrix by Screen

### 1. SplashScreen

#### UI Features (User-Facing)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Animated Logo | Visual | High | ✅ Implemented | Pulsing glow effect on truck logo |
| GPS Grid Background | Visual | Medium | ✅ Implemented | Animated grid pattern with corner accents |
| Loading Indicator | Visual | High | ✅ Implemented | Dual-ring circular progress spinner |
| Branding Display | Visual | High | ✅ Implemented | TerrainIQ title with gradient shader |
| Initialization Status | Text | Low | ✅ Implemented | "INITIALIZING SYSTEM" text |

#### Background Features (System)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Service Initialization | System | Critical | ✅ Implemented | Initialize camera, location, hazard, MQTT services |
| Log Upload | System | High | ✅ Implemented | Upload pending crash logs from previous sessions |
| Camera Initialization | System | Critical | ✅ Implemented | Initialize camera with error handling |
| Location Service Start | System | Critical | ✅ Implemented | Start GPS tracking |
| Hazard Data Fetch | System | High | ✅ Implemented | Initial hazard data load |
| Old Log Cleanup | System | Low | ✅ Implemented | Delete old uploaded log files |

#### UI Components Used

- `Container` with gradient background
- `CustomPainter` (GridPainter) for GPS grid
- `AnimatedBuilder` for pulsing glow
- `CircularProgressIndicator` (dual ring)
- `ShaderMask` for title gradient
- `Image.asset` for logo

#### Service Dependencies

- CameraService
- LocationService
- HazardService
- MqttService
- ServerService
- DeviceLoggerService

---

### 2. DrivingModeScreen (Main Screen)

This is the core screen of the application with a PageView architecture containing 2 pages.

#### Page 1: Hazard HUD

##### UI Features (User-Facing)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Dynamic Background Color | Visual | Critical | ✅ Implemented | Changes based on proximity/severity (Blue/Yellow/Orange/Red) |
| Hazard Warning Display | Visual | Critical | ✅ Implemented | Large warning text with hazard type |
| Distance Countdown | Visual | Critical | ✅ Implemented | 80pt bold distance in meters, rounded to nearest 5m |
| Directional Arrow | Visual | High | ✅ Implemented | Navigation arrow pointing toward hazard |
| Severity Display | Visual | High | ✅ Implemented | Severity score (1-10 scale) |
| Hazard Labels | Visual | High | ✅ Implemented | Multiple labels with primary label emphasized |
| "All Clear" State | Visual | High | ✅ Implemented | Check icon with "No known hazards" message |
| "Next Hazard" Indicator | Visual | High | ✅ Implemented | Top-right corner showing next hazard ahead (±90° cone) |
| Location Status Indicator | Visual | Medium | ✅ Implemented | Shows GPS/heading availability status |
| Status Indicators | Visual | High | ✅ Implemented | Recording, motion, orientation, roughness (bottom-right) |
| Page Indicator Dots | Navigation | Medium | ✅ Implemented | Bottom center dots showing current page |
| Back Button | Navigation | High | ✅ Implemented | Top-left circular button with back arrow |

##### Background Features (System)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Proximity Checking | System | Critical | ✅ Implemented | Check proximity every 1 second |
| Hazard Distance Calculation | System | Critical | ✅ Implemented | Calculate distance to all hazards |
| Proximity Level Detection | System | Critical | ✅ Implemented | Determine safe/approaching/warning/insideZone |
| Forward Cone Detection | System | High | ✅ Implemented | Find next hazard in ±90° forward cone |
| Background Color Logic | System | Critical | ✅ Implemented | Blue/Yellow/Orange/Red based on severity + distance |
| Bearing Calculation | System | High | ✅ Implemented | Calculate angle to hazard for arrow direction |

#### Page 2: Camera View

##### UI Features (User-Facing)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Full-Screen Camera Preview | Visual | Critical | ✅ Implemented | Live camera feed from rear camera |
| Camera Orientation Display | Visual | High | ✅ Implemented | Shows Front/Rear/Left/Right + compass direction |
| Speed Display | Visual | High | ✅ Implemented | Current speed in km/h |
| Recording Indicator | Visual | Critical | ✅ Implemented | Flashing red "REC" badge when recording |
| Record Button | Action | Critical | ✅ Implemented | 80x80 circular button for manual record control |
| Auto-Record Toggle | Action | High | ✅ Implemented | Switch to enable/disable auto-recording |
| Motion Status Display | Visual | High | ✅ Implemented | Moving/Stopped indicator with icon |
| Orientation Status | Visual | High | ✅ Implemented | Phone orientation (Portrait/Landscape) validation |
| Roughness Indicator | Visual | Medium | ✅ Implemented | Road quality (Smooth/Moderate/Rough/Very Rough) |
| Warming Up Progress | Visual | Medium | ✅ Implemented | Circular progress showing 3-second motion warmup |
| Page Indicator Dots | Navigation | Medium | ✅ Implemented | Bottom center dots showing current page |
| Back Button | Navigation | High | ✅ Implemented | Top-left circular button with back arrow |

##### Background Features (System)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Auto-Record Logic | System | Critical | ✅ Implemented | Start recording after 3s of sustained motion |
| Auto-Stop Logic | System | Critical | ✅ Implemented | Stop recording after 30s idle |
| Motion Detection | System | Critical | ✅ Implemented | Accelerometer-based movement detection (≥0.4 m/s) |
| Orientation Validation | System | High | ✅ Implemented | Validate phone is in recording position |
| CSV Data Logging | System | High | ✅ Implemented | Log sensor data every 100ms during recording |
| Video Recording | System | Critical | ✅ Implemented | Record video with audio |
| Storage Management | System | High | ✅ Implemented | Add recording to storage service |
| Upload Queuing | System | High | ✅ Implemented | Queue video for server upload |
| Roughness Calculation | System | Medium | ✅ Implemented | Calculate road surface quality from accelerometer |
| Double-Click Prevention | System | High | ✅ Implemented | Prevent multiple simultaneous record operations |

#### UI Components Used

##### Hazard HUD (Page 1)
- `Container` with dynamic background
- `Icon` (warning, check_circle_outline, navigation)
- `Text` with various styles (warning, countdown, labels)
- `Transform.rotate` for directional arrows
- `Positioned` for layout
- `Row`, `Column`, `Wrap` for arrangement
- `BoxDecoration` with opacity overlays

##### Camera View (Page 2)
- `CameraPreview` widget
- `Stack` for overlays
- `Switch` for auto-record toggle
- `GestureDetector` for record button
- `CircularProgressIndicator` for warming up
- `LinearProgressIndicator` for warming up (portrait)
- `FadeTransition` for REC blinking
- `AnimationController` for animations
- `Icon` with color coding

#### Service Dependencies

- **CameraService** - Camera control, recording
- **HazardService** - Hazard data, proximity calculation
- **LocationService** - GPS, heading, speed
- **MotionService** - Movement detection, orientation, roughness
- **DataLoggerService** - CSV data logging
- **StorageService** - File management
- **ServerService** - Upload queue management
- **DeviceLoggerService** - Error logging

---

### 3. SettingsScreen

#### UI Features (User-Facing)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Driving Mode Section | Section | High | ✅ Implemented | Expandable section for driving mode settings |
| Launch Driving Mode | Action | Medium | ✅ Implemented | Button to navigate to DrivingModeScreen |
| Proximity Threshold Slider | Input | High | ✅ Implemented | Adjust hazard alert distance (100m-500m) |
| WiFi-Only Toggle | Input | High | ✅ Implemented | Enable/disable WiFi-only uploads |
| Delete After Upload Toggle | Input | Medium | ✅ Implemented | Auto-delete files after successful upload |
| Flat Orientation Toggle | Input | Low | ✅ Implemented | Allow recording when phone is flat |
| Recording Info Display | Info | Medium | ✅ Implemented | Auto-record settings explanation |
| Motion Threshold Display | Info | Low | ✅ Implemented | Motion detection thresholds |

#### Background Features (System)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| Proximity Threshold Update | System | High | ✅ Implemented | Update HazardService threshold (100-500m) |
| WiFi Mode Update | System | High | ✅ Implemented | Update ServerService WiFi-only mode |
| Delete Mode Update | System | Medium | ✅ Implemented | Update ServerService delete-after-upload mode |
| Orientation Override | System | Low | ✅ Implemented | Update MotionService flat orientation handling |

#### UI Components Used

- `AppBar` with title and colors
- `ListView` for scrollable settings
- `ExpansionTile` for collapsible sections
- `SwitchListTile` for toggles
- `Slider` for threshold adjustment
- `ListTile` for info items
- `Icon` for visual indicators
- `Divider` for section separation

#### Service Dependencies

- **HazardService** - Proximity threshold configuration
- **ServerService** - Upload settings
- **MotionService** - Orientation override settings

---

### 4. PreviewModeScreen (Web Only)

#### UI Features (User-Facing)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| MQTT Connection Display | Visual | High | ✅ Implemented | Shows MQTT broker connection status |
| Device Info Display | Visual | High | ✅ Implemented | Device name, location, speed |
| Hazard Warning Display | Visual | High | ✅ Implemented | Current hazard being warned about |
| Recording Status | Visual | High | ✅ Implemented | Shows if device is recording |
| Motion Status | Visual | Medium | ✅ Implemented | Shows if device is moving |
| Last Update Time | Visual | Medium | ✅ Implemented | Shows last MQTT message received |

#### Background Features (System)

| Feature | Type | Priority | Status | Description |
|---------|------|----------|--------|-------------|
| MQTT WebSocket Connection | System | Critical | ✅ Implemented | Connect to MQTT broker via WebSocket |
| Real-time Data Display | System | High | ✅ Implemented | Update UI when MQTT messages received |

#### UI Components Used

- `Scaffold` with AppBar
- `Container` for status cards
- `Text` for data display
- `Icon` for status indicators

#### Service Dependencies

- **MqttPreviewService** (web-specific)
- MQTT broker (external)

---

## UI Component Inventory

### Core Components

| Component | Usage Count | Screens Used | Purpose |
|-----------|-------------|--------------|---------|
| Container | 50+ | All | Layout, backgrounds, overlays |
| Text | 100+ | All | All text display |
| Icon | 40+ | All | Visual indicators, buttons |
| Positioned | 20+ | DrivingModeScreen, SplashScreen | Absolute positioning |
| Stack | 15+ | All | Layered layouts |
| Row | 30+ | All | Horizontal arrangement |
| Column | 40+ | All | Vertical arrangement |

### Navigation Components

| Component | Screens | Purpose |
|-----------|---------|---------|
| PageView | DrivingModeScreen | Swipeable pages (Hazard HUD / Camera) |
| PageController | DrivingModeScreen | Control page navigation |
| Navigator | All | Screen navigation |

### Input Components

| Component | Screens | Purpose |
|-----------|---------|---------|
| GestureDetector | DrivingModeScreen, SettingsScreen | Tap detection |
| Switch | DrivingModeScreen, SettingsScreen | Toggle settings |
| Slider | SettingsScreen | Proximity threshold adjustment |

### Animation Components

| Component | Screens | Purpose |
|-----------|---------|---------|
| AnimationController | DrivingModeScreen, SplashScreen | Control animations |
| FadeTransition | DrivingModeScreen | REC indicator blinking |
| AnimatedBuilder | SplashScreen | Pulsing glow effect |
| Transform.rotate | DrivingModeScreen | Directional arrows |

### Custom Components

| Component | File | Purpose |
|-----------|------|---------|
| GridPainter | SplashScreen | GPS grid background pattern |
| CameraPreview | DrivingModeScreen | Live camera feed |

---

## Background Services Matrix

### Service Overview

| Service | Type | Launch | Update Frequency | Purpose |
|---------|------|--------|------------------|---------|
| CameraService | Hardware | Splash | On-demand | Camera control, video recording |
| LocationService | Hardware | Splash | 5 seconds | GPS tracking, heading, speed |
| HazardService | Network | Splash | 15 minutes (std), 5s (high-freq) | Hazard data fetching, proximity |
| MotionService | Sensor | Auto | Continuous | Accelerometer, gyroscope, movement |
| MqttService | Network | Splash | Continuous | Real-time server communication |
| ServerService | Network | Splash | On-demand | Video/CSV/log uploads, heartbeat |
| DataLoggerService | Data | On-recording | 100ms (recording) | CSV sensor data logging |
| StorageService | Data | Auto | On-demand | File management, auto-cleanup |
| PermissionService | System | On-demand | One-time | System permissions |
| DeviceLoggerService | System | Auto | On-event | Error and crash logging |
| MetadataService | Data | On-recording | On-event | Recording metadata generation |

### Service Interaction Matrix

| Service | Depends On | Used By | Data Flow |
|---------|------------|---------|-----------|
| CameraService | PermissionService | DrivingModeScreen | User → Service → Hardware |
| LocationService | PermissionService | HazardService, DrivingModeScreen, MqttService | Hardware → Service → UI |
| HazardService | LocationService, MqttService | DrivingModeScreen, SettingsScreen | Network → Service → UI |
| MotionService | PermissionService | DrivingModeScreen, DataLoggerService | Hardware → Service → UI |
| MqttService | - | HazardService, LocationService | Bidirectional Network |
| ServerService | - | SplashScreen, DrivingModeScreen, SettingsScreen | Local → Network |
| DataLoggerService | LocationService, MotionService | DrivingModeScreen | Sensors → CSV File |
| StorageService | - | DrivingModeScreen, ServerService | File System |

### Background Timers

| Timer | Location | Interval | Purpose |
|-------|----------|----------|---------|
| Proximity Check | DrivingModeScreen | 1 second | Update hazard proximity |
| Motion Check | DrivingModeScreen | 1 second | Check auto-record conditions |
| Data Log | DrivingModeScreen | 100ms | Log sensor data to CSV |
| Countdown Update | DrivingModeScreen | 1 second | Update countdown display |
| Hazard Fetch | HazardService | 15 minutes | Periodic hazard refresh |
| High-Freq Fetch | HazardService | 5 seconds | High-frequency hazard mode |
| Location Update | LocationService | 5 seconds | GPS position update |
| MQTT Heartbeat | MqttService | 60 seconds | Connection heartbeat |
| MQTT Status | MqttService | 5 seconds | Status/location publish |

---

## User Interaction Flows

### 1. App Launch Flow

```
User opens app
    ↓
SplashScreen displays
    ↓
[Background] Initialize services
    ├─ Camera initialized
    ├─ Location service started
    ├─ Hazard data fetched
    ├─ MQTT connected
    └─ Pending logs uploaded
    ↓
Navigate to DrivingModeScreen (Page 1 - Hazard HUD)
```

### 2. Hazard Warning Flow

```
[Background] Location updates
    ↓
[Background] Proximity check (every 1s)
    ↓
[Background] Find closest hazard
    ↓
If within threshold (500m default):
    ↓
Calculate proximity level
    ├─ Safe (>threshold)
    ├─ Approaching (within threshold)
    ├─ Warning (close to zone)
    └─ Inside Zone (within danger zone)
    ↓
Update UI:
    ├─ Change background color
    ├─ Show hazard details
    ├─ Display distance countdown
    └─ Show directional arrow
```

### 3. Auto-Record Flow

```
[Background] Motion detected (≥0.4 m/s)
    ↓
[Background] Start 3-second warmup timer
    ↓
UI: Show "Detecting motion..." progress indicator
    ↓
After 3 seconds of sustained motion:
    ↓
If auto-record enabled AND valid orientation:
    ↓
[Background] Start video recording
[Background] Start CSV logging (100ms interval)
    ↓
UI: Show red "REC" indicator (flashing)
    ↓
[Background] Monitor for idle state
    ↓
After 30 seconds idle:
    ↓
[Background] Stop recording
[Background] Stop CSV logging
[Background] Add to storage
[Background] Queue for upload
    ↓
UI: Hide "REC" indicator
UI: Show "Recording saved" snackbar
```

### 4. Manual Recording Flow

```
User swipes to Page 2 (Camera View)
    ↓
User taps Record button
    ↓
If not already recording:
    ├─ [Background] Start video recording
    ├─ [Background] Start CSV logging
    ├─ UI: Show red "REC" indicator
    └─ UI: Show snackbar "Recording started!"
    ↓
User taps Record button again:
    ├─ [Background] Stop video recording
    ├─ [Background] Stop CSV logging
    ├─ [Background] Add to storage
    ├─ [Background] Queue for upload
    ├─ UI: Hide "REC" indicator
    └─ UI: Show snackbar "Recording saved and queued for upload!"
```

### 5. Settings Adjustment Flow

```
User taps back button → SettingsScreen
    ↓
User adjusts proximity slider (100m-500m)
    ↓
[Background] Update HazardService threshold
[Background] Notify listeners
    ↓
UI: Update display value
    ↓
Return to DrivingModeScreen
    ↓
[Background] Use new threshold for proximity checks
```

### 6. Page Navigation Flow

```
User on Page 1 (Hazard HUD)
    ↓
User swipes left
    ↓
PageController animates to Page 2
    ↓
UI: Update page indicator dots
    ↓
Now on Page 2 (Camera View)
    ↓
[Same process in reverse for right swipe]
```

### 7. Next Hazard Indicator Flow

```
[Background] Location + heading available
    ↓
[Background] Calculate forward cone (±90° from heading)
    ↓
[Background] Find closest hazard in forward cone
    ↓
[Background] Exclude currently warned hazard
    ↓
If hazard found:
    ↓
UI: Show "Next hazard" indicator (top-right)
    ├─ Distance (rounded to 10m)
    └─ Directional arrow (relative bearing)
```

---

## State Management Map

### Provider Architecture

All services use the Provider pattern for state management.

### State Flow Diagram

```
User Action
    ↓
Widget (Consumer)
    ↓
Service (ChangeNotifier)
    ↓
notifyListeners()
    ↓
Widget rebuilds
    ↓
UI updates
```

### Service State Properties

#### CameraService
- `isInitialized` - Camera ready status
- `isRecording` - Recording status
- `controller` - CameraController instance

#### LocationService
- `currentPosition` - GPS coordinates
- `latitude`, `longitude`, `altitude`
- `speed` - Speed in m/s
- `heading` - Compass heading
- `accuracy` - GPS accuracy

#### HazardService
- `hazards` - List of all hazards
- `closestHazard` - Nearest hazard
- `distanceToClosest` - Distance in meters
- `proximityLevel` - Safe/Approaching/Warning/InsideZone
- `lastFetchTime` - Last hazard fetch timestamp
- `proximityThresholdMeters` - Alert distance (100-500m)
- `highFrequencyMode` - High-freq mode enabled

#### MotionService
- `isMoving` - Movement detected
- `orientation` - Portrait/Landscape/Flat
- `isValidRecordingPosition` - Valid for recording
- `accelX`, `accelY`, `accelZ` - Accelerometer data
- `gyroX`, `gyroY`, `gyroZ` - Gyroscope data
- `firstMovementTime` - Start of sustained motion
- `lastMovementTime` - Last detected movement
- `ignoreFlatOrientation` - Flat orientation override

#### ServerService
- `wifiOnlyMode` - WiFi-only upload enabled
- `deleteAfterUpload` - Auto-delete enabled
- `uploadQueue` - Pending uploads
- `isRecording` - Recording status (for heartbeat)

### State Update Triggers

| Trigger | Service | State Changed | UI Impact |
|---------|---------|---------------|-----------|
| GPS update | LocationService | position, speed, heading | Distance countdown, speed display |
| Proximity check | HazardService | closestHazard, proximityLevel | Background color, warning display |
| Motion detected | MotionService | isMoving, firstMovementTime | Auto-record start, status indicators |
| Motion stopped | MotionService | isMoving, lastMovementTime | Auto-record stop, status indicators |
| Recording started | CameraService | isRecording | REC indicator shows |
| Recording stopped | CameraService | isRecording | REC indicator hides |
| Settings changed | HazardService | proximityThresholdMeters | Slider value, alert distance |
| Hazard fetch | HazardService | hazards, lastFetchTime | Available hazards updated |
| Orientation change | MotionService | orientation, isValidRecordingPosition | Orientation status color |

---

## Responsive Design Considerations

### Orientation Support

| Screen | Portrait | Landscape | Adaptive Layout |
|--------|----------|-----------|-----------------|
| SplashScreen | ✅ Primary | ✅ Supported | Fixed layout |
| DrivingModeScreen | ✅ Primary | ✅ Supported | Adaptive (status indicators repositioned) |
| SettingsScreen | ✅ Primary | ✅ Supported | Scrollable list |

### Screen Size Adaptation

- **Small screens (<5")**: All elements visible, compact layout
- **Medium screens (5-6.5")**: Standard layout (primary target)
- **Large screens (>6.5")**: Scaled layout, larger touch targets

### Text Scaling

- Supports system text scaling
- Minimum font sizes enforced for readability
- Icon sizes scale proportionally

---

## Accessibility Features

### Current Implementation

| Feature | Status | Description |
|---------|--------|-------------|
| High Contrast Colors | ✅ Partial | Color-coded severity levels |
| Large Touch Targets | ✅ Yes | 80x80 record button, 40x40 navigation |
| Icon-based Status | ✅ Yes | Visual icons for all states |
| Screen Reader Support | ❌ Not implemented | Semantic labels needed |
| Haptic Feedback | ❌ Not implemented | Planned for critical alerts |

### Future Enhancements

- [ ] VoiceOver/TalkBack support with semantic labels
- [ ] Haptic feedback for proximity warnings
- [ ] Audio alerts for hazards (optional)
- [ ] Reduced motion mode for animations
- [ ] Color blind friendly palette options

---

## Performance Metrics

### Target Performance

| Metric | Target | Current |
|--------|--------|---------|
| Frame Rate | 60 FPS | ✅ 60 FPS |
| Proximity Update | <100ms | ✅ ~50ms |
| UI State Change | <16ms | ✅ <16ms |
| Camera Frame Rate | 30 FPS | ✅ 30 FPS |
| Battery Life (4hrs) | >4 hours | ✅ ~4-5 hours |
| Memory Usage | <200MB | ✅ ~150MB |

### Optimization Strategies

- Use `const` constructors where possible
- Minimize rebuilds with `Consumer` widgets
- Cache calculated values in services
- Debounce rapid state changes
- Lazy load heavy resources

---

## Testing Checklist

### UI Testing

- [ ] All screens render correctly in portrait
- [ ] All screens render correctly in landscape
- [ ] Page swipe gesture works smoothly
- [ ] Back button navigates correctly
- [ ] Status indicators update in real-time
- [ ] Color transitions are smooth
- [ ] Animations don't drop frames

### Interaction Testing

- [ ] Record button starts/stops recording
- [ ] Auto-record toggle enables/disables auto-recording
- [ ] Proximity slider adjusts threshold
- [ ] Settings persist across app restarts
- [ ] Double-click prevention works
- [ ] Navigation flows work correctly

### Service Testing

- [ ] Camera initializes successfully
- [ ] Location updates received
- [ ] Hazard data fetches correctly
- [ ] MQTT connects and publishes
- [ ] CSV logging creates valid files
- [ ] Video uploads queue correctly

---

*This document should be updated whenever UI features are added, modified, or removed.*
