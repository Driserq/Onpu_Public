# App Theme System

## Overview

All colors in the app are centralized in `AppColors.swift` to ensure consistency and make it easy to update the app's visual appearance.

## Color Categories

### Brand Colors
- **`Color.appAccent`** - Primary brand color (pink)
  - Used for: Tab bar icons, primary buttons, brand elements
- **`Color.appAccentLight`** - Light accent for backgrounds
  - Used for: Selected button backgrounds, subtle highlights

### Background Colors
- **`Color.appBackground`** - Primary background
  - Used for: Main content areas, cards
- **`Color.appBackgroundGrouped`** - Grouped content background
  - Used for: List backgrounds, grouped sections
- **`Color.appBackgroundSecondary`** - Secondary background
  - Used for: Nested elements, secondary containers
- **`Color.appBackgroundTertiary`** - Tertiary background
  - Used for: Subtle containers, light gray backgrounds

### Highlight & Selection Colors
- **`Color.appHighlight`** - Selected line highlight
  - Used for: Selected lyrics lines
- **`Color.appTranslationBackground`** - Translation background
  - Used for: Translation text backgrounds
- **`Color.appWarningBackground`** - Warning/alert background
  - Used for: Warning messages, alerts

### Pitch Accent Colors
- **`Color.appPitchAccent`** - Pitch accent line color
  - Used for: Pitch accent visualization lines

### UI Element Colors
- **`Color.appShadow`** - Standard shadow
  - Used for: Card shadows, subtle elevation
- **`Color.appShadowStrong`** - Prominent shadow
  - Used for: Modal shadows, strong elevation

## Usage

Instead of using hardcoded colors:
```swift
// ❌ Don't do this
.background(Color.pink)
.foregroundStyle(Color.pink.opacity(0.1))

// ✅ Do this
.background(Color.appAccent)
.foregroundStyle(Color.appAccentLight)
```

## Updating Colors

To change the app's color scheme:

1. Open `Uta/Theme/AppColors.swift`
2. Modify the color definitions
3. All views will automatically use the new colors

Example - changing the accent color from pink to blue:
```swift
// In AppColors.swift
static let appAccent = Color.blue  // Changed from .pink
static let appAccentLight = Color.blue.opacity(0.1)  // Changed from .pink
```

## Background Color Consistency

All main views now use consistent backgrounds:
- **Home**: `appBackground`
- **Library**: System default (list style)
- **Dictionary**: `appBackgroundGrouped`
- **Lyrics**: `appBackground` (toolbar)
- **Add Song**: `appBackgroundTertiary` (loading overlay)

This ensures a unified visual experience across the app.

## Notes

- Colors adapt to light/dark mode automatically through system colors
- Custom colors (like `appAccent`) work in both light and dark mode
- Opacity values are preserved when switching themes
