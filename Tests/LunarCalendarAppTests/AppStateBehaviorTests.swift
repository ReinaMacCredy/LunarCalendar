@testable import LunarCalendarApp
import Foundation
import Testing

@Suite("AppState behavior")
struct AppStateBehaviorTests {
    @Test("SettingsStore keeps intentional custom format selection")
    func settingsStoreKeepsIntentionalCustomFormatSelection() async throws {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let defaults = try #require(UserDefaults(suiteName: suiteName), "Failed to create isolated defaults suite")
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = SettingsStore(suiteName: suiteName)

        var settings = UserSettings()
        settings.iconStyle = .customFormat
        settings.customIconFormat = "EEE d MMM HH:mm"
        await settingsStore.save(settings)

        let persisted = await settingsStore.load()
        #expect(persisted.iconStyle == .customFormat)
        #expect(persisted.customIconFormat == "EEE d MMM HH:mm")
    }

    @MainActor
    @Test("setSource does not persist without settingsDidChange")
    func setSourceDoesNotPersistWithoutSettingsDidChange() async throws {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let defaults = try #require(UserDefaults(suiteName: suiteName), "Failed to create isolated defaults suite")
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = SettingsStore(suiteName: suiteName)
        let state = AppState(settingsStore: settingsStore)

        let source = CalendarSource(
            id: "event:home",
            identifier: "event-home",
            title: "Home",
            kind: .event
        )
        state.availableSources = [source]
        state.setSource(source, isSelected: false)

        let persisted = await settingsStore.load()
        #expect(persisted.allEventCalendarsSelected)
        #expect(persisted.selectedEventCalendarIDs.isEmpty)
    }

    @MainActor
    @Test(
        "Lunar compact menu bar title omits legacy language prefixes",
        arguments: [
            PrefixScenario(language: .vietnamese, unexpectedPrefix: "ÂL "),
            PrefixScenario(language: .english, unexpectedPrefix: "Lunar "),
            PrefixScenario(language: .chineseSimplified, unexpectedPrefix: "农历 "),
        ]
    )
    func menuBarTitleLunarCompactOmitsLanguagePrefix(scenario: PrefixScenario) {
        let state = AppState()

        state.settings.iconStyle = .lunarCompact
        state.settings.language = scenario.language
        state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
        let title = state.menuBarTitle

        #expect(!title.hasPrefix(scenario.unexpectedPrefix))
    }

    @MainActor
    @Test("Up-to-date status auto-resets to idle after configured delay")
    func upToDateStatusAutoResetsToIdleAfterConfiguredDelay() async {
        let state = AppState(upToDateStatusDisplayDuration: .milliseconds(50))

        state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
        #expect(isUpToDate(state.updateStatus))

        let resetToIdle = await waitUntil(timeout: .seconds(1)) {
            if case .idle = state.updateStatus {
                return true
            }
            return false
        }

        #expect(resetToIdle)
    }

    @MainActor
    @Test("Up-to-date reset task does not override a newer status")
    func upToDateStatusResetDoesNotOverrideNewStatus() async {
        let state = AppState(upToDateStatusDisplayDuration: .milliseconds(50))

        state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
        state.updateStatus = .error("network failed")

        let remainedError = await remainsError(
            state,
            message: "network failed",
            for: .milliseconds(220)
        )

        #expect(remainedError)
    }

    @Test("SettingsStore persists pending downloaded update")
    func settingsStorePersistsPendingDownloadedUpdate() async throws {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let defaults = try #require(UserDefaults(suiteName: suiteName), "Failed to create isolated defaults suite")
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = SettingsStore(suiteName: suiteName)

        var settings = UserSettings()
        settings.pendingDownloadedUpdate = DownloadedUpdate(
            latestVersion: "1.2.3",
            filePath: "/tmp/lunar-calendar-1.2.3.zip",
            extractedAppPath: "/tmp/LunarCalendar.app"
        )
        await settingsStore.save(settings)

        let persisted = await settingsStore.load()
        #expect(persisted.pendingDownloadedUpdate == settings.pendingDownloadedUpdate)
    }

    @MainActor
    @Test("selectDate and jumpToDate normalize dates the same way")
    func selectDateAndJumpToDateNormalizeSameWay() {
        let state = AppState()
        let rawDate = Date(timeIntervalSince1970: 1_739_875_212)

        state.selectDate(rawDate)
        let selectedAfterSelect = state.selectedDate
        let displayMonthAfterSelect = state.displayMonth

        state.jumpToDate(rawDate)

        #expect(state.selectedDate == selectedAfterSelect)
        #expect(state.displayMonth == displayMonthAfterSelect)
        #expect(state.selectedDate == state.appCalendar.startOfDay(for: rawDate))
    }

