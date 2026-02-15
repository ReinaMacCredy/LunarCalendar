@testable import LunarCalendarApp
import XCTest

@MainActor
final class AppStateSourceSelectionTests: XCTestCase {
    func testDeselectingOnlyEventSourceKeepsNoneSelectedState() {
        let state = AppState()
        let source = CalendarSource(
            id: "event:home",
            identifier: "event-home",
            title: "Home",
            kind: .event
        )
        state.availableSources = [source]

        XCTAssertTrue(state.isSourceSelected(source))

        state.setSource(source, isSelected: false)

        XCTAssertFalse(state.settings.allEventCalendarsSelected)
        XCTAssertTrue(state.settings.selectedEventCalendarIDs.isEmpty)
        XCTAssertFalse(state.isSourceSelected(source))
    }

    func testDeselectingOnlyReminderSourceKeepsNoneSelectedState() {
        let state = AppState()
        let source = CalendarSource(
            id: "reminder:home",
            identifier: "reminder-home",
            title: "Home",
            kind: .reminder
        )
        state.availableSources = [source]

        XCTAssertTrue(state.isSourceSelected(source))

        state.setSource(source, isSelected: false)

        XCTAssertFalse(state.settings.allReminderCalendarsSelected)
        XCTAssertTrue(state.settings.selectedReminderCalendarIDs.isEmpty)
        XCTAssertFalse(state.isSourceSelected(source))
    }
}
