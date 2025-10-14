# TerrainIQ Dashcam - Requirements Document

## Project Overview

**App Name:** TerrainIQ Dashcam
**Platform:** iOS (Flutter)
**Purpose:** Road intelligence system that provides real-time hazard warnings and dashcam recording capabilities for drivers
**Developer:** IntelliMass.ai

---

## Core Features

### 1. Dashcam Recording
- **Video Recording:** High-quality video recording using device rear camera
- **Auto-Recording:** Automatically starts recording when motion is detected (vehicle moving)
- **Storage Management:** Videos saved to device storage with automatic cleanup
- **Recording Indicators:** Visual indicators showing recording status

### 2. Hazard Detection & Warnings

#### Hazard Data
- **Server Integration:** Fetches hazards from backend server (192.168.8.105:3000)
- **Fetch Radius:** Default 200km, high-frequency mode uses 50km
- **Update Frequency:** Every 15 minutes (standard), every 5 seconds (high-frequency mode)
- **Hazard Properties:**
  - Location (lat/lon)
  - Severity (1-10 scale)
  - Labels (multiple tags per hazard)
  - Zone radius (danger zone size in meters)
  - Detection statistics (times detected, last detected date)
  - Driver notes

#### Proximity Warnings
- **Proximity Threshold:** Configurable 100m-500m (default: 500m)
- **Proximity Levels:**
  - **Safe:** No hazards nearby
  - **Approaching:** Within proximity threshold
  - **Warning:** Close to hazard zone
  - **Inside Zone:** Within hazard danger zone
- **Real-time Updates:** Proximity checked every second
- **Visual Feedback:** Background color changes based on proximity and severity:
  - Blue: Safe
  - Yellow: Low severity hazard
  - Orange: Medium severity (5-7)
  - Red: High severity (8-10) within 250m

#### Next Hazard Indicator
- **Forward Direction Detection:** Shows next hazard in forward direction of travel (±90° cone)
- **Filtering:** Excludes hazard currently being warned about
- **Display:** Shows distance and directional arrow in top-right corner
- **Tap to View:** Clicking opens map view showing hazards within 1000m

### 3. Location Services
- **GPS Tracking:** Continuous location tracking
- **Heading Detection:** Compass heading for directional awareness
- **Speed Monitoring:** Real-time speed in km/h
- **Update Frequency:** Location updates every 5 seconds

### 4. Motion Detection
- **Accelerometer:** Detects vehicle movement
- **Orientation:** Landscape/portrait detection with recording position validation
- **Road Roughness:** Measures road surface quality (smooth, moderate, rough, very rough)
- **Movement Threshold:** Auto-start recording when moving

### 5. MQTT Communication
- **Broker:** 192.168.8.105:1883
- **Device Identification:** Unique device ID per session
- **Published Topics:**
  - Location updates (every 5s)
  - Status updates (every 5s)
  - Proximity alerts (on change)
  - Heartbeat (every 60s)
  - Recording state changes
- **Subscribed Topics:**
  - Commands (e.g., enable high-frequency mode)

### 6. User Interface

#### Driving Mode Screen (Main UI)
**Page View with 2 Pages:**

**Page 1: Hazard HUD (Default)**
- Large full-screen hazard warnings
- Dynamic background colors
- Proximity countdown (distance to hazard)
- Directional arrow pointing to hazard
- Hazard type and severity display
- Status indicators (recording, motion, orientation, roughness)
- "Next Hazard" indicator (top-right)
- "All Clear" state when no hazards

**Page 2: Camera View**
- Full-screen camera preview
- Camera orientation indicator (Front/Rear/Left/Right + compass direction)
- Current speed display
- Recording indicator (red "REC" badge)

**Navigation:**
- Swipe between pages
- Page indicators (dots at bottom)
- Back button (top-left)

#### Splash Screen
- TerrainIQ branding with truck logo
- Animated loading indicators
- GPS grid background
- Initializes all services before navigation

### 7. Service Architecture

**Services (Provider Pattern):**
1. **CameraService:** Camera initialization and recording management
2. **LocationService:** GPS tracking and heading detection
3. **HazardService:** Hazard fetching and proximity calculations
4. **MotionService:** Accelerometer and movement detection
5. **MqttService:** Real-time communication with server
6. **ServerService:** HTTP API communication
7. **StorageService:** File management
8. **PermissionService:** System permissions handling
9. **DataLoggerService:** Local data logging
10. **DeviceLoggerService:** Error and crash logging

---

## Technical Requirements

### Backend API

**Base URL:** `http://192.168.8.105:3000`

**Endpoints:**
- `POST /get_hazards` - Fetch hazards within radius
  - Body: `{ lat, lon, radius_km }`
  - Returns: `{ hazards: [...] }`