    @Test("refresh derived output deduplicates, sorts, and filters detail agenda")
    func refreshDerivedOutputDeduplicatesSortsAndFiltersDetailAgenda() {
        let monthStart = makeGregorianDate(year: 2026, month: 2, day: 1, hour: 0)
        let selectedDate = makeGregorianDate(year: 2026, month: 2, day: 10)
        let detailInterval = DateInterval(
            start: makeGregorianDate(year: 2026, month: 2, day: 10, hour: 0),
            end: makeGregorianDate(year: 2026, month: 2, day: 18, hour: 0)
        )

        let betaItem = AgendaItem(
            id: "event:beta",
            kind: .event,
            sourceIdentifier: "calendar-a",
            sourceTitle: "Calendar A",
            title: "Beta",
            startDate: makeGregorianDate(year: 2026, month: 2, day: 10, hour: 9),
            endDate: nil,
            isAllDay: false,
            isCompleted: false
        )
        let sharedOriginal = AgendaItem(
            id: "event:shared",
            kind: .event,
            sourceIdentifier: "calendar-a",
            sourceTitle: "Calendar A",
            title: "Original Shared Event",
            startDate: makeGregorianDate(year: 2026, month: 2, day: 11, hour: 8),
            endDate: nil,
            isAllDay: false,
            isCompleted: false
        )
        let sharedUpdated = AgendaItem(
            id: "event:shared",
            kind: .event,
            sourceIdentifier: "calendar-b",
            sourceTitle: "Calendar B",
            title: "Updated Shared Event",
            startDate: makeGregorianDate(year: 2026, month: 2, day: 11, hour: 10),
            endDate: nil,
            isAllDay: false,
            isCompleted: false
        )
        let outsideDetailWindow = AgendaItem(
            id: "event:outside",
            kind: .event,
            sourceIdentifier: "calendar-c",
            sourceTitle: "Calendar C",
            title: "Outside Detail Window",
            startDate: makeGregorianDate(year: 2026, month: 2, day: 20, hour: 9),
            endDate: nil,
            isAllDay: false,
            isCompleted: false
        )

        let input = AppStateRefreshDerivedInput(
            localeIdentifier: "en_US_POSIX",
            timeZoneIdentifier: "UTC",
            monthStart: monthStart,
            selectedDate: selectedDate,
            detailInterval: detailInterval,
            firstWeekday: 2,
            monthInfos: [makeLunarInfo(for: selectedDate, label: "S")],
            previousMonthInfos: [makeLunarInfo(for: makeGregorianDate(year: 2026, month: 1, day: 31), label: "P")],
            nextMonthInfos: [makeLunarInfo(for: makeGregorianDate(year: 2026, month: 3, day: 1), label: "N")],
            agendaBatches: [
                AppStateRefreshAgendaBatch(
                    interval: DateInterval(
                        start: makeGregorianDate(year: 2026, month: 2, day: 1, hour: 0),
                        end: makeGregorianDate(year: 2026, month: 2, day: 15, hour: 0)
                    ),
                    items: [betaItem, sharedOriginal]
                ),
                AppStateRefreshAgendaBatch(
                    interval: DateInterval(
                        start: makeGregorianDate(year: 2026, month: 2, day: 10, hour: 0),
                        end: makeGregorianDate(year: 2026, month: 3, day: 1, hour: 0)
                    ),
                    items: [sharedUpdated, outsideDetailWindow]
                ),
            ]
        )

        let output = computeAppStateRefreshDerivedOutput(from: input)

        #expect(output.monthCells.count == 42)
        #expect(output.detailAgenda.map(\.id) == ["event:beta", "event:shared"])
        #expect(output.detailAgenda.last?.title == "Updated Shared Event")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        #expect(
            output.monthCells.contains { cell in
                guard let date = cell.date, cell.isSelected else {
                    return false
                }
                return calendar.isDate(date, inSameDayAs: selectedDate)
            }
        )
    }

    private func makeGregorianDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? .distantPast
    }

    private func makeLunarInfo(for date: Date, label: String) -> LunarDayInfo {
        LunarDayInfo(
            gregorianDate: date,
            lunarYearText: "Year",
            fullLunarDateText: "Full Lunar Date",
            lunarMonthText: "Month",
            lunarDayText: "Day",
            displayLabel: label,
            compactDisplayLabel: label,
            isLeapMonth: false,
            solarTerm: nil,
            lunarFestival: nil,
            holiday: nil,
            isImportantFestivalDay: false
        )
    }

    private func makeIsolatedDefaultsSuiteName() -> String {
        "AppStateBehaviorTests.\(UUID().uuidString)"
    }

    @MainActor
    private func waitUntil(
        timeout: Duration,
        pollInterval: Duration = .milliseconds(10),
        condition: @MainActor () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(for: pollInterval)
        }

        return condition()
    }

    @MainActor
    private func remainsError(
        _ state: AppState,
        message: String,
        for duration: Duration,
        pollInterval: Duration = .milliseconds(10)
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + duration

        while clock.now < deadline {
            guard case .error(let currentMessage) = state.updateStatus, currentMessage == message else {
                return false
            }
            try? await Task.sleep(for: pollInterval)
        }

        return true
    }

    private func isUpToDate(_ status: UpdateStatus) -> Bool {
        if case .upToDate = status {
            return true
        }
        return false
    }

    struct PrefixScenario: Sendable, CustomTestStringConvertible {
        let language: AppLanguage
        let unexpectedPrefix: String

        var testDescription: String {
            "\(language.rawValue) omits '\(unexpectedPrefix)'"
        }
    }
}
