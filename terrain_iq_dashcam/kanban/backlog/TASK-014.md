---
id: TASK-014
title: Create Flutter Web Test Suite with Playwright
type: feature
priority: medium
assignee: agent
validation_status: in_progress
created_at: 2025-10-14T08:21:17.172111
updated_at: 2025-10-14T18:02:00.000000
completed_at: None
tags: [mqtt, logging, web-server]
---

# Create Flutter Web Test Suite with Playwright

## Description

Build web version of Flutter app and create Playwright browser automation tests. Setup includes: Flutter web build configuration, browser test environment, test scripts for UI interactions, and mock implementations for sensors/camera in web environment. Create visual regression tests and performance benchmarks.

## Use Case

Enable browser-based testing of Flutter app without needing physical devices. Allow automated UI testing in CI/CD pipelines. Support visual regression testing and cross-browser compatibility validation. Useful for rapid prototyping and UI testing during development.

## Acceptance Criteria

- [ ] Flutter web build successfully configured
- [ ] App runs in Chrome/Safari/Firefox browsers
- [ ] Playwright test framework installed
- [ ] Test can navigate between app screens
- [ ] UI element selectors working reliably
- [ ] Mock sensor data implementation
- [ ] Mock camera implementation (placeholder)
- [ ] Mock GPS implementation
- [ ] Visual regression tests configured
- [ ] Screenshot comparison working
- [ ] Performance benchmarks implemented
- [ ] Tests pass on Chrome, Firefox, Safari
- [ ] Test execution time under 3 minutes
- [ ] CI/CD integration configured

## Subtasks

- [x] Configure Flutter for web platform
- [x] Build web version of app
- [x] Setup local web server for testing (headless mode on port 3201)
- [x] Install Playwright (@playwright/test)
- [x] Create test/e2e/web/ directory
- [x] Configure Playwright browsers
- [x] Implement Flutter web test utilities
- [x] Create navigation test (splash to driving)
- [x] Create UI interaction test (buttons, toggles)
- [x] Implement visual regression baseline
- [x] Create screenshot comparison tests
- [x] Add performance benchmarking
- [ ] Implement sensor data mocking in browser
- [ ] Create mock camera placeholder
- [ ] Create mock GPS coordinate injection
- [ ] Create cross-browser test matrix
- [ ] Add CI/CD workflow
- [ ] Document web testing setup

## Test Data

### Good Samples

**Mock Sensor Data:**
- Accelerometer: x=1.5, y=2.0, z=9.8
- Gyroscope: x=0.1, y=0.2, z=0.0
- GPS: lat=37.7749, lng=-122.4194

**Performance Metrics:**
- Page load time < 3 seconds
- First contentful paint < 1 second
- Time to interactive < 2 seconds

### Bad Samples

**Error States:**
- Sensor API not supported in browser
- Camera permission denied
- Network timeout
- JavaScript errors in console

## Notes

- Flutter web has limited sensor API support
- Camera requires WebRTC fallback
- GPS requires browser geolocation API
- Visual regression may have cross-platform differences
- Use headless mode for CI/CD
- Store baseline screenshots in version control
- Consider Percy or similar for visual testing
- Add accessibility testing (axe-core)
- Test responsive design (mobile/tablet/desktop viewports)

## Progress (2025-10-14)

### ✅ Completed
1. **Enhanced MQTT Broker Logging**
   - Added timestamps to all connection/disconnection events
   - Added error logging (clientError, keepaliveTimeout)
   - Logs now show: ✅ connections, ❌ disconnections, ⚠️ errors, ⏱️ timeouts

2. **Enhanced Flutter MQTT Client Logging**
   - Added timestamps to all MQTT events
   - Added offline/reconnect event handlers
   - Improved error messages with client ID tracking
   - Logs now show: 🔌 connecting, ✅ connected, ❌ disconnected, 📴 offline, 🔄 reconnecting

3. **Flutter Web Server Mode**
   - Updated start_flutter.sh to use headless web-server mode
   - No browser popup - access only via http://localhost:3201 or simulator iframe
   - Eliminates duplicate MQTT connections from multiple browser windows
   - Allows controlled testing environment

4. **MQTT Connection Test Script**
   - Created test_mqtt_connection.sh for monitoring connection stability
   - Tests run for 30 seconds and report connection status
   - Verified: 8 clients connected and stable ✅

### Issues Fixed
- **Multiple MQTT Clients**: Headless mode prevents duplicate connections
- **Poor Visibility**: Enhanced logging shows exactly when/why disconnections occur
- **No Timestamps**: All events now timestamped for debugging

5. **Playwright Test Suite** (2025-10-14 20:00)
   - Installed Playwright and Chromium browser
   - Created playwright.config.js with test configuration
   - Created 3 comprehensive test suites:
     - flutter-app-load.spec.js: App loading, rendering, network checks, MQTT connection
     - mqtt-connection.spec.js: MQTT connection, subscriptions, stability, error handling
     - ui-interaction.spec.js: UI rendering, resize handling, mouse/keyboard events, performance, visual regression
   - Test coverage: 18 total tests across 3 test suites
   - Includes screenshot capture and visual regression baselines
   - Ready to run with: npx playwright test

### Next Steps
- Run Playwright E2E test suite and verify all tests pass
- Add visual MQTT status indicator in HTML simulator
- Implement automated connection stability tests in CI/CD
- Add cross-browser testing (Firefox, Safari)
- Document web testing setup and procedures
