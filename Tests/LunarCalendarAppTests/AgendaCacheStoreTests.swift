@testable import LunarCalendarApp
import Foundation
import Testing

@Suite("Agenda cache store")
struct AgendaCacheStoreTests {
    @Test("Replace and load day agenda")
    func replaceAndLoadDayAgenda() async throws {
        let persistence = PersistenceController(inMemory: true)
        let cache = AgendaCacheStore(container: persistence.container)

        await waitForPersistentStoreToLoad(in: persistence)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 4, hour: 9)))
        let dayEnd = try #require(calendar.date(byAdding: .day, value: 2, to: day))

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
        #expect(loaded.count == 2)
        #expect(loaded.first?.title == "Meeting")
    }

    private func waitForPersistentStoreToLoad(
        in persistence: PersistenceController,
        timeout: Duration = .seconds(1),
        pollInterval: Duration = .milliseconds(10)
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while persistence.container.persistentStoreCoordinator.persistentStores.isEmpty {
            if clock.now >= deadline {
                break
            }
            try? await Task.sleep(for: pollInterval)
        }

        #expect(!persistence.container.persistentStoreCoordinator.persistentStores.isEmpty)
    }
}
