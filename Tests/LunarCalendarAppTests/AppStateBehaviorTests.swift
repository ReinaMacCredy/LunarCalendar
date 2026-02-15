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
