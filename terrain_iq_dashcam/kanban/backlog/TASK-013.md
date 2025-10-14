---
id: TASK-013
title: Setup Appium for Real Device Automation
type: feature
priority: high
assignee: agent
validation_status: pending
created_at: 2025-10-14T08:21:24.123456
updated_at: 2025-10-14T08:21:24.123456
completed_at: None
tags: [testing, appium, automation, e2e]
---

# Setup Appium for Real Device Automation

## Description

Configure Appium testing framework for iOS and Android. Create test scripts that can run on real devices and emulators. Include automated tests for: app installation, sensor simulation, camera functionality, auto-record workflow, GPS tracking, and full end-to-end recording scenarios. Integrate with CI/CD pipeline.

## Use Case

Enable fully automated testing on real iOS and Android devices without manual intervention. Test actual app behavior with real sensors, camera, and GPS. Support continuous integration and automated regression testing. Allow testing across multiple device types and OS versions.

## Acceptance Criteria

- [ ] Appium server installed and configured
- [ ] iOS XCUITest driver installed and working
- [ ] Android UiAutomator2 driver installed and working
- [ ] Test scripts can launch app on iOS device
- [ ] Test scripts can launch app on Android device
- [ ] Sensor simulation working (accelerometer/gyroscope)
- [ ] GPS location simulation implemented
- [ ] Camera permission handling automated
- [ ] App installation test passing
- [ ] Auto-record workflow test passing
- [ ] Full E2E recording test passing
- [ ] Tests can run in parallel on multiple devices
- [ ] CI/CD integration configured
- [ ] Test execution time under 10 minutes

## Subtasks

- [ ] Install Appium globally (npm install -g appium)
- [ ] Install XCUITest driver for iOS
- [ ] Install UiAutomator2 driver for Android
- [ ] Create test/ appium/ directory structure
- [ ] Create iOS capabilities configuration
- [ ] Create Android capabilities configuration
- [ ] Implement app installation test
- [ ] Create element locator utilities
- [ ] Implement navigation test (splash to driving mode)
- [ ] Create sensor simulation utilities
- [ ] Implement motion detection test with simulated data
- [ ] Implement auto-record start test
- [ ] Implement auto-record stop test
- [ ] Create GPS simulation utilities
- [ ] Implement location tracking test
- [ ] Create full E2E recording scenario test
- [ ] Add parallel test execution support
- [ ] Create CI/CD integration script
- [ ] Document Appium setup and usage

## Test Data

### Good Samples

**iOS Device Capabilities:**
```json
{
  "platformName": "iOS",
  "platformVersion": "17.0",
  "deviceName": "iPhone 15 Pro",
  "app": "/path/to/TerrainIQ.app",
  "automationName": "XCUITest",
  "noReset": false
}
```

**Android Device Capabilities:**
```json
{
  "platformName": "Android",
  "platformVersion": "14.0",
  "deviceName": "Pixel 8",
  "app": "/path/to/terrain-iq.apk",
  "automationName": "UiAutomator2",
  "noReset": false
}
```

**Sensor Simulation:**
- Shake gesture (iOS): `driver.execute('mobile: shake')`
- Accelerometer data injection
- GPS coordinates: 37.7749, -122.4194

### Bad Samples

**Error Cases:**
- App not installed
- Permission denied
- Device offline
- Sensor unavailable

## Notes

- Appium requires Xcode command line tools for iOS
- Android requires SDK platform tools
- Use environment variables for device IDs
- Consider device farm integration (BrowserStack, Sauce Labs)
- Test on multiple OS versions (iOS 15-17, Android 12-14)
- Store test results in JSON format
- Include video recording on failure
- Add retry logic for flaky tests
