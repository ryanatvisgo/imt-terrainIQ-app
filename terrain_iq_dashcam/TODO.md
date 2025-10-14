# TerrainIQ Dashcam TODO List

## Current Session Todos - 2025-10-14

### In Progress
- [x] Fix iOS build errors (web-only imports)
  - Created stub files for non-web platforms
  - Implemented conditional imports for dart:html and dart:js
  - Fixed MqttService to skip on web platform

### Browser Testing Suite (HIGH PRIORITY)
- [ ] Create Playwright test suite for simulator integration
  - [ ] Add test for HTML simulator MQTT connection
  - [ ] Add test for Flutter app MQTT connection
  - [ ] Add test for preview parameter changes
  - [ ] Add test for HTML render verification
  - [ ] Add test for Flutter app render verification
- [ ] Improve logging in HTML simulator
- [ ] Improve logging in Flutter app

**User Request:** "when you try to set up the server you need browser based tests that allow you to test: launching the simulator, adjusting some preview parameters, confirming the HTML render is right, and then checking the Flutter Simulator is right also. Each app should be writing logs that make it easier."

### Test Suite Implementation (From Kanban Tasks)

#### TASK-011: Flutter Integration Test Suite (CRITICAL)
- [ ] Configure Flutter integration test package
- [ ] Implement camera service tests
- [ ] Create auto-record with sensor simulation tests
- [ ] Add motion detection tests
- [ ] Create GPS/Location service tests
- [ ] Add full recording workflow test

#### TASK-012: In-App Test Runner with Visual UI (CRITICAL)
- [ ] Create TestRunnerScreen widget
- [ ] Design test result card UI
- [ ] Implement test execution framework
- [ ] Add device info display
- [ ] Create test result export (JSON/CSV)

#### TASK-013: Appium for Real Device Automation (HIGH)
- [ ] Install and configure Appium
- [ ] Setup XCUITest driver (iOS)
- [ ] Setup UiAutomator2 driver (Android)
- [ ] Create sensor simulation utilities
- [ ] Implement full E2E recording tests

#### TASK-014: Flutter Web Test Suite with Playwright (MEDIUM)
- [ ] Configure Flutter for web platform
- [ ] Setup Playwright test framework
- [ ] Create mock sensor data for browser
- [ ] Implement visual regression tests
- [ ] Add cross-browser testing

#### TASK-015: E2E Test Orchestration Script (HIGH)
- [ ] Create test_all_e2e.sh script
- [ ] Implement parallel test execution
- [ ] Add result aggregation
- [ ] Generate HTML test report
- [ ] Configure CI/CD integration

#### TASK-016: Document Test Suite Architecture (MEDIUM)
- [ ] Create TESTING.md overview
- [ ] Document Flutter integration tests
- [ ] Add Appium setup guide
- [ ] Document web testing with Playwright
- [ ] Create troubleshooting guide

### Current Issues to Fix

#### MQTT Connection Issues
**Problem:** Flutter web app MQTT shows as disconnected in simulator
**Status:** Investigating
**Actions Needed:**
- Check browser console for JavaScript errors
- Verify MQTT.js library loading
- Add better error logging to both HTML simulator and Flutter app
- Create automated test to verify MQTT bidirectional communication

#### Server Connection Issues
**Problem:** Server heartbeat failing with CORS/network error
**Error:** `ClientException: Failed to fetch, uri=http://192.168.8.105:3000/heartbeat`
**Status:** Server is running but Flutter web can't reach it
**Actions Needed:**
- Add CORS headers to mock server
- Change Flutter web to use localhost:3000 instead of 192.168.8.105:3000
- Add server connectivity test

### Completed This Session ✅
- [x] Fixed iOS build errors (dart:html, dart:js not available)
- [x] Created conditional imports for web-only code
- [x] Created stub implementations for mobile platforms
- [x] Fixed MqttService infinite reconnection loop on web
- [x] Configured Flutter to run on fixed port (3201)
- [x] Started MQTT broker successfully (port 3301)
- [x] Started mock server successfully (port 3000)
- [x] Launched Flutter web app successfully

## Previous Session Work

### Git Repository Setup
- [x] Initialize git repository
- [x] Create comprehensive .gitignore
- [x] Push to GitHub: https://github.com/ryanatvisgo/imt-terrainIQ-app
- [x] Fix API key exposure in git history

### Kanban Tasks Created
- [x] TASK-011: Flutter Integration Test Suite
- [x] TASK-012: In-App Test Runner
- [x] TASK-013: Appium Real Device Automation
- [x] TASK-014: Flutter Web Test Suite
- [x] TASK-015: E2E Test Orchestration
- [x] TASK-016: Test Documentation

## System Architecture

### Running Services
- **MQTT Broker:** ws://localhost:3301 (Aedes)
- **Mock Server:** http://localhost:3000 (Node.js/Express)
- **Flutter Web:** http://localhost:3201 (Chrome)
- **HTML Simulator:** http://localhost:3000/simulator.html

### Files Modified This Session
- `lib/main.dart` - Added conditional imports, WebRouteHelper
- `lib/services/mqtt_service.dart` - Added kIsWeb check
- `lib/services/mqtt_preview_service_stub.dart` - Created stub for mobile
- `lib/utils/web_route_helper_stub.dart` - Created stub for mobile
- `lib/utils/web_route_helper_web.dart` - Created web-specific routing
- `lib/screens/preview_mode_screen.dart` - Added conditional import

### Test Infrastructure Needed
1. **Playwright Test Suite** (browser automation)
   - Test HTML simulator + Flutter web integration
   - Verify MQTT communication
   - Check UI rendering on both apps
   - Validate parameter changes propagate correctly

2. **Logging Improvements**
   - HTML simulator: Console logs for all MQTT events
   - Flutter app: Debug logs for connection state
   - MQTT broker: Connection/disconnection events
   - Mock server: Request/response logging

3. **CI/CD Integration**
   - GitHub Actions workflow
   - Automated test execution
   - Test result reporting
   - Screenshot capture on failures

## Notes
- Camera permissions persist when using fixed port (3201)
- Web platform limitations: no file system, no native MQTT client
- MqttPreviewServiceJs uses MQTT.js for web, MqttService for mobile
- Preview mode detected via port 3201 or URL hash #/preview
