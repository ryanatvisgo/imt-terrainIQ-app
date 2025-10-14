---
id: TASK-015
title: Create E2E Test Orchestration Script
type: feature
priority: high
assignee: agent
validation_status: pending
created_at: 2025-10-14T08:21:30.936062
updated_at: 2025-10-14T08:21:30.936062
completed_at: None
tags: []
---

# Create E2E Test Orchestration Script

## Description

Build comprehensive end-to-end test automation script (similar to test_csv_upload_e2e.sh) that orchestrates all test suites: Flutter integration tests, Appium tests, web tests, and server tests. Include environment setup, test execution, result aggregation, HTML report generation, and cleanup. Support parallel test execution and CI/CD integration.

## Use Case

Provide single command to run all test suites across all platforms. Enable automated regression testing in CI/CD pipeline. Generate comprehensive test reports combining results from Flutter, Appium, web, and server tests. Simplify testing for developers and QA teams.

## Acceptance Criteria

- [ ] Single test script created (test_all_e2e.sh)
- [ ] Script checks all prerequisites (Flutter, Node.js, Appium)
- [ ] Auto-starts required services (server, MQTT)
- [ ] Runs Flutter integration tests
- [ ] Runs Appium tests on iOS/Android
- [ ] Runs web tests with Playwright
- [ ] Runs server endpoint tests
- [ ] Supports parallel test execution
- [ ] Aggregates results from all test suites
- [ ] Generates HTML test report
- [ ] Calculates overall pass rate
- [ ] Handles test failures gracefully
- [ ] Cleans up resources after completion
- [ ] CI/CD integration configured
- [ ] Execution time under 15 minutes

## Subtasks

- [ ] Create test_all_e2e.sh script
- [ ] Add prerequisite checking (Flutter, Node, Appium)
- [ ] Implement service startup (server, MQTT broker)
- [ ] Add Flutter integration test execution
- [ ] Add Appium test execution (iOS + Android)
- [ ] Add Playwright web test execution
- [ ] Add server endpoint test execution
- [ ] Implement parallel test execution
- [ ] Create result aggregation logic
- [ ] Implement HTML report generation
- [ ] Add test duration tracking
- [ ] Add pass/fail rate calculation
- [ ] Implement cleanup procedures
- [ ] Add error handling and logging
- [ ] Create CI/CD workflow file (.github/workflows/test.yml)
- [ ] Add usage documentation
- [ ] Test on macOS, Linux, Windows

## Test Data

### Good Samples

**Test Report Output:**
```
╔══════════════════════════════════════════════════╗
║   TerrainIQ Complete Test Suite Results         ║
╚══════════════════════════════════════════════════╝

📱 Flutter Integration Tests:     ✅ 15/15 passed
📱 Appium iOS Tests:              ✅ 12/12 passed
🤖 Appium Android Tests:          ✅ 12/12 passed
🌐 Playwright Web Tests:          ✅ 8/8 passed
🖥️  Server Endpoint Tests:         ✅ 7/7 passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Total Tests: 54
✅ Passed: 54
❌ Failed: 0
📈 Pass Rate: 100.0%
⏱️  Duration: 12m 34s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Full report: test_report_20251014_083000.html
```

### Bad Samples

**Error Cases:**
- Flutter not installed
- No iOS simulator available
- Appium server not running
- Server startup failed
- Test timeout exceeded

## Notes

- Run tests in order: server → Flutter → Appium → web
- Use tmux or GNU parallel for parallel execution
- Store logs in test_logs/ directory
- Generate both HTML and JSON reports
- Include screenshots of failures
- Email report on CI/CD failures
- Support --quick mode (skip slow tests)
- Support --platform flag (ios, android, web)
- Add --retry flag for flaky tests
- Consider using test containers for isolation
