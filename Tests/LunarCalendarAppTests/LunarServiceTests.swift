@testable import LunarCalendarApp
import XCTest

final class LunarServiceTests: XCTestCase {
    func testMonthInfoCountMatchesGregorianMonth() async {
        let service = LunarService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let month = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!

        let infos = await service.monthInfo(
            for: month,
            locale: Locale(identifier: "en_US"),
            timeZone: calendar.timeZone,
            showSolarTerms: true,
            showHolidays: true
        )

        XCTAssertEqual(infos.count, 28)
    }

    func testKnownTetDateMapsToFestival() async {
        let service = LunarService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 10))!

        let info = await service.dayInfo(
            for: date,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )

        XCTAssertEqual(info.lunarFestival, "Tết Nguyên Đán")
    }

    func testLunarInfoAcrossTenYears() async {
        let service = LunarService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2021, month: 1, day: 15))!

        for monthOffset in 0..<120 {
            guard let date = calendar.date(byAdding: .month, value: monthOffset, to: start) else {
                XCTFail("Failed to build date at month offset \(monthOffset)")
                return
            }

            let info = await service.dayInfo(
                for: date,
                locale: Locale(identifier: "vi_VN"),
                timeZone: calendar.timeZone,
                showSolarTerms: true,
                showHolidays: true
            )

            XCTAssertFalse(info.lunarYearText.isEmpty)
            XCTAssertFalse(info.lunarMonthText.isEmpty)
            XCTAssertFalse(info.lunarDayText.isEmpty)
        }
    }

    func testTetPeriodDaysAreFlaggedForHighlight() async {
        let service = LunarService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let tetEve = calendar.date(from: DateComponents(year: 2024, month: 2, day: 9))!
        let tetDay1 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 10))!
        let tetDay2 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 11))!
        let tetDay3 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 12))!

        let infoEve = await service.dayInfo(
            for: tetEve,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )
        let infoDay1 = await service.dayInfo(
            for: tetDay1,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )
        let infoDay2 = await service.dayInfo(
            for: tetDay2,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )
        let infoDay3 = await service.dayInfo(
            for: tetDay3,
            locale: Locale(identifier: "vi_VN"),
            timeZone: calendar.timeZone,
            showSolarTerms: false,
            showHolidays: false
        )

        XCTAssertTrue(infoEve.isImportantFestivalDay)
        XCTAssertTrue(infoDay1.isImportantFestivalDay)
        XCTAssertTrue(infoDay2.isImportantFestivalDay)
        XCTAssertTrue(infoDay3.isImportantFestivalDay)
    }
}
