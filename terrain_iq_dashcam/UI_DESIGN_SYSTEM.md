# TerrainIQ Dashcam - UI Design System

**Last Updated:** 2025-10-13
**Version:** 1.0.0

This document defines the visual design language, UI components, patterns, and guidelines for the TerrainIQ Dashcam application to ensure consistency and maintainability.

---

## Table of Contents

1. [Design Principles](#design-principles)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Spacing & Layout](#spacing--layout)
5. [Component Library](#component-library)
6. [Animation & Motion](#animation--motion)
7. [Iconography](#iconography)
8. [Responsive Design](#responsive-design)
9. [Dark Mode](#dark-mode)

---

## Design Principles

### 1. Safety First
- **Clear visual hierarchy** - Critical information is always prominent
- **High contrast** - Readable in bright sunlight and at night
- **Large touch targets** - Easy to tap while driving (minimum 44x44pt)
- **Glanceable information** - Key data understood in <2 seconds

### 2. Minimal Distraction
- **Clean interfaces** - Remove unnecessary UI elements
- **Auto-hiding controls** - UI fades when not needed
- **Motion-appropriate feedback** - Animations only when helpful
- **Voice/haptic alternatives** - Reduce need to look at screen

### 3. Real-time Responsiveness
- **60fps animations** - Smooth, fluid interactions
- **Instant feedback** - UI responds to touch immediately
- **Live data updates** - No stale information
- **Progress indication** - Always show what's happening

### 4. Accessibility
- **Color blind safe** - Don't rely solely on color
- **Icon + text labels** - Multiple information channels
- **Scalable text** - Support system text sizing
- **High contrast mode** - Support accessibility settings

---

## Color System

### Primary Palette

#### Brand Blue
```dart
Primary Blue:   #1E88E5  Color(0xFF1E88E5)
Primary Dark:   #1976D2  Color(0xFF1976D2)
Primary Light:  #64B5F6  Color(0xFF64B5F6)
```

**Usage:** Branding, primary actions, safe states, navigation highlights

---

### Semantic Colors

#### Safety Status Colors

```dart
// Safe / All Clear
Safe Blue:      #1976D2  Color(0xFF1976D2)

// Low Risk Warning
Warning Yellow: #FBC02D  Color(0xFFFBC02D)

// Medium Risk Warning
Warning Orange: #FF6F00  Color(0xFFFF6F00)

// High Risk Warning (8-10 severity, <250m)
Danger Red:     #D32F2F  Color(0xFFD32F2F)
```

**Severity-to-Color Mapping:**

| Severity | Distance | Background Color |
|----------|----------|------------------|
| Any | >threshold (500m default) | Safe Blue (#1976D2) |
| 1-4 | <threshold | Warning Yellow (#FBC02D) |
| 5-7 | <threshold | Warning Orange (#FF6F00) |
| 8-10 | <250m | Danger Red (#D32F2F) |
| 8-10 | ≥250m | Warning Orange (#FF6F00) |

---

#### Motion Status Colors

```dart
// Moving / Active
Active Green:   #4CAF50  Color(0xFF4CAF50)

// Stopped / Idle
Idle Gray:      #9E9E9E  Color(0xFF9E9E9E)

// Warning / Invalid State
Alert Orange:   #FF9800  Color(0xFFFF9800)

// Recording
Record Red:     #F44336  Color(0xFFF44336)
```

---

#### Road Roughness Colors

```dart
Smooth:         #4CAF50  Color(0xFF4CAF50)  // Green
Moderate:       #FFEB3B  Color(0xFFFFEB3B)  // Yellow
Rough:          #FF9800  Color(0xFFFF9800)  // Orange
Very Rough:     #F44336  Color(0xFFF44336)  // Red
```

---

### Neutral Palette

```dart
// Backgrounds
Background:     #FFFFFF  Colors.white
Dark BG:        #000000  Colors.black
Splash Dark:    #0A0E1A  Color(0xFF0A0E1A)

// Text
Text Primary:   #212121  Color(0xFF212121)
Text Secondary: #757575  Color(0xFF757575)
Text Disabled:  #BDBDBD  Color(0xFFBDBDBD)
Text Inverse:   #FFFFFF  Colors.white

// Dividers & Borders
Divider:        #E0E0E0  Color(0xFFE0E0E0)
Border Light:   #F5F5F5  Color(0xFFF5F5F5)
Border Dark:    #9E9E9E  Color(0xFF9E9E9E)
```

---

### Color Usage Guidelines

**Do:**
- Use semantic colors consistently (green=good, red=danger)
- Maintain sufficient contrast ratios (WCAG AA: 4.5:1 for text)
- Test colors in both day and night conditions
- Use color blindness simulation tools

**Don't:**
- Don't use color as the only indicator
- Don't mix warm and cool colors inconsistently
- Don't use pure black (#000000) on pure white (#FFFFFF) for body text
- Don't override system accessibility colors

---

## Typography

### Font Family

**System Font Stack:**
- **iOS:** San Francisco (SF Pro)
- **Android:** Roboto
- **Flutter Default:** Uses platform default

```dart
// Flutter uses system fonts by default
TextStyle(fontFamily: null) // Uses platform default
```

---

### Type Scale

#### Display Text (Splash, Titles)

```dart
Display Large:
  fontSize: 48.0
  fontWeight: FontWeight.w200  // Light
  letterSpacing: 4.0
  height: 1.2
  // Usage: Splash screen title

Display Medium:
  fontSize: 36.0
  fontWeight: FontWeight.bold
  letterSpacing: 2.0
  // Usage: Warning text, hazard labels
```

---

#### Headline Text (Countdowns, Alerts)

```dart
Headline Large:
  fontSize: 80.0
  fontWeight: FontWeight.bold
  // Usage: Distance countdown

Headline Medium:
  fontSize: 32.0
  fontWeight: FontWeight.bold
  letterSpacing: 2.0
  // Usage: "HAZARD AHEAD", "ALL CLEAR"

Headline Small:
  fontSize: 28.0
  fontWeight: FontWeight.bold
  // Usage: Hazard type labels
```

---

#### Body Text (Status, Info)

```dart
Body Large:
  fontSize: 18.0
  fontWeight: FontWeight.w400  // Regular
  height: 1.8
  // Usage: Status descriptions, settings labels

Body Medium:
  fontSize: 16.0
  fontWeight: FontWeight.w500  // Medium
  // Usage: List tiles, button labels

Body Small:
  fontSize: 14.0
  fontWeight: FontWeight.w400
  // Usage: Secondary info, timestamps
```

---

#### Caption Text (Labels, Hints)

```dart
Caption Large:
  fontSize: 14.0
  fontWeight: FontWeight.w500
  // Usage: Section headers

Caption Medium:
  fontSize: 12.0
  fontWeight: FontWeight.w400
  // Usage: Hints, helper text

Caption Small:
  fontSize: 10.0
  fontWeight: FontWeight.bold
  letterSpacing: 2.0
  // Usage: Status badges, compact indicators
```

---

### Text Color Pairings

| Background | Primary Text | Secondary Text |
|------------|--------------|----------------|
| Safe Blue | White (#FFFFFF) | White 70% opacity |
| Warning Yellow | Dark Gray (#212121) | Gray (#757575) |
| Warning Orange | White (#FFFFFF) | White 70% opacity |
| Danger Red | White (#FFFFFF) | White 70% opacity |
| White | Dark Gray (#212121) | Gray (#757575) |
| Black | White (#FFFFFF) | White 70% opacity |

---

### Typography Guidelines

**Do:**
- Use font weights to create hierarchy (Light → Medium → Bold)
- Maintain consistent line heights (1.2-1.8)
- Use letter spacing for uppercase text
- Limit to 2-3 font sizes per screen

**Don't:**
- Don't use more than 3 font weights on a single screen
- Don't use font sizes smaller than 10pt for critical info
- Don't use italic for emphasis (use bold or color)
- Don't use all-caps for long text (max 3-4 words)

---

## Spacing & Layout

### Spacing Scale

Based on 8pt grid system:

```dart
// Base unit: 8dp
Spacing XS:     4.0   // Tight grouping
Spacing SM:     8.0   // Related items
Spacing MD:     16.0  // Standard padding
Spacing LG:     24.0  // Section spacing
Spacing XL:     32.0  // Major sections
Spacing 2XL:    48.0  // Screen-level spacing
Spacing 3XL:    64.0  // Large gaps
```

---

### Layout Patterns

#### Full-Screen Layouts (Driving Mode, Splash)

```dart
SafeArea(
  child: Stack(
    children: [
      // Background layer
      Container(color: dynamicBackground),
      // Content layer
      Positioned.fill(child: mainContent),
      // Overlay layer (back button, status)
      Positioned(top: 20, left: 20, child: backButton),
    ],
  ),
)
```

**Padding from screen edges:** 20pt minimum

---

#### List-Based Layouts (Settings)

```dart
ListView(
  padding: EdgeInsets.symmetric(vertical: 16.0),
  children: [
    // ExpansionTile for sections
    // ListTile for items
    // Divider between sections
  ],
)
```

**List item height:**
- Single line: 56pt minimum
- Two lines: 72pt minimum
- Three lines: 88pt minimum

---

#### Card Layouts (Status Indicators)

```dart
Container(
  padding: EdgeInsets.all(12.0),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.7),
    borderRadius: BorderRadius.circular(12.0),
    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
  ),
  child: content,
)
```

**Border radius:** 8-20pt depending on size
**Padding:** 8-16pt

---

### Grid System

**Column Grid:**
- 12-column grid for responsive layouts
- Gutters: 16pt
- Margins: 16-24pt from screen edge

**Component Sizing:**
- Touch targets: 44x44pt minimum (Apple HIG, WCAG)
- Icons: 16pt, 20pt, 24pt, 32pt, 40pt
- Buttons: 44pt minimum height

---

### Spacing Guidelines

**Do:**
- Use consistent spacing multipliers (4, 8, 16, 24, 32)
- Align elements to 8pt grid
- Group related items with less spacing
- Use more spacing to separate sections

**Don't:**
- Don't use arbitrary spacing values (11pt, 23pt)
- Don't cram too many elements in small spaces
- Don't use equal spacing for unrelated items
- Don't violate minimum touch target sizes (44pt)

---

## Component Library

### 1. Buttons

#### Primary Button (Record Button)

```dart
GestureDetector(
  onTap: onPressed,
  child: Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: isRecording ? Colors.red : Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Icon(
      isRecording ? Icons.stop : Icons.videocam,
      color: isRecording ? Colors.white : Colors.red,
      size: 40,
    ),
  ),
)
```

**Specs:**
- Size: 80x80pt
- Shape: Circle
- Shadow: 10pt blur, 5pt offset
- States: Default (white), Recording (red)

---

#### Icon Button (Back Button)

```dart
GestureDetector(
  onTap: onPressed,
  child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
  ),
)
```

**Specs:**
- Padding: 12pt
- Background: Black 50% opacity
- Icon size: 28pt
- Total size: 52x52pt (44pt+ touch target)

---

### 2. Switches & Toggles

#### Standard Switch

```dart
Switch(
  value: value,
  onChanged: onChanged,
  activeColor: Colors.green,
  materialTapTargetSize: MaterialTapTargetSize.padded,
)
```

**Colors:**
- Active: Green (#4CAF50)
- Inactive: Gray (#9E9E9E)
- Minimum touch target: 44x44pt

---

### 3. Sliders

#### Proximity Threshold Slider

```dart
Slider(
  value: value,
  min: 100,
  max: 500,
  divisions: 8,
  label: '${value.toStringAsFixed(0)}m',
  onChanged: onChanged,
)
```

**Specs:**
- Track height: 4pt
- Thumb size: 20pt diameter
- Active color: Primary Blue
- Label: Dynamic value

---

### 4. Status Indicators

#### Status Dot

```dart
Container(
  padding: EdgeInsets.all(6),
  decoration: BoxDecoration(
    color: color.withOpacity(0.2),
    shape: BoxShape.circle,
  ),
  child: Icon(icon, color: color, size: 16),
)
```

**Specs:**
- Icon size: 16pt
- Padding: 6pt
- Background: Icon color at 20% opacity
- Total size: 28x28pt

---

#### Enhanced Roughness Indicator

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: color.withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color, width: 1.5),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.waves, color: color, size: 16),
      SizedBox(width: 4),
      Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

---

### 5. Progress Indicators

#### Circular Progress (Warming Up)

```dart
SizedBox(
  width: 14,
  height: 14,
  child: CircularProgressIndicator(
    value: progress,  // 0.0 to 1.0
    strokeWidth: 2,
    backgroundColor: Colors.grey.withOpacity(0.3),
    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
  ),
)
```

---

#### Linear Progress (Warming Up - Portrait)

```dart
LinearProgressIndicator(
  value: progress,  // 0.0 to 1.0
  backgroundColor: Colors.grey.withOpacity(0.3),
  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
  minHeight: 4,
)
```

---

### 6. Page Indicators

```dart
Container(
  width: isActive ? 12 : 8,
  height: isActive ? 12 : 8,
  decoration: BoxDecoration(
    color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
    shape: BoxShape.circle,
    boxShadow: isActive ? [
      BoxShadow(
        color: Colors.white.withOpacity(0.5),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ] : null,
  ),
)
```

**Specs:**
- Active: 12x12pt, white, glowing
- Inactive: 8x8pt, white 40%
- Spacing: 8pt between dots

---

### 7. Cards & Containers

#### Overlay Card (Camera info, Status)

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
  ),
  child: content,
)
```

**Specs:**
- Background: Black 70% opacity
- Border radius: 20pt
- Padding: 16pt horizontal, 12pt vertical

---

#### Info Card (Settings, Warnings)

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.3),
    borderRadius: BorderRadius.circular(16),
  ),
  child: content,
)
```

---

### 8. Directional Arrows

#### Hazard Direction Arrow

```dart
Transform.rotate(
  angle: bearing * math.pi / 180.0,  // Degrees to radians
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Icon(
      Icons.navigation,
      size: 80,
      color: Colors.white,
    ),
  ),
)
```

**Specs:**
- Icon: navigation (arrow pointing up)
- Rotation: Dynamic based on bearing
- Border: 3pt white
- Padding: 16pt
- Icon size: 80pt

---

## Animation & Motion

### Animation Timing

| Animation Type | Duration | Curve |
|----------------|----------|-------|
| Micro-interactions (tap, toggle) | 150-200ms | easeOut |
| Page transitions | 300-400ms | easeInOut |
| Fade in/out | 200-300ms | easeIn/easeOut |
| Pulsing glow (splash) | 2000ms | Repeat reverse |
| Recording indicator blink | 800ms | Repeat reverse |
| Slide transitions | 300ms | easeInOut |

---

### Animation Patterns

#### Fade Transition (REC Indicator)

```dart
AnimationController _flashController = AnimationController(
  duration: Duration(milliseconds: 800),
  vsync: this,
)..repeat(reverse: true);

FadeTransition(
  opacity: _flashController,
  child: recIndicator,
)
```

---

#### Pulse Animation (Splash Logo)

```dart
AnimationController _pulseController = AnimationController(
  vsync: this,
  duration: Duration(milliseconds: 2000),
)..repeat(reverse: true);

AnimatedBuilder(
  animation: _pulseController,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E88E5).withOpacity(0.3 * _pulseController.value),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: child,
    );
  },
  child: logo,
)
```

---

#### Page Transition

```dart
PageController _pageController = PageController(initialPage: 0);

PageView(
  controller: _pageController,
  onPageChanged: (index) {
    setState(() => _currentPage = index);
  },
  children: [page1, page2],
)
```

---

### Motion Guidelines

**Do:**
- Use motion to guide attention
- Keep animations under 400ms
- Use easing curves (not linear)
- Provide immediate feedback (<100ms)

**Don't:**
- Don't animate critical safety information
- Don't use animations that distract from driving
- Don't chain multiple sequential animations
- Don't animate continuously (except status indicators)

---

## Iconography

### Icon Library

**Primary Icon Pack:** Material Icons (built-in with Flutter)

### Icon Sizes

```dart
Icon XS:  16.0  // Status indicators
Icon SM:  20.0  // List items
Icon MD:  24.0  // Standard buttons
Icon LG:  32.0  // Feature buttons
Icon XL:  40.0  // Primary actions
Icon 2XL: 80.0  // Directional arrows
Icon 3XL: 100.0 // Warning icons
Icon 4XL: 120.0 // All clear icon
```

---

### Icon Usage Map

| Icon | Name | Usage | Size |
|------|------|-------|------|
| ▶️ | arrow_back | Back navigation | 28pt |
| ⚠️ | warning_rounded | Hazard warnings | 100pt |
| ✓ | check_circle_outline | All clear | 120pt |
| 🧭 | navigation | Directional arrows | 24-80pt |
| 📹 | videocam | Record button | 40pt |
| ⏹️ | stop | Stop recording | 40pt |
| 🔴 | fiber_manual_record | Recording indicator | 12pt |
| 📵 | videocam_off | Not recording | 16pt |
| 🚗 | directions_car | Moving status | 16-20pt |
| ⏸️ | pause_circle_outline | Stopped | 16-20pt |
| 📱 | phone_android | Orientation | 16-20pt |
| 🌊 | waves | Road roughness | 16pt |
| 🎯 | location_off | GPS unavailable | 20pt |
| 🔍 | location_searching | Searching GPS | 20pt |
| 🧭 | explore_off | No heading | 20pt |

---

### Icon Color Coding

| State | Color | Example |
|-------|-------|---------|
| Active/Good | Green (#4CAF50) | Moving, valid orientation |
| Inactive/Neutral | Gray (#9E9E9E) | Stopped, not recording |
| Warning | Orange (#FF9800) | Invalid orientation |
| Danger | Red (#F44336) | Recording, very rough road |
| Info | Blue (#1E88E5) | Navigation, branding |

---

## Responsive Design

### Breakpoints

| Size | Width | Orientation | Layout Adjustments |
|------|-------|-------------|--------------------|
| Small | <375pt | Portrait | Compact layout, smaller text |
| Medium | 375-428pt | Portrait | Standard layout (target) |
| Large | >428pt | Portrait | Scaled layout, larger touch targets |
| Landscape | Any | Landscape | Repositioned controls, compact status |

---

### Orientation Handling

**Portrait Mode (Default):**
- Full-screen hazard warnings
- Expanded auto-record toggle with details
- Vertical status arrangement

**Landscape Mode:**
- Side-by-side layout considerations
- Compact auto-record toggle
- Horizontal status arrangement
- Controls repositioned to left/right edges

**Adaptation Code:**
```dart
final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

Widget build(BuildContext context) {
  return isLandscape ? buildLandscapeLayout() : buildPortraitLayout();
}
```

---

### Text Scaling

Support system text scaling (iOS Settings > Display > Text Size):

```dart
Text(
  'Label',
  style: TextStyle(fontSize: 16.0),
  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3),
)
```

**Max scale factor:** 1.3x (prevent layout breaking)

---

## Dark Mode

### Current Implementation

**Status:** Partial dark mode support

The app uses dynamic dark backgrounds for:
- Hazard warning screens (context-dependent colors)
- Splash screen (dark gradient)
- Camera overlays (dark with transparency)

**System Dark Mode:** Not yet implemented

---

### Future Dark Mode Strategy

#### Color Adaptations

| Light Mode | Dark Mode | Usage |
|------------|-----------|-------|
| #FFFFFF (White) | #121212 (Dark Gray) | Backgrounds |
| #212121 (Dark Gray) | #FFFFFF (White) | Text |
| #1E88E5 (Blue) | #64B5F6 (Light Blue) | Primary actions |
| #E0E0E0 (Light Gray) | #424242 (Dark Gray) | Dividers |

#### Implementation Approach

```dart
final brightness = MediaQuery.of(context).platformBrightness;
final isDark = brightness == Brightness.dark;

final backgroundColor = isDark ? Color(0xFF121212) : Colors.white;
final textColor = isDark ? Colors.white : Color(0xFF212121);
```

---

## Design Tokens

### Flutter Theme Configuration

```dart
ThemeData(
  primaryColor: Color(0xFF1E88E5),
  primaryColorDark: Color(0xFF1976D2),
  primaryColorLight: Color(0xFF64B5F6),

  // Accent
  colorScheme: ColorScheme.light(
    primary: Color(0xFF1E88E5),
    secondary: Color(0xFF4CAF50),
    error: Color(0xFFD32F2F),
  ),

  // Text Theme
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w200),
    displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  ),

  // App Bar
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E88E5),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
)
```

---

## Design Resources

### Tools Used

- **Design:** Figma (or equivalent for mockups)
- **Color Testing:** Contrast Checker, Color Oracle (colorblind sim)
- **Typography:** SF Pro (iOS), Roboto (Android)
- **Icons:** Material Icons (Flutter built-in)

### External Resources

- [Material Design Guidelines](https://material.io/design)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)

---

*This design system should be referenced when creating new UI components or modifying existing ones to ensure visual consistency across the application.*
