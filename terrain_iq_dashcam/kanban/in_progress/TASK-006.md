---
id: TASK-006
title: Add screen navigation to simulator Examples tab
type: bug
priority: high
assignee: agent
validation_status: pending
created_at: 2025-10-12T06:08:54.456688
updated_at: 2025-10-12T19:20:55.626Z
completed_at: null
tags: [simulator, ui, enhancement]
---

# Add screen navigation to simulator Examples tab

## Description

Implement buttons to toggle between Hazard view, Camera view, Settings, and Left Nav screens for each scenario. Allow users to see how different screens would appear in each scenario configuration.

## Use Case

Users testing the simulator need to understand how different app screens (Hazard HUD, Camera view, Settings, Left Nav) would appear for each scenario configuration. This feature will allow them to visualize the complete user experience across all screens.

## Acceptance Criteria

- [ ] Add screen navigation buttons to Examples tab
- [ ] Implement Hazard view display
- [ ] Implement Camera view display
- [ ] Implement Settings screen mockup
- [ ] Implement Left Nav menu mockup
- [ ] Ensure navigation maintains current scenario configuration
- [ ] Add smooth transitions between screens
- [ ] Update documentation with navigation feature

## Test Data

### Good Samples
_No good samples defined_

### Bad Samples
_No bad samples defined_

## Subtasks

- [x] Add View Mode selector to Controls panel
- [x] Wire View Mode selector to existing page navigation
- [x] Sync dropdown value with page dot clicks
- [x] Fix sharp turn arrow to point forward
- [x] Test all view modes in simulator
- [x] Add Video Layout toggle (PIP vs Docked)
- [x] Implement docked video layout CSS for portrait
- [x] Implement docked video layout CSS for landscape
- [ ] Update camera placeholder with road background
- [x] Test video layouts in both orientations

## Notes

- [2025-10-12 15:45] Analysis: app_simulator.html is 2000+ lines with complex state management
- Current simulator uses renderScenarioPreviews() to show static preview images
- Full screen navigation requires: (1) Settings screen mockup, (2) Left Nav mockup, (3) Refactored state management to support view switching
- Complexity: High - requires significant refactoring of simulator architecture
- Recommendation: Run automated tests first to establish baseline, then implement incrementally
- [2025-10-12 17:00] New requirement: Add state change functionality to main simulator
- [2025-10-12 17:15] COMPLETED: Added View Mode selector in Controls panel
- View Mode dropdown allows switching between 3 existing views: HUD Only, HUD with Camera PIP, Camera Fullscreen
- Selector syncs with page dot navigation - both work together
- Fixed sharp turn arrow to point forward (↑) for better driver clarity
- Implementation leverages existing page navigation system instead of creating new layouts
- [2025-10-12 17:30] IN PROGRESS: Added Video Layout toggle system
- Implemented Picture-in-Picture vs Docked video layout modes
- Docked portrait: Video at top 1/3, warnings below (no overlap)
- Docked landscape: Video right-aligned 1/3, warnings left (no overlap)
- Enhanced camera placeholder to use road view background image
- Video layouts dynamically adapt to orientation changes
- User can toggle between PIP and Docked modes in Controls panel
- TODO: Add actual road_view.jpg image to assets/images/ directory