- `POST /add_hazard` - Add new hazard (from web interface)
  - Body: `{ lat, lon, severity, labels, zone_m, notes }`

- `DELETE /remove_hazard/:id` - Remove hazard

- `GET /all_hazards` - Get all hazards

- `GET /hazard-map` - Web interface for hazard management

**MQTT Broker:**
- Host: 192.168.8.105
- Port: 1883
- QoS: At least once (1)

### Data Models

#### Hazard
```dart
{
  lon: double,
  lat: double,
  zoneRadiusMeters: double,
  lastDetected: DateTime,
  timesDetected6Months: int,
  severity: int (1-10),
  labels: List<String>,
  driverNotes: List<DriverNote>
}
```

#### ProximityLevel
```dart
enum ProximityLevel {
  safe,           // No hazards nearby
  approaching,    // Within threshold
  warning,        // Close to zone
  insideZone      // Within danger zone
}
```

### Configuration

**App Config** (`lib/config.dart`):
- Server URL: `http://192.168.8.105:3000`
- MQTT Broker: `192.168.8.105:1883`
- Update intervals configurable

**Permissions Required:**
- Camera
- Location (Always)
- Motion & Fitness
- Microphone (for video audio)

---

## User Flows

### 1. App Launch
1. Splash screen displays
2. Initialize services (camera, location, MQTT, hazards)
3. Request permissions if needed
4. Fetch initial hazard data
5. Navigate to Driving Mode

### 2. Active Driving
1. GPS tracks location continuously
2. Motion detector identifies movement
3. Auto-start recording if moving
4. Update proximity every second
5. Display warnings when hazards nearby
6. Publish location/status via MQTT every 5s

### 3. Hazard Warning Flow
1. Detect hazard within proximity threshold
2. Calculate proximity level
3. Update UI background color
4. Show hazard details (type, severity, distance)
5. Display directional arrow
6. Show countdown distance
7. Clear warning when out of range

### 4. Next Hazard View
1. User taps "Next Hazard" indicator
2. Navigate to map view
3. Display hazards within 1000m
4. Show current location marker
5. Interactive map with hazard markers

---

## Design Guidelines

### Color Scheme
- **Primary Blue:** `#1E88E5` (safe state, branding)
- **Safe:** `#1976D2` (blue)
- **Low Risk:** `#FBC02D` (yellow)
- **Medium Risk:** `#FF6F00` (orange)
- **High Risk:** `#D32F2F` (red - only within 250m and severity ≥8)

### Typography
- **Title Font:** Sans-serif, light weight, 48pt (splash screen)
- **Warning Text:** Bold, 36pt (hazard warnings)
- **Countdown:** Extra bold, 80pt (distance display)
- **Status Text:** Regular, 14-18pt (info display)

### Spacing
- Standard padding: 16-24px
- Large spacing: 32px (major sections)
- Compact spacing: 8-12px (related items)

---

## Performance Requirements

### Response Times
- Hazard proximity update: <100ms
- Location update processing: <50ms
- UI state changes: <16ms (60fps)
- Camera frame rate: 30fps minimum

### Resource Usage
- Battery: Optimized for continuous use (4+ hours)
- Storage: Auto-cleanup old recordings
- Network: Minimal data usage (<5MB/hour)
- Memory: <200MB typical usage

---

## Known Issues & Future Improvements

### Current Known Issues
- None (all previously reported issues fixed)

### Future Enhancements
1. **Offline Mode:** Cache hazards for offline use
2. **Route Planning:** Show hazards along planned route
3. **Hazard Reporting:** Allow drivers to report new hazards
4. **Analytics Dashboard:** Web interface for hazard statistics
5. **Multi-language Support:** Internationalization
6. **Apple CarPlay Integration:** Display on car screen
7. **Cloud Backup:** Automatic video upload to cloud storage
8. **Hazard Categories:** Filter by hazard type
9. **Community Features:** Share hazard data with other drivers
10. **Advanced Alerts:** Audio warnings, haptic feedback

---

## Version History

### v1.0 (Current)
- Initial release
- Core hazard warning system
- Dashcam recording
- MQTT communication
- "Next Hazard" indicator
- Camera view integration
- Proximity-based warnings
- Motion detection

---

## Interactive App Simulator

### Overview
An interactive web-based simulator has been created to demonstrate app functionality and requirements. The simulator allows stakeholders and developers to visualize how the app responds to different conditions without needing to build and run the actual app.

### Simulator Features

