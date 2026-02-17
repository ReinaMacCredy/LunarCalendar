@testable import LunarCalendarApp
import Foundation
import XCTest

final class AppStateBehaviorTests: XCTestCase {
    func testSettingsStoreKeepsIntentionalCustomFormatSelection() async {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let settingsStore = SettingsStore(suiteName: suiteName)

        var settings = UserSettings()
        settings.iconStyle = .customFormat
        settings.customIconFormat = "EEE d MMM HH:mm"
        await settingsStore.save(settings)

        let persisted = await settingsStore.load()
        XCTAssertEqual(persisted.iconStyle, .customFormat)
        XCTAssertEqual(persisted.customIconFormat, "EEE d MMM HH:mm")
    }

    func testSetSourceDoesNotPersistWithoutSettingsDidChange() async {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let settingsStore = SettingsStore(suiteName: suiteName)
        let state = await MainActor.run {
            AppState(settingsStore: settingsStore)
        }

        let source = CalendarSource(
            id: "event:home",
            identifier: "event-home",
            title: "Home",
            kind: .event
        )
        await MainActor.run {
            state.availableSources = [source]
            state.setSource(source, isSelected: false)
        }
        try? await Task.sleep(nanoseconds: 100_000_000)

        let persisted = await settingsStore.load()
        XCTAssertTrue(persisted.allEventCalendarsSelected)
        XCTAssertTrue(persisted.selectedEventCalendarIDs.isEmpty)
    }

    func testMenuBarTitleLunarCompactOmitsVietnamesePrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .vietnamese
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("ÂL "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testMenuBarTitleLunarCompactOmitsEnglishPrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .english
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("Lunar "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testMenuBarTitleLunarCompactOmitsChinesePrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .chineseSimplified
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("农历 "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testUpToDateStatusAutoResetsToIdleAfterConfiguredDelay() async {
        let state = await MainActor.run {
            AppState(upToDateStatusDisplayDuration: .milliseconds(50))
        }

        await MainActor.run {
            state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
            guard case .upToDate = state.updateStatus else {
                XCTFail("Expected update status to be up to date")
                return
            }
        }

        try? await Task.sleep(for: .milliseconds(150))

        await MainActor.run {
            guard case .idle = state.updateStatus else {
                XCTFail("Expected update status to reset to idle")
                return
            }
        }
    }

    func testUpToDateStatusResetDoesNotOverrideNewStatus() async {
        let state = await MainActor.run {
            AppState(upToDateStatusDisplayDuration: .milliseconds(50))
        }

        await MainActor.run {
            state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
            state.updateStatus = .error("network failed")
        }

        try? await Task.sleep(for: .milliseconds(150))

        await MainActor.run {
            guard case .error(let message) = state.updateStatus else {
                XCTFail("Expected update status to remain error")
                return
            }
            XCTAssertEqual(message, "network failed")
        }
    }

    func testSettingsStorePersistsPendingDownloadedUpdate() async {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let settingsStore = SettingsStore(suiteName: suiteName)

        var settings = UserSettings()
        settings.pendingDownloadedUpdate = DownloadedUpdate(
            latestVersion: "1.2.3",
            filePath: "/tmp/lunar-calendar-1.2.3.zip",
            extractedAppPath: "/tmp/LunarCalendar.app"
        )
        await settingsStore.save(settings)

        let persisted = await settingsStore.load()
        XCTAssertEqual(persisted.pendingDownloadedUpdate, settings.pendingDownloadedUpdate)
    }

    private func makeIsolatedDefaultsSuiteName(file: StaticString = #filePath, line: UInt = #line) -> String {
        let suiteName = "AppStateBehaviorTests.\(UUID().uuidString)"
        guard UserDefaults(suiteName: suiteName) != nil else {
            XCTFail("Failed to create isolated defaults suite", file: file, line: line)
            return UUID().uuidString
        }

        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return suiteName
    }
}
