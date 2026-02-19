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

    func testMenuBarTitleLunarCompactOmitsVietnamesePrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .vietnamese
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("ÂL "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testMenuBarTitleLunarCompactOmitsEnglishPrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .english
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("Lunar "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testMenuBarTitleLunarCompactOmitsChinesePrefix() async {
        let state = await MainActor.run {
            AppState()
        }

        await MainActor.run {
            state.settings.iconStyle = .lunarCompact
            state.settings.language = .chineseSimplified
            state.menuBarDate = Date(timeIntervalSince1970: 1_739_746_800)
            let title = state.menuBarTitle
            XCTAssertFalse(title.hasPrefix("农历 "), "Unexpected prefix in menu bar title: \(title)")
        }
    }

    func testUpToDateStatusAutoResetsToIdleAfterConfiguredDelay() async {
        let state = await MainActor.run {
            AppState(upToDateStatusDisplayDuration: .milliseconds(50))
        }

        await MainActor.run {
            state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
            guard case .upToDate = state.updateStatus else {
                XCTFail("Expected update status to be up to date")
                return
            }
        }

        try? await Task.sleep(for: .milliseconds(150))

        await MainActor.run {
            guard case .idle = state.updateStatus else {
                XCTFail("Expected update status to reset to idle")
                return
            }
        }
    }

    func testUpToDateStatusResetDoesNotOverrideNewStatus() async {
        let state = await MainActor.run {
            AppState(upToDateStatusDisplayDuration: .milliseconds(50))
        }

        await MainActor.run {
            state.applyUpdateCheckResult(.upToDate(currentVersion: "1.2.3"))
            state.updateStatus = .error("network failed")
        }

        try? await Task.sleep(for: .milliseconds(150))

        await MainActor.run {
            guard case .error(let message) = state.updateStatus else {
                XCTFail("Expected update status to remain error")
                return
            }
            XCTAssertEqual(message, "network failed")
        }
    }

    func testSettingsStorePersistsPendingDownloadedUpdate() async {
        let suiteName = makeIsolatedDefaultsSuiteName()
        let settingsStore = SettingsStore(suiteName: suiteName)

        var settings = UserSettings()
        settings.pendingDownloadedUpdate = DownloadedUpdate(
            latestVersion: "1.2.3",
            filePath: "/tmp/lunar-calendar-1.2.3.zip",
            extractedAppPath: "/tmp/LunarCalendar.app"
        )
        await settingsStore.save(settings)

        let persisted = await settingsStore.load()
        XCTAssertEqual(persisted.pendingDownloadedUpdate, settings.pendingDownloadedUpdate)
    }

    func testSelectDateAndJumpToDateNormalizeSameWay() async {
        let state = await MainActor.run {
            AppState()
        }
        let rawDate = Date(timeIntervalSince1970: 1_739_875_212)

        await MainActor.run {
            state.selectDate(rawDate)
            let selectedAfterSelect = state.selectedDate
            let displayMonthAfterSelect = state.displayMonth

            state.jumpToDate(rawDate)

            XCTAssertEqual(state.selectedDate, selectedAfterSelect)
            XCTAssertEqual(state.displayMonth, displayMonthAfterSelect)
            XCTAssertEqual(state.selectedDate, state.appCalendar.startOfDay(for: rawDate))
        }
    }

    func testRefreshDerivedOutputDeduplicatesSortsAndFiltersDetailAgenda() {
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

        XCTAssertEqual(output.monthCells.count, 42)
        XCTAssertEqual(output.detailAgenda.map(\.id), ["event:beta", "event:shared"])
        XCTAssertEqual(output.detailAgenda.last?.title, "Updated Shared Event")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        XCTAssertTrue(
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
