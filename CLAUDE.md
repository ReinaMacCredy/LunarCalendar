# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Run tests (primary verification command)
swift test

# Run a single test
swift test --filter LunarServiceTests/testMonthInfoCountMatchesGregorianMonth

# Build debug via Xcode project
xcodebuild -project LunarCalendarApp.xcodeproj -scheme LunarCalendarApp \
  -configuration Debug -derivedDataPath ./.xcodebuild build

# Build release (no code signing, matches CI)
xcodebuild -project LunarCalendarApp.xcodeproj -scheme LunarCalendarApp \
  -configuration Release -destination "platform=macOS" \
  -derivedDataPath ./.xcodebuild \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" build

# Run the built app
.xcodebuild/Build/Products/Debug/LunarCalendarApp.app/Contents/MacOS/LunarCalendarApp
```

The Xcode project is generated from `project.yml` via XcodeGen. Edit `project.yml` for build settings, not the `.xcodeproj` directly.

## Architecture

**macOS menu bar app** (Swift 6.0, macOS 14+, no external dependencies) displaying a Vietnamese lunar calendar with calendar/reminder integration.

### State & Lifecycle

- `LunarCalendarApp.swift` — `@main` entry point, creates `AppState` and `MenuBarController`
- `AppState` — `@Observable @MainActor` singleton, owns all app state. Coordinates refresh via `RefreshReason` enum (startup, timerTick, eventStoreChanged, monthChanged, settingsChanged, permissionsChanged). Uses nonce-based cancellation for stale async updates.
- `MenuBarController` — manages `NSStatusItem` and `NSPopover`, bridges AppKit menu bar with SwiftUI views

### Services (Sources/LunarCalendarApp/Services/)

- `LunarService` — pure lunar calendar math + Vietnamese festival/solar term mapping. Loads `solar_terms.json` from bundle resources. No side effects.
- `EventKitService` — `EKEventStore` wrapper for calendar events and reminders. Handles permissions and change notifications.
- `SettingsStore` — `UserDefaults`-backed persistence for `UserSettings`
- `LaunchAtLoginManager` — `SMAppService` wrapper

### Persistence (Sources/LunarCalendarApp/Persistence/)

- `AgendaCacheStore` — local cache for agenda items using a lightweight store
- `PersistenceController` — cache lifecycle management

### Views (Sources/LunarCalendarApp/Views/)

SwiftUI views rendered inside the menu bar popover:
- `CalendarPopoverView` → `MonthGridView` + `AgendaListView`
- `AppSettingsView` — standalone settings window

### Key Models (Models.swift)

- `LunarDayInfo` — complete lunar calendar data for one day
- `AgendaItem` — calendar event or reminder
- `UserSettings` — all user preferences
- `CalendarSource` — available calendar/reminder lists for filtering
- `CalendarDayCell` — UI-ready data for month grid cells

## Concurrency

Strict concurrency is enabled (`SWIFT_STRICT_CONCURRENCY = complete`). `AppState` and all UI code runs on `@MainActor`. Services use `async/await`. Follow existing actor isolation patterns when adding new code.

## Testing

Tests use XCTest with async test methods. `@testable import LunarCalendarApp` gives access to internals. Tests cover lunar calculations, state behavior, source selection logic, and cache operations.
