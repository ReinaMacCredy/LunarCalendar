import Foundation

enum UpdateStatus: Sendable {
    case idle
    case checking
    case upToDate(String)
    case available(latestVersion: String, releaseURL: String?)
    case error(String)
}

enum AccessState: String, Codable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum CalendarAccessEntity: String, Codable, Sendable {
    case event
    case reminder
}

enum AgendaKind: String, Codable, Sendable {
    case event
    case reminder
}

enum MenuBarIconStyle: String, Codable, CaseIterable, Sendable {
    case lunarCompact
    case calendarDayFilled
    case calendarDayOutlined
    case calendarSymbol
    case customFormat

    var title: String {
        switch self {
        case .lunarCompact:
            return "Âm lịch"
        case .calendarDayFilled:
            return "Ngày tô"
        case .calendarDayOutlined:
            return "Ngày viền"
        case .calendarSymbol:
            return "Biểu tượng lịch"
        case .customFormat:
            return "Tùy chỉnh"
        }
    }
}

enum HolidayKind: String, Codable, Sendable {
    case holiday
    case specialDay
}

struct HolidayInfo: Hashable, Codable, Sendable {
    let name: String
    let kind: HolidayKind
}

struct LunarDayInfo: Hashable, Codable, Sendable {
    let gregorianDate: Date
    let lunarYearText: String
    let fullLunarDateText: String
    let lunarMonthText: String
    let lunarDayText: String
    let displayLabel: String
    let compactDisplayLabel: String
    let isLeapMonth: Bool
    let solarTerm: String?
    let lunarFestival: String?
    let holiday: HolidayInfo?
    let isImportantFestivalDay: Bool
}

struct CalendarSource: Identifiable, Hashable, Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case event
        case reminder
    }

    let id: String
    let identifier: String
    let title: String
    let kind: Kind
}

struct AgendaItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let kind: AgendaKind
    let sourceIdentifier: String
    let sourceTitle: String
    let title: String
    let startDate: Date?
    let endDate: Date?
    let isAllDay: Bool
    let isCompleted: Bool

    var sortDate: Date {
        startDate ?? endDate ?? .distantFuture
    }

    var dayAnchor: Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: sortDate)
    }
}

struct UserSettings: Hashable, Codable, Sendable {
    var showHolidays: Bool = true
    var showSolarTerms: Bool = true
    var showReminders: Bool = true
    var firstWeekday: Int = 2
    var selectedEventCalendarIDs: Set<String> = []
    var selectedReminderCalendarIDs: Set<String> = []
    var allEventCalendarsSelected: Bool = true
    var allReminderCalendarsSelected: Bool = true
    var iconStyle: MenuBarIconStyle = .lunarCompact
    var customIconFormat: String = "EEE d MMM HH:mm"

    init() {}

    private enum CodingKeys: String, CodingKey {
        case showHolidays
        case showSolarTerms
        case showReminders
        case firstWeekday
        case selectedEventCalendarIDs
        case selectedReminderCalendarIDs
        case allEventCalendarsSelected
        case allReminderCalendarsSelected
        case iconStyle
        case customIconFormat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showHolidays = try container.decodeIfPresent(Bool.self, forKey: .showHolidays) ?? true
        showSolarTerms = try container.decodeIfPresent(Bool.self, forKey: .showSolarTerms) ?? true
        showReminders = try container.decodeIfPresent(Bool.self, forKey: .showReminders) ?? true
        let rawWeekday = try container.decodeIfPresent(Int.self, forKey: .firstWeekday) ?? 2
        firstWeekday = max(1, min(7, rawWeekday))
        selectedEventCalendarIDs = try container.decodeIfPresent(Set<String>.self, forKey: .selectedEventCalendarIDs) ?? []
        selectedReminderCalendarIDs = try container.decodeIfPresent(Set<String>.self, forKey: .selectedReminderCalendarIDs) ?? []
        allEventCalendarsSelected = try container.decodeIfPresent(Bool.self, forKey: .allEventCalendarsSelected)
            ?? selectedEventCalendarIDs.isEmpty
        allReminderCalendarsSelected = try container.decodeIfPresent(Bool.self, forKey: .allReminderCalendarsSelected)
            ?? selectedReminderCalendarIDs.isEmpty
        iconStyle = try container.decodeIfPresent(MenuBarIconStyle.self, forKey: .iconStyle) ?? .lunarCompact
        customIconFormat = try container.decodeIfPresent(String.self, forKey: .customIconFormat) ?? "EEE d MMM HH:mm"
    }
}

struct CalendarDayCell: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date?
    let dayText: String
    let lunarText: String
    let isCurrentMonth: Bool
    let showsHolidayMarker: Bool
    let hasAgenda: Bool
    let isToday: Bool
    let isSelected: Bool
    let highlightsFestival: Bool
}

enum RefreshReason: String, Sendable {
    case startup
    case timerTick
    case eventStoreChanged
    case monthChanged
    case selectedDateChanged
    case settingsChanged
    case permissionsChanged
}
