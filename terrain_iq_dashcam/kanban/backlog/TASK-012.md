---
id: TASK-012
title: Build In-App Test Runner with Visual UI
type: feature
priority: critical
assignee: agent
validation_status: pending
created_at: 2025-10-14T08:21:07.873375
updated_at: 2025-10-14T08:21:07.873375
completed_at: None
tags: [testing, ui, automation]
---

# Build In-App Test Runner with Visual UI

## Description

Create a test runner screen built into the Flutter app that allows running automated tests from within the app itself. Display test results visually with pass/fail indicators, detailed logs, and export capabilities. Include tests for: camera init, motion detection, auto-record, GPS tracking, hazard detection, CSV generation, and server upload.

## Use Case

Allow developers and QA testers to run comprehensive automated tests directly on physical devices without external tools. Enable field testing, debugging, and validation in real-world conditions. Useful for testing sensor accuracy, camera functionality, and network conditions on actual hardware.

## Acceptance Criteria

- [ ] Test runner screen accessible from main menu
- [ ] Visual list of all available tests
- [ ] "Run All Tests" button implemented
- [ ] Individual test execution capability
- [ ] Real-time test progress display
- [ ] Pass/fail indicators with green/red colors
- [ ] Detailed test logs expandable for each test
- [ ] Test duration tracking
- [ ] Overall pass rate calculation
- [ ] Export test results to JSON/CSV
- [ ] Share test results via email/message
- [ ] Screenshot capture on test failure
- [ ] Device info display (OS, model, sensors)
- [ ] Test history with timestamps
- [ ] All core functionality tests included

## Subtasks

- [ ] Create TestRunnerScreen widget
- [ ] Design test result card UI component
- [ ] Implement test execution framework
- [ ] Create camera initialization test
- [ ] Create motion detection test
- [ ] Create auto-record trigger test
- [ ] Create GPS accuracy test
- [ ] Create hazard detection test
- [ ] Create CSV generation validation test
- [ ] Create server upload test
- [ ] Implement test result export to JSON
- [ ] Implement test result sharing
- [ ] Add screenshot capture on failure
- [ ] Create test history storage
- [ ] Add device info display
- [ ] Implement progress indicators
- [ ] Add search/filter for tests
- [ ] Create test documentation in-app

## Test Data

### Good Samples

**UI Elements:**
- Test list with 10+ tests
- Pass rate: 100% (all green)
- Test duration: < 60 seconds total
- Device info shows all sensors available

**Test Results:**
```json
{
  "timestamp": "2025-10-14T08:30:00Z",
  "device": "iPhone 15 Pro",
  "os": "iOS 17.0",
  "tests": [
    {"name": "Camera Init", "passed": true, "duration": 2.5},
    {"name": "Motion Detection", "passed": true, "duration": 5.2}
  ],
  "passRate": 1.0
}
```

### Bad Samples

**UI States:**
- Test failure with red indicator
- Missing sensor warning
- Network unavailable error
- Permission denied state

## Notes

- Add accessibility from Settings screen
- Consider debug/release build variants
- Include mock mode for tests without real sensors
- Add test scheduling for automated runs
- Consider adding performance benchmarks
- Export should include device logs
- Screenshots saved to app documents directory
- Test history limited to last 50 runs
