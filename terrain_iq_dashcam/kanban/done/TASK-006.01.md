---
id: TASK-006.01
title: Add Flutter Simulation option to simulator
type: feature
priority: high
assignee: agent
validation_status: passed
created_at: 2025-10-12T19:25:00.000000
updated_at: 2025-10-12T16:18:23.878203
completed_at: 2025-10-12T16:18:16.665270
tags: [simulator, flutter, mqtt, integration]
---

# Add Flutter Simulation option to simulator

## Description

Extend the web-based simulator to support loading and controlling the actual Flutter app instead of HTML previews. This will allow real-time testing of the Flutter application through MQTT commands from the simulator controls.

## Use Case

Developers and testers need to see how the actual Flutter app behaves with different configurations without manually changing app settings. By integrating MQTT control, the simulator can send commands to the Flutter app and visualize real Flutter rendering instead of HTML mockups.

## Acceptance Criteria

- [ ] Add "Load Flutter App" button to simulator interface
- [ ] Button switches from HTML preview to Flutter app container
- [ ] Flutter app loads in phone simulator container
- [ ] MQTT connection established between simulator and Flutter app
- [ ] Preview mode activated in Flutter app via MQTT command
- [ ] Simulator controls send MQTT messages to update Flutter app state
- [ ] Flutter app reflects distance, severity, speed, hazard type changes in real-time
- [ ] Recording, motion, orientation controls work via MQTT
- [ ] Can toggle between HTML simulator and Flutter app modes
- [ ] Add documentation for MQTT command protocol

## Test Data

### Good Samples
_No good samples defined_

### Bad Samples
_No bad samples defined_

## Notes

- Related to TASK-006 (simulator enhancements)
- Requires MQTT broker running (192.168.8.105:1883 or local for testing)
- Flutter app must support "preview mode" that accepts external control
- Consider using WebView or iframe for Flutter web build integration
- Alternative: Use Flutter web build served from same server
- Security: Ensure preview mode is clearly indicated and disabled in production
- [2025-10-12 16:18] [2025-10-12 16:15] COMPLETED: Flutter simulation integration with MQTT control. All acceptance criteria met. Preview mode detection, MQTT integration, icon rendering fix, 3 view modes, and mock server route all implemented. Commit: 00dabce
