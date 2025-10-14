---
id: TASK-008
title: Design Left Navigation menu
type: feature
priority: high
assignee: agent
validation_status: pending
created_at: 2025-10-12T06:09:23.135494
updated_at: 2025-10-12T06:09:23.135494
completed_at: null
tags: [ui, navigation, design]
---

# Design Left Navigation menu

## Description

Create Left Nav menu design with options: My Account, Settings, Hazard History, Recordings Gallery, Help & Support, and Logout

## Use Case

Users need quick access to key app features and account management through a slide-out navigation menu. This provides a central hub for accessing all major app sections.

## Acceptance Criteria

- [ ] Design left navigation menu layout
- [ ] Include "My Account" menu item
- [ ] Include "Settings" menu item
- [ ] Include "Hazard History" menu item
- [ ] Include "Recordings Gallery" menu item
- [ ] Include "Help & Support" menu item
- [ ] Include "Logout" menu item
- [ ] Add user profile section at top
- [ ] Ensure design works in both orientations
- [ ] Add to simulator as viewable screen option

## Test Data

### Good Samples
- Logged-in user view with profile info
- Menu interaction flow
- Visual hierarchy of menu items

### Bad Samples
- N/A

## Implementation Notes

### Menu Structure

```
┌─────────────────────────────┐
│  👤 John Doe                │
│  john.doe@example.com       │
├─────────────────────────────┤
│  🏠 Dashboard               │
│  📊 Hazard History          │
│  📹 Recordings Gallery      │
│  ⚙️  Settings               │
│  👤 My Account              │
│  ❓ Help & Support          │
├─────────────────────────────┤
│  🚪 Logout                  │
└─────────────────────────────┘
```

### Menu Items Detail

#### User Profile Section
- Profile picture (circle avatar)
- User name
- Email address
- (Optional) Statistics: trips, hazards reported

#### Navigation Items
1. **Dashboard** - Main hazard view
2. **Hazard History** - List of previously encountered hazards
3. **Recordings Gallery** - Browse saved video recordings
4. **Settings** - App configuration (links to TASK-007)
5. **My Account** - User profile, preferences
6. **Help & Support** - FAQ, contact support, documentation

#### Footer
7. **Logout** - Sign out of account

### Design Considerations
- Slide-out animation from left edge
- Semi-transparent overlay on main content
- Tap outside menu to close
- Highlight active menu item
- Use iOS-style iconography
- Maintain consistent spacing and typography

### Interaction Flow
- Tap hamburger icon → menu slides in
- Tap menu item → navigate to screen, close menu
- Tap outside menu → menu slides out
- Swipe gesture support (slide in/out)

## Dependencies
- TASK-006 (for displaying in simulator)
- TASK-007 (Settings screen to link to)

## Notes

_No notes yet_
