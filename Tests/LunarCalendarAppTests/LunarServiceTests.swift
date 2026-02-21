@testable import LunarCalendarApp
import Foundation
import Testing

@Suite("Lunar service")
struct LunarServiceTests {
    @Test("Month info count matches Gregorian month length")
    func monthInfoCountMatchesGregorianMonth() async throws {
        let service = LunarService()
        let calendar = Self.utcGregorianCalendar()
        let month = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))

        let infos = await service.monthInfo(
            for: month,
            locale: Locale(identifier: "en_US"),
            timeZone: calendar.timeZone,
            showSolarTerms: true,
            showHolidays: true
        )

        #expect(infos.count == 28)
    }

    @Test("Known Tet date maps to festival")
    func knownTetDateMapsToFestival() async throws {
        let service = LunarService()
        let calendar = Self.utcGregorianCalendar()
        let date = try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: 10)))

        let info = await service.dayInfo(
            for: date,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )

        #expect(info.lunarFestival == "Tết Nguyên Đán")
    }

    @Test("Lunar info fields are populated across ten years", arguments: Array(0..<120))
    func lunarInfoAcrossTenYears(monthOffset: Int) async throws {
        let service = LunarService()
        let calendar = Self.utcGregorianCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2021, month: 1, day: 15)))

        let date = try #require(
            calendar.date(byAdding: .month, value: monthOffset, to: start),
            "Failed to build date at month offset \(monthOffset)"
        )

        let info = await service.dayInfo(
            for: date,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: true,
            showHolidays: true
        )

        #expect(!info.lunarYearText.isEmpty)
        #expect(!info.lunarMonthText.isEmpty)
        #expect(!info.lunarDayText.isEmpty)
    }

    @Test("Tet period days are highlighted", arguments: [9, 10, 11, 12])
    func tetPeriodDaysAreFlaggedForHighlight(day: Int) async throws {
        let service = LunarService()
        let calendar = Self.utcGregorianCalendar()
        let date = try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: day)))

        let info = await service.dayInfo(
            for: date,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )

        #expect(info.isImportantFestivalDay)
    }

    private static func utcGregorianCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }
}
