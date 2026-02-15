@testable import LunarCalendarApp
import Foundation
import XCTest

final class AgendaCacheStoreTests: XCTestCase {
    func testReplaceAndLoadDayAgenda() async throws {
        let persistence = PersistenceController(inMemory: true)
        let cache = AgendaCacheStore(container: persistence.container)

        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.date(from: DateComponents(year: 2026, month: 2, day: 4, hour: 9))!
        let dayEnd = calendar.date(byAdding: .day, value: 2, to: day)!

        let items = [
            AgendaItem(
                id: "event:1",
                kind: .event,
                sourceIdentifier: "source-1",
                sourceTitle: "Calendar",
                title: "Meeting",
                startDate: day,
                endDate: day.addingTimeInterval(1800),
                isAllDay: false,
                isCompleted: false
            ),
            AgendaItem(
                id: "reminder:1",
                kind: .reminder,
                sourceIdentifier: "source-2",
                sourceTitle: "Reminders",
                title: "Buy fruit",
                startDate: day.addingTimeInterval(3600),
                endDate: day.addingTimeInterval(3600),
                isAllDay: false,
                isCompleted: false
            ),
        ]

        try await cache.replace(items: items, in: DateInterval(start: day, end: dayEnd))

        let loaded = try await cache.dayAgenda(for: day)
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.first?.title, "Meeting")
    }
}
