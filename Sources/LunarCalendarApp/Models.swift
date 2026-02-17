import Foundation

enum UpdateAssetKind: String, Sendable {
    case zip
    case dmg
    case other
}

struct UpdateAsset: Hashable, Sendable {
    let name: String
    let downloadURL: String
    let sizeInBytes: Int64?
    let kind: UpdateAssetKind
}

struct UpdateRelease: Hashable, Sendable {
    let latestVersion: String
    let title: String?
    let releaseNotes: String?
    let releaseURL: String?
    let publishedAt: Date?
    let asset: UpdateAsset?
}

struct DownloadedUpdate: Hashable, Sendable {
    let latestVersion: String
    let filePath: String
    let extractedAppPath: String?

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    var extractedAppURL: URL? {
        extractedAppPath.map { URL(fileURLWithPath: $0) }
    }
}

enum UpdateStatus: Sendable {
    case idle
    case checking
    case upToDate(String)
    case available(UpdateRelease)
    case downloading(latestVersion: String)
    case downloaded(DownloadedUpdate)
    case installing(String)
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

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case vietnamese
    case english
    case chineseSimplified

    var localeIdentifier: String {
        switch self {
        case .vietnamese:
            return "vi"
        case .english:
            return "en"
        case .chineseSimplified:
            return "zh-Hans"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var title: String {
        switch self {
        case .vietnamese:
            return "Tiếng Việt"
        case .english:
            return "English"
        case .chineseSimplified:
            return "简体中文"
        }
    }
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
            return L10n.tr("Âm lịch")
        case .calendarDayFilled:
            return L10n.tr("Ngày tô")
        case .calendarDayOutlined:
            return L10n.tr("Ngày viền")
        case .calendarSymbol:
            return L10n.tr("Biểu tượng lịch")
        case .customFormat:
            return L10n.tr("Tùy chỉnh")
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
    var language: AppLanguage = .vietnamese
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
    var autoCheckForUpdates: Bool = true
    var autoDownloadUpdates: Bool = false
    var skippedUpdateVersion: String?

    init() {}

    private enum CodingKeys: String, CodingKey {
        case language
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
        case autoCheckForUpdates
        case autoDownloadUpdates
        case skippedUpdateVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .vietnamese
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
        autoCheckForUpdates = try container.decodeIfPresent(Bool.self, forKey: .autoCheckForUpdates) ?? true
        autoDownloadUpdates = try container.decodeIfPresent(Bool.self, forKey: .autoDownloadUpdates) ?? false
        skippedUpdateVersion = try container.decodeIfPresent(String.self, forKey: .skippedUpdateVersion)
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
