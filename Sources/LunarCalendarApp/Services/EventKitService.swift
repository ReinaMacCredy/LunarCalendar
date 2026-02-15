import EventKit
import Foundation

actor EventKitService {
    private let store = EKEventStore()

    func accessState(for entity: CalendarAccessEntity) -> AccessState {
        let status: EKAuthorizationStatus
        switch entity {
        case .event:
            status = EKEventStore.authorizationStatus(for: .event)
        case .reminder:
            status = EKEventStore.authorizationStatus(for: .reminder)
        }

        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .fullAccess, .writeOnly:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAccessIfNeeded(for entity: CalendarAccessEntity) async -> AccessState {
        let current = accessState(for: entity)
        guard current == .notDetermined else {
            return current
        }
        guard hasRequiredUsageDescription(for: entity) else {
            return .denied
        }

        do {
            let granted = try await Self.requestAccess(for: entity)
            store.reset()

            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    func availableSources(includeReminders: Bool) -> [CalendarSource] {
        var sources: [CalendarSource] = store.calendars(for: .event).map {
            CalendarSource(
                id: "event:\($0.calendarIdentifier)",
                identifier: $0.calendarIdentifier,
                title: $0.title,
                kind: .event
            )
        }

        if includeReminders {
            let reminderSources = store.calendars(for: .reminder).map {
                CalendarSource(
                    id: "reminder:\($0.calendarIdentifier)",
                    identifier: $0.calendarIdentifier,
                    title: $0.title,
                    kind: .reminder
                )
            }
            sources.append(contentsOf: reminderSources)
        }

        return sources.sorted { lhs, rhs in
            lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    func fetchAgenda(
        in interval: DateInterval,
        selectedEventCalendarIDs: Set<String>?,
        selectedReminderCalendarIDs: Set<String>?,
        includeReminders: Bool
    ) async -> [AgendaItem] {
        async let events = fetchEvents(in: interval, selectedCalendarIDs: selectedEventCalendarIDs)
        async let reminders = includeReminders
            ? fetchReminders(in: interval, selectedCalendarIDs: selectedReminderCalendarIDs)
            : []

        let merged = await events + reminders
        return merged.sorted { lhs, rhs in
            if lhs.sortDate == rhs.sortDate {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhs.sortDate < rhs.sortDate
        }
    }

    private func fetchEvents(in interval: DateInterval, selectedCalendarIDs: Set<String>?) -> [AgendaItem] {
        guard accessState(for: .event) == .authorized else {
            return []
        }

        let all = store.calendars(for: .event)
        let selected = selectedCalendars(from: all, ids: selectedCalendarIDs)
        guard !selected.isEmpty else {
            return []
        }

        let predicate = store.predicateForEvents(
            withStart: interval.start,
            end: interval.end,
            calendars: selected
        )
        let events = store.events(matching: predicate)

        return events.map { event in
            let timestamp = event.startDate?.timeIntervalSince1970 ?? 0
            return AgendaItem(
                id: "event:\(event.calendarItemIdentifier):\(Int(timestamp))",
                kind: .event,
                sourceIdentifier: event.calendar.calendarIdentifier,
                sourceTitle: event.calendar.title,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                isCompleted: false
            )
        }
    }

    private func fetchReminders(in interval: DateInterval, selectedCalendarIDs: Set<String>?) async -> [AgendaItem] {
        guard accessState(for: .reminder) == .authorized else {
            return []
        }

        let all = store.calendars(for: .reminder)
        let selected = selectedCalendars(from: all, ids: selectedCalendarIDs)
        guard !selected.isEmpty else {
            return []
        }

        let incompletePredicate = store.predicateForIncompleteReminders(
            withDueDateStarting: interval.start,
            ending: interval.end,
            calendars: selected
        )

        return await reminderAgendaItems(matching: incompletePredicate)
    }

    private func reminderAgendaItems(matching predicate: NSPredicate) async -> [AgendaItem] {
        await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                let items = (reminders ?? []).map { reminder in
                    let dueDate = reminder.dueDateComponents?.date
                    let timestamp = dueDate?.timeIntervalSince1970 ?? 0
                    return AgendaItem(
                        id: "reminder:\(reminder.calendarItemIdentifier):\(Int(timestamp))",
                        kind: .reminder,
                        sourceIdentifier: reminder.calendar.calendarIdentifier,
                        sourceTitle: reminder.calendar.title,
                        title: reminder.title,
                        startDate: dueDate,
                        endDate: dueDate,
                        isAllDay: dueDate == nil,
                        isCompleted: reminder.isCompleted
                    )
                }
                continuation.resume(returning: items)
            }
        }
    }

    private func selectedCalendars(from all: [EKCalendar], ids: Set<String>?) -> [EKCalendar] {
        guard let ids else {
            return all
        }
        return all.filter { ids.contains($0.calendarIdentifier) }
    }

    private func hasRequiredUsageDescription(for entity: CalendarAccessEntity) -> Bool {
        let info = Bundle.main.infoDictionary ?? [:]
        switch entity {
        case .event:
            return info["NSCalendarsFullAccessUsageDescription"] != nil || info["NSCalendarsUsageDescription"] != nil
        case .reminder:
            return info["NSRemindersFullAccessUsageDescription"] != nil || info["NSRemindersUsageDescription"] != nil
        }
    }

    private static func requestAccess(for entity: CalendarAccessEntity) async throws -> Bool {
        let requestStore = EKEventStore()
        switch entity {
        case .event:
            return try await requestStore.requestFullAccessToEvents()
        case .reminder:
            return try await requestStore.requestFullAccessToReminders()
        }
    }
}
