---
id: TASK-011
title: Create Flutter Integration Test Suite
type: feature
priority: critical
assignee: agent
validation_status: pending
created_at: 2025-10-14T08:20:39.989269
updated_at: 2025-10-14T08:20:39.989269
completed_at: None
tags: []
---

# Create Flutter Integration Test Suite

## Description

Implement comprehensive Flutter integration tests for camera, auto-record, motion detection, GPS, hazard detection, and full recording workflow. Tests should run on real devices/emulators and validate end-to-end functionality including sensor simulation and service integration.

## Use Case

Enable automated testing of Flutter app functionality on real devices and emulators. Validate camera recording, auto-record on motion, sensor data collection, GPS tracking, hazard detection, and server upload workflows without manual intervention.

## Acceptance Criteria

- [ ] Flutter integration test package configured in pubspec.yaml
- [ ] integration_test/ directory structure created
- [ ] Camera service initialization test implemented
- [ ] Auto-record on motion test with sensor simulation
- [ ] Motion detection service test with accelerometer data
- [ ] GPS/Location service test with mock coordinates
- [ ] Hazard detection and warning test
- [ ] Full recording workflow test (start to upload)
- [ ] CSV generation validation test
- [ ] Server upload integration test
- [ ] Test can run on iOS simulator/device
- [ ] Test can run on Android emulator/device
- [ ] Tests pass with 100% success rate
- [ ] Test execution time under 5 minutes

## Subtasks

- [ ] Setup integration_test package in pubspec.yaml
- [ ] Create integration_test/app_test.dart main file
- [ ] Implement camera initialization test
- [ ] Create sensor data mocking utilities
- [ ] Implement motion detection test (3s sustained motion)
- [ ] Implement auto-record start test
- [ ] Implement auto-record stop test (30s idle)
- [ ] Create GPS coordinate mocking
- [ ] Implement location service test
- [ ] Implement hazard proximity test
- [ ] Create full recording workflow test
- [ ] Implement CSV validation test
- [ ] Implement server upload mock/integration test
- [ ] Add test documentation and usage guide
- [ ] Create iOS test runner script
- [ ] Create Android test runner script

## Test Data

### Good Samples

**Motion Data:**
- Delta threshold: 0.8 m/s² (should trigger motion)
- Sustained motion: 3+ seconds (should start recording)
- Idle period: 30+ seconds (should stop recording)

**GPS Data:**
- Valid coordinates: 37.7749° N, 122.4194° W
- Speed: 10 m/s (36 km/h)
- Accuracy: 5 meters

**Hazard Data:**
- Critical hazard: severity=10, distance=150m (should show red warning)
- Moderate hazard: severity=6, distance=500m (should show orange warning)

### Bad Samples

**Motion Data:**
- Delta below threshold: 0.5 m/s² (should not trigger)
- Motion < 3 seconds (should not start recording)
- Idle < 30 seconds (should not stop recording)

**GPS Data:**
- Invalid coordinates: null, null
- No GPS signal

## Notes

- Integration tests require physical device or emulator with sensor support
- Use MethodChannel for sensor data injection on iOS
- Use intent injection for Android sensor simulation
- Mock server should be running for upload tests
- Tests should cleanup recorded files after completion
