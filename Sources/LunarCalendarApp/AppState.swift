import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedDate: Date
    var displayMonth: Date
    var menuBarDate: Date
    var monthCells: [CalendarDayCell] = []
    var weekdaySymbols: [String] = []
    var selectedDayInfo: LunarDayInfo?
    var agendaItems: [AgendaItem] = []
    var availableSources: [CalendarSource] = []
    var eventAccess: AccessState = .notDetermined
    var reminderAccess: AccessState = .notDetermined
    var settings: UserSettings = UserSettings()
    var isLoading = false
    var errorMessage: String?
    var showSettings = false
    var launchAtLoginEnabled = false

    private let lunarService: LunarService
    private let eventService: EventKitService
    private let settingsStore: SettingsStore
    private let cacheStore: AgendaCacheStore
    private let launchAtLoginManager: LaunchAtLoginManager
    private let updateService: UpdateService

    private var calendar: Calendar
    private let legacyCustomFormatValue = "EEE d MMM HH:mm"
    private var bootstrapDone = false
    private var bootstrapTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var autoUpdateTask: Task<Void, Never>?
    private var refreshNonce: Int = 0
    private var saveSettingsTask: Task<Void, Never>?

    init(
        lunarService: LunarService = LunarService(),
        eventService: EventKitService = EventKitService(),
        settingsStore: SettingsStore = SettingsStore(),
        cacheStore: AgendaCacheStore = AgendaCacheStore(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        updateService: UpdateService = UpdateService()
    ) {
        let initialLanguage = L10n.appLanguage
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = initialLanguage.locale
        calendar.timeZone = .current

        self.selectedDate = calendar.startOfDay(for: now)
        self.displayMonth = now.startOfMonth(using: calendar)
        self.menuBarDate = now
        self.calendar = calendar

        self.lunarService = lunarService
        self.eventService = eventService
        self.settingsStore = settingsStore
        self.cacheStore = cacheStore
        self.launchAtLoginManager = launchAtLoginManager
        self.updateService = updateService
        self.settings.language = initialLanguage
    }

    var appLocale: Locale {
        settings.language.locale
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM y")
        return formatter.string(from: displayMonth).capitalized(with: appLocale)
    }

    var menuBarTitle: String {
        let locale = appLocale
        let day = calendar.component(.day, from: menuBarDate)

        switch settings.iconStyle {
        case .lunarCompact:
            return localizedLunarMenuBarTitle(for: menuBarDate, locale: locale)
        case .calendarDayFilled:
            return "#\(day)"
        case .calendarDayOutlined:
            return "[\(day)]"
        case .calendarSymbol:
            return L10n.tr("Cal", locale: locale, fallback: "Cal")
        case .customFormat:
            let format = String(settings.customIconFormat.prefix(64))
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateFormat = format
            return formatter.string(from: menuBarDate)
        }
    }

    func bootstrapIfNeeded() async {
        if bootstrapDone {
            return
        }
        if let bootstrapTask {
            await bootstrapTask.value
            return
        }

        let task = Task { @MainActor [self] in
            await performBootstrap()
        }
        bootstrapTask = task
        await task.value
    }

    private func performBootstrap() async {
        defer {
            bootstrapTask = nil
        }
        guard !bootstrapDone else {
            return
        }

        settings = await settingsStore.load()
        applyLocalization()
        await migrateLegacyCustomFormatIfNeeded()
        launchAtLoginEnabled = launchAtLoginManager.isEnabled()

        eventAccess = await eventService.requestAccessIfNeeded(for: .event)
        reminderAccess = await eventService.requestAccessIfNeeded(for: .reminder)

        weekdaySymbols = CalendarGridBuilder.weekdaySymbols(calendar: calendar, firstWeekday: settings.firstWeekday)

        if let cached = try? await cacheStore.dayAgenda(for: selectedDate) {
            agendaItems = cached
        }

        bootstrapDone = true
        configureAutoUpdatePolling()
        refresh(reason: .startup)
        if settings.autoCheckForUpdates {
            checkForUpdates(isAutomatic: true)
        }
    }

    func refresh(reason: RefreshReason) {
        refreshTask?.cancel()
        refreshNonce += 1
        let nonce = refreshNonce

        let selectedDate = self.selectedDate
        let displayMonth = self.displayMonth
        let settings = self.settings
        let locale = appLocale
        let timeZone = calendar.timeZone

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
                self.menuBarDate = .now
            }
            guard await MainActor.run(body: { self.refreshNonce == nonce }), !Task.isCancelled else {
                return
            }

            let monthStart = displayMonth.startOfMonth(using: calendar)
            let monthInterval = calendar.dateInterval(of: .month, for: monthStart) ?? DateInterval(start: monthStart, duration: 86400 * 31)
            let detailStart = calendar.startOfDay(for: selectedDate)
            let detailEnd = selectedDate.addingDays(8, using: calendar)
            let detailInterval = DateInterval(start: detailStart, end: detailEnd)
            let agendaIntervals = self.mergedDateIntervals([monthInterval, detailInterval])

            let prevMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

            async let monthInfosTask = lunarService.monthInfo(
                for: monthStart,
                locale: locale,
                timeZone: timeZone,
                showSolarTerms: settings.showSolarTerms,
                showHolidays: settings.showHolidays
            )
            async let prevMonthInfosTask = lunarService.monthInfo(
                for: prevMonth,
                locale: locale,
                timeZone: timeZone,
                showSolarTerms: settings.showSolarTerms,
                showHolidays: settings.showHolidays
            )
            async let nextMonthInfosTask = lunarService.monthInfo(
                for: nextMonth,
                locale: locale,
                timeZone: timeZone,
                showSolarTerms: settings.showSolarTerms,
                showHolidays: settings.showHolidays
            )

            async let dayInfoTask = lunarService.dayInfo(
                for: selectedDate,
                locale: locale,
                timeZone: timeZone,
                showSolarTerms: settings.showSolarTerms,
                showHolidays: settings.showHolidays
            )

            async let sourcesTask = eventService.availableSources(includeReminders: settings.showReminders)
            let selectedEventCalendarIDs = settings.allEventCalendarsSelected ? nil : settings.selectedEventCalendarIDs
            let selectedReminderCalendarIDs = settings.allReminderCalendarsSelected ? nil : settings.selectedReminderCalendarIDs
            var agendaBatches: [(interval: DateInterval, items: [AgendaItem])] = []
            agendaBatches.reserveCapacity(agendaIntervals.count)
            for interval in agendaIntervals {
                guard await MainActor.run(body: { self.refreshNonce == nonce }), !Task.isCancelled else {
                    return
                }
                let items = await eventService.fetchAgenda(
                    in: interval,
                    selectedEventCalendarIDs: selectedEventCalendarIDs,
                    selectedReminderCalendarIDs: selectedReminderCalendarIDs,
                    includeReminders: settings.showReminders
                )
                agendaBatches.append((interval: interval, items: items))
            }

            let monthInfos = await monthInfosTask
            let prevMonthInfos = await prevMonthInfosTask
            let nextMonthInfos = await nextMonthInfosTask
            let dayInfo = await dayInfoTask
            let sources = await sourcesTask
            var agendaByID: [String: AgendaItem] = [:]
            for batch in agendaBatches {
                for item in batch.items {
                    agendaByID[item.id] = item
                }
            }
            let agenda = agendaByID.values.sorted { lhs, rhs in
                if lhs.sortDate == rhs.sortDate {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.sortDate < rhs.sortDate
            }

            guard await MainActor.run(body: { self.refreshNonce == nonce }), !Task.isCancelled else {
                return
            }

            for batch in agendaBatches {
                try? await cacheStore.replace(items: batch.items, in: batch.interval)
            }

            guard await MainActor.run(body: { self.refreshNonce == nonce }), !Task.isCancelled else {
                return
            }

            let monthMap = Dictionary(
                uniqueKeysWithValues: (prevMonthInfos + monthInfos + nextMonthInfos).map { info in
                    (calendar.startOfDay(for: info.gregorianDate), info)
                }
            )

            let agendaDays = Set(agenda.map { calendar.startOfDay(for: $0.sortDate) })
            let cells = CalendarGridBuilder.monthCells(
                monthStart: monthStart,
                selectedDate: selectedDate,
                monthInfos: monthMap,
                agendaDays: agendaDays,
                firstWeekday: settings.firstWeekday,
                calendar: calendar
            )

            let detailAgenda = agenda.filter { item in
                item.sortDate >= detailStart && item.sortDate < detailEnd
            }
            guard await MainActor.run(body: { self.refreshNonce == nonce }), !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self.weekdaySymbols = CalendarGridBuilder.weekdaySymbols(calendar: self.calendar, firstWeekday: settings.firstWeekday)
                self.monthCells = cells
                self.selectedDayInfo = dayInfo
                self.availableSources = sources
                self.agendaItems = detailAgenda
                self.isLoading = false
                self.eventAccess = self.eventAccess
                self.reminderAccess = self.reminderAccess
                if reason == .permissionsChanged {
                    self.errorMessage = nil
                }
            }
        }
    }

    func selectDate(_ date: Date) {
        let normalized = calendar.startOfDay(for: date)
        selectedDate = normalized
        displayMonth = normalized.startOfMonth(using: calendar)
        refresh(reason: .selectedDateChanged)
    }

    func jumpToDate(_ date: Date) {
        let normalized = calendar.startOfDay(for: date)
        selectedDate = normalized
        displayMonth = normalized.startOfMonth(using: calendar)
        refresh(reason: .selectedDateChanged)
    }

    func goToToday() {
        let today = calendar.startOfDay(for: .now)
        selectedDate = today
        displayMonth = today.startOfMonth(using: calendar)
        refresh(reason: .selectedDateChanged)
    }

    func showPreviousMonth() {
        displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
        refresh(reason: .monthChanged)
    }

    func showNextMonth() {
        displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
        refresh(reason: .monthChanged)
    }

    func requestAccess(for entity: CalendarAccessEntity) {
        Task {
            _ = await eventService.requestAccessIfNeeded(for: entity)
            eventAccess = await eventService.accessState(for: .event)
            reminderAccess = await eventService.accessState(for: .reminder)
            refresh(reason: .permissionsChanged)
        }
    }

    func isSourceSelected(_ source: CalendarSource) -> Bool {
        switch source.kind {
        case .event:
            if settings.allEventCalendarsSelected {
                return true
            }
            return settings.selectedEventCalendarIDs.contains(source.identifier)
        case .reminder:
            if settings.allReminderCalendarsSelected {
                return true
            }
            return settings.selectedReminderCalendarIDs.contains(source.identifier)
        }
    }

    func setSource(_ source: CalendarSource, isSelected: Bool) {
        switch source.kind {
        case .event:
            let allEventIDs = Set(availableSources.filter { $0.kind == .event }.map(\.identifier))
            if settings.allEventCalendarsSelected {
                guard !isSelected else {
                    return
                }
                settings.allEventCalendarsSelected = false
                settings.selectedEventCalendarIDs = allEventIDs
                settings.selectedEventCalendarIDs.remove(source.identifier)
            } else {
                if isSelected {
                    settings.selectedEventCalendarIDs.insert(source.identifier)
                } else {
                    settings.selectedEventCalendarIDs.remove(source.identifier)
                }
                if !allEventIDs.isEmpty, settings.selectedEventCalendarIDs.count == allEventIDs.count {
                    settings.allEventCalendarsSelected = true
                    settings.selectedEventCalendarIDs = []
                }
            }

        case .reminder:
            let allReminderIDs = Set(availableSources.filter { $0.kind == .reminder }.map(\.identifier))
            if settings.allReminderCalendarsSelected {
                guard !isSelected else {
                    return
                }
                settings.allReminderCalendarsSelected = false
                settings.selectedReminderCalendarIDs = allReminderIDs
                settings.selectedReminderCalendarIDs.remove(source.identifier)
            } else {
                if isSelected {
                    settings.selectedReminderCalendarIDs.insert(source.identifier)
                } else {
                    settings.selectedReminderCalendarIDs.remove(source.identifier)
                }
                if !allReminderIDs.isEmpty, settings.selectedReminderCalendarIDs.count == allReminderIDs.count {
                    settings.allReminderCalendarsSelected = true
                    settings.selectedReminderCalendarIDs = []
                }
            }
        }
    }

    func settingsDidChange() {
        applyLocalization()
        saveSettingsTask?.cancel()
        let snapshot = settings
        saveSettingsTask = Task {
            await settingsStore.save(snapshot)
        }
        configureAutoUpdatePolling()
        refresh(reason: .settingsChanged)
    }

    private func migrateLegacyCustomFormatIfNeeded() async {
        if await settingsStore.isLegacyCustomFormatMigrationDone() {
            return
        }

        if settings.iconStyle == .customFormat, settings.customIconFormat == legacyCustomFormatValue {
            settings.iconStyle = .lunarCompact
            await settingsStore.save(settings)
        }

        await settingsStore.markLegacyCustomFormatMigrationDone()
    }

    private func mergedDateIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        let sorted = intervals.sorted { lhs, rhs in
            lhs.start < rhs.start
        }
        guard var active = sorted.first else {
            return []
        }

        var merged: [DateInterval] = []
        merged.reserveCapacity(sorted.count)

        for interval in sorted.dropFirst() {
            if interval.start <= active.end {
                active = DateInterval(start: active.start, end: max(active.end, interval.end))
            } else {
                merged.append(active)
                active = interval
            }
        }

        merged.append(active)
        return merged
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = launchAtLoginManager.isEnabled()
        } catch {
            errorMessage = error.localizedDescription
            launchAtLoginEnabled = launchAtLoginManager.isEnabled()
        }
    }

    func openCalendarApp() {
        let seconds = Int(selectedDate.timeIntervalSinceReferenceDate)
        if let url = URL(string: "calshow:\(seconds)") {
            NSWorkspace.shared.open(url)
        }
    }

    func openRemindersApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }

    var updateStatus: UpdateStatus = .idle

    func checkForUpdates(isAutomatic: Bool = false) {
        guard !isUpdateBusy else {
            return
        }
        if isAutomatic, settings.autoCheckForUpdates == false {
            return
        }
        updateStatus = .checking

        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
                let result = try await updateService.checkForUpdate(currentVersion: currentVersion)

                switch result {
                case .upToDate(let version):
                    updateStatus = .upToDate(version)
                case .available(let release):
                    updateStatus = .available(release)
                    if settings.autoDownloadUpdates {
                        downloadAndRelaunchAvailableUpdate()
                    }
                }
            } catch {
                updateStatus = .error(error.localizedDescription)
            }
        }
    }

    func openLatestRelease() {
        let releaseURLString: String?
        switch updateStatus {
        case .available(let release):
            releaseURLString = release.releaseURL
        default:
            releaseURLString = nil
        }

        if let releaseURLString, let url = URL(string: releaseURLString) {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "https://github.com/ReinaMacCredy/LunarCalendar/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }

    func downloadAndRelaunchAvailableUpdate() {
        downloadAvailableUpdate(autoRelaunch: true)
    }

    func downloadAvailableUpdate(autoRelaunch: Bool = false) {
        guard case .available(let release) = updateStatus else {
            return
        }
        guard release.asset != nil else {
            updateStatus = .error(
                L10n.tr(
                    "No downloadable asset found for this release.",
                    locale: appLocale,
                    fallback: "No downloadable asset found for this release."
                )
            )
            return
        }

        updateStatus = .downloading(latestVersion: release.latestVersion)
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let downloaded = try await updateService.downloadUpdate(release)
                updateStatus = .downloaded(downloaded)
                if autoRelaunch {
                    relaunchFromDownloadedUpdate()
                }
            } catch {
                updateStatus = .error(error.localizedDescription)
            }
        }
    }

    func relaunchFromDownloadedUpdate() {
        guard case .downloaded(let downloaded) = updateStatus else {
            return
        }
        guard let appURL = downloaded.extractedAppURL else {
            NSWorkspace.shared.open(downloaded.fileURL)
            updateStatus = .error(
                L10n.tr(
                    "Downloaded installer opened. Please install manually.",
                    locale: appLocale,
                    fallback: "Downloaded installer opened. Please install manually."
                )
            )
            return
        }

        updateStatus = .installing(downloaded.latestVersion)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let bundleIdentifier = Bundle.main.bundleIdentifier
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { [weak self] _, error in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                if let error {
                    self.updateStatus = .error(error.localizedDescription)
                    return
                }
                guard let bundleIdentifier else {
                    NSApp.terminate(nil)
                    return
                }

                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }
                    let deadline = Date().addingTimeInterval(4)
                    while Date() < deadline {
                        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
                        let hasNewInstance = running.contains { $0.processIdentifier != currentPID }
                        if hasNewInstance {
                            NSApp.terminate(nil)
                            return
                        }
                        try? await Task.sleep(for: .milliseconds(200))
                    }

                    self.updateStatus = .error(
                        L10n.tr(
                            "Downloaded app did not relaunch automatically. Please use Relaunch again or open installer manually.",
                            fallback: "Downloaded app did not relaunch automatically. Please use Relaunch again or open installer manually."
                        )
                    )
                }
            }
        }
    }

    func openDownloadedInstaller() {
        guard case .downloaded(let downloaded) = updateStatus else {
            return
        }
        NSWorkspace.shared.open(downloaded.fileURL)
    }

    func dismissUpdateStatus() {
        updateStatus = .idle
    }

    private var isUpdateBusy: Bool {
        switch updateStatus {
        case .checking, .downloading, .installing:
            return true
        case .idle, .upToDate, .available, .downloaded, .error:
            return false
        }
    }

    private func configureAutoUpdatePolling() {
        autoUpdateTask?.cancel()
        autoUpdateTask = nil

        guard settings.autoCheckForUpdates else {
            return
        }

        autoUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(21_600))
                guard !Task.isCancelled else {
                    return
                }
                await MainActor.run {
                    self?.checkForUpdates(isAutomatic: true)
                }
            }
        }
    }

    private func applyLocalization() {
        L10n.setLanguage(settings.language)
        calendar.locale = appLocale
        calendar.timeZone = .current
    }

    private func localizedLunarMenuBarTitle(for date: Date, locale: Locale) -> String {
        var lunarCalendar = Calendar(identifier: .chinese)
        lunarCalendar.locale = locale
        lunarCalendar.timeZone = calendar.timeZone

        let components = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let day = components.day ?? 1
        let month = components.month ?? 1
        let leapMarker = (components.isLeapMonth ?? false)
            ? " \(L10n.tr("nhuận", locale: locale, fallback: "nhuận"))"
            : ""

        let cyclicalYearFormatter = DateFormatter()
        cyclicalYearFormatter.calendar = lunarCalendar
        cyclicalYearFormatter.locale = locale
        cyclicalYearFormatter.timeZone = calendar.timeZone
        cyclicalYearFormatter.dateFormat = "U"
        let yearName = cyclicalYearFormatter.string(from: date)

        return "\(L10n.tr("ÂL", locale: locale, fallback: "ÂL")) \(day)/\(month)\(leapMarker) \(yearName)"
    }
}
