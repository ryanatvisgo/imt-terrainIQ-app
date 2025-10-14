---
id: TASK-001
title: Create interactive web-based app simulator
type: feature
priority: high
assignee: agent
validation_status: passed
created_at: 2025-10-12T06:17:21.951341
updated_at: 2025-10-12T15:34:16.409Z
completed_at: 2025-10-12T06:17:36.543904
tags: []
---

# Create interactive web-based app simulator

## Description

Build comprehensive HTML simulator demonstrating all TerrainIQ Dashcam app functionality with interactive controls, three view modes, and 12 pre-configured scenarios


Use Case
Interactive demonstration tool for testing and visualizing app functionality without needing to run the full Flutter application.

Acceptance Criteria
Interactive controls for distance, severity, speed, hazard type
Three view modes: Hazard HUD, HUD with PIP, Camera with Overlay
Portrait and Landscape orientation support
12 pre-configured scenarios with "Try It" buttons
Three-tab interface: Controls, Requirements, Examples
Responsive design and smooth transitions
Notes

[2025-10-12 06:17] Completed: Created app_simulator.html with interactive controls, 3 view modes, 12 scenarios, and full responsive design
Includes scroll position memory when switching tabs
Full-screen examples mode hides phone simulator for better visibility

Based on the completed task, here are the 12 pre-configured scenarios from the app simulator:

1. Safe Driving - No hazards, normal conditions
2. Approaching Pothole - 300m from medium severity pothole  
3. Construction Zone - 150m from high severity construction
4. Accident Ahead - 75m from very high severity accident
5. In Danger Zone - Inside severe hazard zone (road closure)
6. Multiple Hazards - Several hazards at varying distances
7. High Speed Warning - Speeding (120 km/h) near construction
8. Rough Road - Rough terrain with debris hazard
9. Sharp Turn - Approaching dangerous curve
10. Weather Hazard - Flooding/ice with reduced visibility
11. Night Driving - Low visibility with road work
12. Emergency Stop - Critical hazard requiring immediate attention

Interactive features include distance/severity/speed controls, hazard type selection, three view modes (Hazard HUD, HUD with PIP, Camera with Overlay), orientation toggle, and responsive three-tab interface."
This provides a comprehensive overview of all the realistic driving scenarios the simulator demonstrates, making it easier for stakeholders to understand the app's capabilities and for developers to reference the complete feature set.

## Use Case

Interactive demonstration tool for testing and visualizing app functionality without needing to run the full Flutter application.

## Acceptance Criteria

- [ ] Interactive controls for distance, severity, speed, hazard type
- [ ] Three view modes: Hazard HUD, HUD with PIP, Camera with Overlay
- [ ] Portrait and Landscape orientation support
- [ ] 12 pre-configured scenarios with "Try It" buttons
- [ ] Three-tab interface: Controls, Requirements, Examples
- [ ] Responsive design and smooth transitions

## Test Data

### Good Samples
_No good samples defined_

### Bad Samples
_No bad samples defined_

## Notes

- [2025-10-12 06:17] Completed: Created app_simulator.html with interactive controls, 3 view modes, 12 scenarios, and full responsive design
- Includes scroll position memory when switching tabs
- Full-screen examples mode hides phone simulator for better visibility
