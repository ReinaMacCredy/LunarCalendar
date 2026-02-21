@testable import LunarCalendarApp
import Testing

@Suite("AppState source selection")
struct AppStateSourceSelectionTests {
    @MainActor
    @Test(
        "Deselecting only source keeps none-selected state",
        arguments: [CalendarSource.Kind.event, .reminder]
    )
    func deselectingOnlySourceKeepsNoneSelectedState(kind: CalendarSource.Kind) {
        let state = AppState()
        let source = CalendarSource(
            id: "\(kind.rawValue):home",
            identifier: "\(kind.rawValue)-home",
            title: "Home",
            kind: kind
        )
        state.availableSources = [source]

        #expect(state.isSourceSelected(source))

        state.setSource(source, isSelected: false)

        switch kind {
        case .event:
            #expect(state.settings.allEventCalendarsSelected == false)
            #expect(state.settings.selectedEventCalendarIDs.isEmpty)
        case .reminder:
            #expect(state.settings.allReminderCalendarsSelected == false)
            #expect(state.settings.selectedReminderCalendarIDs.isEmpty)
        }

        #expect(state.isSourceSelected(source) == false)
    }
}
