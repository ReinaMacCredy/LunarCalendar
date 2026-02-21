# LunarCalendarApp

macOS menu bar app -- Swift 6.0, macOS 14+, no external dependencies. Vietnamese lunar calendar with calendar/reminder integration.

## Commands

```bash
# Test (primary verification)
swift test
swift test --filter LunarServiceTests/testMonthInfoCountMatchesGregorianMonth

# Build debug
xcodebuild -project LunarCalendarApp.xcodeproj -scheme LunarCalendarApp \
  -configuration Debug -derivedDataPath ./.xcodebuild build

# Build release (CI-compatible, no signing)
xcodebuild -project LunarCalendarApp.xcodeproj -scheme LunarCalendarApp \
  -configuration Release -destination "platform=macOS" \
  -derivedDataPath ./.xcodebuild \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" build

# Run
.xcodebuild/Build/Products/Debug/LunarCalendarApp.app/Contents/MacOS/LunarCalendarApp
```

## Project Config

Xcode project is generated from `project.yml` via XcodeGen. Edit `project.yml` for build settings -- never `.xcodeproj` directly.

## Architecture

### State & Lifecycle
- `LunarCalendarApp.swift` -- `@main`, creates `AppState` + `MenuBarController`
- `AppState` -- `@Observable @MainActor` singleton. Refresh via `RefreshReason` enum. Nonce-based cancellation for stale async updates.
- `MenuBarController` -- `NSStatusItem` + `NSPopover`, bridges AppKit menu bar with SwiftUI

### Services/
- `LunarService` -- pure lunar math + Vietnamese festival/solar term mapping. Loads `solar_terms.json` from bundle. No side effects.
- `EventKitService` -- `EKEventStore` wrapper. Permissions + change notifications.
- `SettingsStore` -- `UserDefaults`-backed `UserSettings` persistence
- `LaunchAtLoginManager` -- `SMAppService` wrapper

### Persistence/
- `AgendaCacheStore` -- local agenda item cache
- `PersistenceController` -- cache lifecycle

### Views/
- `CalendarPopoverView` --> `MonthGridView` + `AgendaListView`
- `AppSettingsView` -- standalone settings window

### Models (Models.swift)
`LunarDayInfo` | `AgendaItem` | `UserSettings` | `CalendarSource` | `CalendarDayCell`

## Concurrency

Strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY = complete`). `AppState` and UI on `@MainActor`. Services use `async/await`. Follow existing actor isolation patterns.

## Testing

XCTest with async methods. `@testable import LunarCalendarApp`. Coverage: lunar calculations, state behavior, source selection, cache operations.
