# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About Solstice

Solstice is a multi-platform Apple app for tracking sunlight and daylight changes. It's open source and designed as a mental health tool to help users appreciate daylight changes throughout the year. Platforms: iOS, macOS, watchOS, visionOS.

## Build Commands

```bash
# Build main app for iOS Simulator
xcodebuild -scheme Solstice -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS
xcodebuild -scheme Solstice -destination 'platform=macOS' build

# Build watchOS app
xcodebuild -scheme "Solstice watchOS Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Test Commands

```bash
# Run unit tests (Swift Testing framework) on iOS Simulator
xcodebuild test -scheme Solstice -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SolsticeTests

# Run UI tests on iOS Simulator
xcodebuild test -scheme Solstice -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SolsticeUITests

# Run all tests
xcodebuild test -scheme Solstice -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Targets
- **SolsticeTests**: Unit tests using Swift Testing (`@Test` macro). Covers `SolsticeCalculator` solar event date calculations.
- **SolsticeUITests**: UI tests using XCUITest. Includes screenshot capture for accent color visual regression detection.

## Architecture

### Targets
- **Solstice**: Main iOS/macOS/visionOS app
- **Solstice watchOS Watch App**: watchOS companion
- **Widget**: iOS home screen widgets (Countdown, Overview, Solar Chart)
- **watchOS Widget**: Watch complications
- **Intents**: Siri Shortcuts support

### Key Patterns

**State Management**: Uses modern `@Observable` macro (iOS 17+) instead of `ObservableObject`. Views use `@Environment(Type.self)` for dependency injection, not `@EnvironmentObject`.

**Data Persistence**: Core Data with CloudKit sync (`NSPersistentCloudKitContainer`). Saved locations sync across devices via iCloud.

**Location**: `CurrentLocation` class manages CLLocationManager with `CLLocationUpdate.liveUpdates()` async API. Widget uses separate `LocationManager` actor with caching and timeouts.

**Background Tasks**: SwiftUI `.backgroundTask(.appRefresh())` modifier for reliable notification scheduling. Notifications are scheduled 64 days in advance.

### Key Files
- `SolsticeApp.swift`: App entry point, environment setup
- `Solstice/Helpers/CurrentLocation.swift`: Location management with @Observable
- `Solstice/Helpers/NotificationManager.swift`: Background notification scheduling
- `Solstice/Helpers/SolsticeCalculator.swift`: Solar event date calculations
- `Widget/Helpers/SolsticeWidgetTimelineProvider.swift`: Shared widget timeline logic

### Protocols
- `AnyLocation`: Base protocol for location data (title, subtitle, coordinates, timezone)
- `ObservableLocation`: `AnyLocation & AnyObject` for class-based locations

### Dependencies (SPM)
- **Solar**: Sunrise/sunset calculations
- **Suite**: Shared UI components
- **TimeMachine**: Debug time travel functionality
- **RealityKitContent**: visionOS 3D content

## Platform Conditionals

Use `#if os(iOS)`, `#if os(macOS)`, `#if os(watchOS)`, `#if os(visionOS)` for platform-specific code. Widget extension code uses `#if !WIDGET_EXTENSION` to exclude unavailable APIs.

## App Groups & Entitlements

- App Group: `group.me.daneden.Solstice` (shared data between app and widgets)
- iCloud Container: `iCloud.me.daneden.Solstice`
- Background Modes: location, remote-notification, fetch