#### 1. Interactive Controls
- **Distance Slider:** Adjust hazard distance (0-1000m) to see proximity warnings
- **Severity Slider:** Change hazard severity (1-10 scale) to see color changes
- **Speed Control:** Adjust vehicle speed (0-120 km/h)
- **Hazard Type Selector:** Choose from different hazard types (Pothole, Sharp Turn, Debris, etc.)
- **Recording Controls:** Toggle auto-record mode and manual recording
- **Motion Detection Toggle:** Simulate moving/stopped vehicle states
- **Orientation Toggle:** Switch between portrait and landscape modes
- **Quick Presets:** One-click scenarios (All Clear, Warning, Danger, Inside Zone)

#### 2. View Modes
The simulator displays three different view modes matching the actual app:
- **View 1 - Hazard HUD Only:** Full-screen hazard warnings with dynamic background colors
- **View 2 - HUD with Camera PIP:** Hazard warnings with picture-in-picture camera preview
- **View 3 - Camera with Overlay:** Full camera view with hazard warning overlay

Users can swipe between views using page indicator dots at the bottom.

#### 3. Three-Tab Interface

**Controls Tab:**
- Interactive sliders and toggles for real-time simulation
- Immediate visual feedback on the phone simulator
- Annotations toggle to explain UI elements

**Requirements Tab:**
- Complete requirements documentation
- Feature badges for quick reference
- Color-coded warning levels explanation
- Usage instructions

**Examples Tab:**
- 12 pre-configured usage scenarios
- Portrait/Landscape/Both orientation toggle
- Scenario categories:
  - Critical warnings (150m, Level 10)
  - Warning states (300m, Level 8)
  - Moderate hazards (500m, Level 6)
  - Minor hazards (450m, Level 3)
  - All clear states
  - Stationary modes
  - Camera view examples
  - Picture-in-picture mode
  - Landscape orientations
  - Multiple hazards
  - Manual recording override
- "Try It" button on each scenario loads that configuration into the main simulator
- Scroll position memory when switching tabs

#### 4. Responsive Design
- Full-screen simulator display
- Examples tab hides the phone simulator to maximize space
- Smooth transitions between portrait/landscape layouts
- Proper CSS Grid implementation for flexible layouts

### File Location
`app_simulator.html` - Single-file HTML application with embedded CSS and JavaScript

### Usage
Open `app_simulator.html` in a web browser to interact with the simulator. No build process or dependencies required.

---

## Development Notes

### Recent Fixes (Latest Session)
1. **Next Hazard Distance Issue** - Fixed logic to show nearby hazards instead of distant ones (was showing 24,890m)
   - Changed filtering to only skip the hazard currently being warned about
   - Now considers all hazards in forward cone regardless of proximity threshold
   - File: `lib/services/hazard_service.dart:275-278`

2. **Camera Initialization** - Added camera service initialization during app startup
   - Camera now initializes in splash screen
   - File: `lib/screens/splash_screen.dart:48-50`

3. **Interactive Simulator Development** - Created comprehensive web-based simulator
   - Demonstrates all app functionality without building the app
   - Supports all view modes (HUD, Camera, PIP)
   - 12 predefined usage scenarios with "Try It" functionality
   - Scroll position memory and responsive layout
   - File: `app_simulator.html`

### Testing Checklist
- [ ] Hazard warnings appear at correct distances
- [ ] "Next Hazard" shows realistic values (100-500m range)
- [ ] Camera works when swiping to camera page
- [ ] Background colors change based on proximity
- [ ] Recording auto-starts when moving
- [ ] MQTT connection established
- [ ] Location updates received
- [ ] Map view shows hazards within 1000m

**Simulator Testing:**
- [x] Controls update phone display in real-time
- [x] All three view modes render correctly
- [x] Orientation toggle works (portrait/landscape)
- [x] Examples tab shows 12 scenarios
- [x] "Try It" buttons load configurations correctly
- [x] Scroll position persists when switching tabs
- [x] Color coding matches severity levels (1=best, 10=worst)

---

## Future Enhancements

### Planned Features
1. **Screen Navigation in Examples:**
   - Add buttons to toggle between Hazard view, Camera view, Settings, and Left Nav
   - Show how different screens would appear for each scenario
   - Design Settings screen with configuration options
   - Design Left Nav menu with My Account, Settings options

2. **Settings Screen Design:**
   - Proximity threshold configuration
   - Update frequency settings
   - Hazard type filters
   - Recording quality options
   - MQTT connection settings
   - About/Version information

3. **Left Navigation Menu:**
   - My Account
   - Settings
   - Hazard History
   - Recordings Gallery
   - Help & Support
   - Logout

4. **Additional Simulator Features:**
   - Map view simulation
   - Hazard reporting interface
   - Statistics dashboard preview
   - Multi-language support preview

---

## Contact & Support

**Developer:** IntelliMass.ai
**Project Repository:** [Add repository URL]
**Issue Tracking:** [Add issue tracker URL]

---

*Last Updated: 2025-10-12*
