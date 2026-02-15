import Foundation

actor LunarService {
    private let lunarMonthNames = [
        "Tháng Giêng", "Tháng Hai", "Tháng Ba", "Tháng Tư", "Tháng Năm", "Tháng Sáu",
        "Tháng Bảy", "Tháng Tám", "Tháng Chín", "Tháng Mười", "Tháng Mười Một", "Tháng Chạp",
    ]

    private let lunarDayNames = [
        "Mùng 1", "Mùng 2", "Mùng 3", "Mùng 4", "Mùng 5", "Mùng 6", "Mùng 7", "Mùng 8", "Mùng 9", "Mùng 10",
        "11", "12", "13", "14", "Rằm", "16", "17", "18", "19", "20",
        "21", "22", "23", "24", "25", "26", "27", "28", "29", "30",
    ]

    private let lunarFestivalMap: [String: String] = [
        "1-1": "Tết Nguyên Đán",
        "1-15": "Rằm tháng Giêng",
        "3-3": "Tết Hàn Thực",
        "5-5": "Tết Đoan Ngọ",
        "7-7": "Thất Tịch",
        "8-15": "Tết Trung Thu",
        "9-9": "Tết Trùng Cửu",
        "12-8": "Lễ Lạp Bát",
    ]

    private let solarTerms: [String: String]
    private let solarTermMapVI: [String: String] = [
        "Start of Spring": "Lập xuân",
        "Rain Water": "Vũ thủy",
        "Awakening of Insects": "Kinh trập",
        "Spring Equinox": "Xuân phân",
        "Clear and Bright": "Thanh minh",
        "Grain Rain": "Cốc vũ",
        "Start of Summer": "Lập hạ",
        "Grain Full": "Tiểu mãn",
        "Grain in Ear": "Mang chủng",
        "Summer Solstice": "Hạ chí",
        "Minor Heat": "Tiểu thử",
        "Major Heat": "Đại thử",
        "Start of Autumn": "Lập thu",
        "Limit of Heat": "Xử thử",
        "White Dew": "Bạch lộ",
        "Autumn Equinox": "Thu phân",
        "Cold Dew": "Hàn lộ",
        "Frost Descent": "Sương giáng",
        "Start of Winter": "Lập đông",
        "Minor Snow": "Tiểu tuyết",
        "Major Snow": "Đại tuyết",
        "Winter Solstice": "Đông chí",
        "Minor Cold": "Tiểu hàn",
        "Major Cold": "Đại hàn",
    ]

    init(bundle: Bundle = ResourceBundle.current) {
        if
            let url = bundle.url(forResource: "solar_terms", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        {
            solarTerms = decoded
        } else {
            solarTerms = [:]
        }
    }

    func dayInfo(
        for date: Date,
        locale: Locale,
        timeZone: TimeZone,
        showSolarTerms: Bool,
        showHolidays: Bool
    ) -> LunarDayInfo {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.locale = locale
        gregorian.timeZone = timeZone

        var chinese = Calendar(identifier: .chinese)
        chinese.locale = locale
        chinese.timeZone = timeZone

        let lunar = chinese.dateComponents([.month, .day, .isLeapMonth], from: date)
        let lunarMonth = max(1, lunar.month ?? 1)
        let lunarDay = max(1, lunar.day ?? 1)
        let monthIndex = lunarMonth - 1
        let dayIndex = lunarDay - 1

        let monthText = lunarMonthNames[min(monthIndex, lunarMonthNames.count - 1)]
        let dayText = lunarDayNames[min(dayIndex, lunarDayNames.count - 1)]
        let yearText = lunarYearText(for: date, calendar: chinese, timeZone: timeZone)
        let fullLunarDateText = fullLunarDateText(for: date, calendar: chinese, timeZone: timeZone)

        let isLeapMonth = lunar.isLeapMonth ?? false
        let monthDayKey = "\(lunarMonth)-\(lunarDay)"

        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateKeyFormatter.calendar = gregorian
        dateKeyFormatter.timeZone = timeZone
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"

        let dateKey = dateKeyFormatter.string(from: date)
        let solarTerm = showSolarTerms ? localizedSolarTerm(solarTerms[dateKey]) : nil

        let isNewYearsEve = isChineseNewYearsEve(date: date, gregorian: gregorian, chinese: chinese)
        var lunarFestival = lunarFestivalMap[monthDayKey]
        if isNewYearsEve {
            lunarFestival = "Giao thừa"
        }
        let isTetHoliday = lunarMonth == 1 && (1...3).contains(lunarDay)

        let holiday = showHolidays ? holidayInfo(for: date, locale: locale, calendar: gregorian) : nil

        var display = (lunar.day == 1) ? monthText : dayText
        if let solarTerm {
            display = solarTerm
        }
        if let lunarFestival {
            display = lunarFestival
        }
        let compactDisplay = compactLabel(for: display, fallbackDay: dayText)

        return LunarDayInfo(
            gregorianDate: gregorian.startOfDay(for: date),
            lunarYearText: yearText,
            fullLunarDateText: fullLunarDateText,
            lunarMonthText: isLeapMonth ? "Nhuận \(monthText)" : monthText,
            lunarDayText: dayText,
            displayLabel: display,
            compactDisplayLabel: compactDisplay,
            isLeapMonth: isLeapMonth,
            solarTerm: solarTerm,
            lunarFestival: lunarFestival,
            holiday: holiday,
            isImportantFestivalDay: isNewYearsEve || isTetHoliday
        )
    }

    func monthInfo(
        for monthAnchor: Date,
        locale: Locale,
        timeZone: TimeZone,
        showSolarTerms: Bool,
        showHolidays: Bool
    ) -> [LunarDayInfo] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = timeZone

        let monthStart = monthAnchor.startOfMonth(using: calendar)
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        return range.compactMap { day -> LunarDayInfo? in
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = day
            guard let date = calendar.date(from: components) else {
                return nil
            }
            return dayInfo(
                for: date,
                locale: locale,
                timeZone: timeZone,
                showSolarTerms: showSolarTerms,
                showHolidays: showHolidays
            )
        }
    }

    private func holidayInfo(for date: Date, locale: Locale, calendar: Calendar) -> HolidayInfo? {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let region = locale.region?.identifier.uppercased() ?? ""

        if region == "VN" {
            if month == 1, day == 1 {
                return HolidayInfo(name: "Tết Dương lịch", kind: .holiday)
            }
            if month == 4, day == 30 {
                return HolidayInfo(name: "Ngày Giải phóng miền Nam", kind: .holiday)
            }
            if month == 5, day == 1 {
                return HolidayInfo(name: "Quốc tế Lao động", kind: .holiday)
            }
            if month == 9, day == 2 {
                return HolidayInfo(name: "Quốc khánh", kind: .holiday)
            }
        } else if region == "US" {
            if month == 1, day == 1 {
                return HolidayInfo(name: "New Year's Day", kind: .holiday)
            }
            if month == 7, day == 4 {
                return HolidayInfo(name: "Independence Day", kind: .holiday)
            }
            if month == 12, day == 25 {
                return HolidayInfo(name: "Christmas Day", kind: .holiday)
            }
            if isThanksgiving(date: date, calendar: calendar) {
                return HolidayInfo(name: "Thanksgiving", kind: .holiday)
            }
        }

        if region == "CN" || region == "TW" || region == "HK" {
            if month == 1, day == 1 {
                return HolidayInfo(name: "New Year", kind: .holiday)
            }
            if month == 5, day == 1 {
                return HolidayInfo(name: "Labor Day", kind: .holiday)
            }
            if month == 10, day == 1 {
                return HolidayInfo(name: "National Day", kind: .holiday)
            }
        }

        return nil
    }

    private func isThanksgiving(date: Date, calendar: Calendar) -> Bool {
        let month = calendar.component(.month, from: date)
        guard month == 11 else {
            return false
        }
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let weekIndex = (day - 1) / 7
        return weekday == 5 && weekIndex == 3
    }

    private func isChineseNewYearsEve(date: Date, gregorian: Calendar, chinese: Calendar) -> Bool {
        let nextDay = date.addingDays(1, using: gregorian)
        let nextComponents = chinese.dateComponents([.month, .day], from: nextDay)
        return nextComponents.month == 1 && nextComponents.day == 1
    }

    private func lunarYearText(for date: Date, calendar: Calendar, timeZone: TimeZone) -> String {
        let cyclicalFormatter = DateFormatter()
        cyclicalFormatter.calendar = calendar
        cyclicalFormatter.locale = Locale(identifier: "vi_VN")
        cyclicalFormatter.timeZone = timeZone
        cyclicalFormatter.dateFormat = "U"

        let cyclical = cyclicalFormatter.string(from: date)
        if cyclical.isEmpty {
            return "Năm âm lịch"
        }
        return "Năm \(cyclical)"
    }

    private func fullLunarDateText(for date: Date, calendar: Calendar, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func localizedSolarTerm(_ term: String?) -> String? {
        guard let term else {
            return nil
        }
        return solarTermMapVI[term] ?? term
    }

    private func compactLabel(for label: String, fallbackDay: String) -> String {
        let map: [String: String] = [
            "Tết Nguyên Đán": "Tết",
            "Rằm tháng Giêng": "Rằm Giêng",
            "Tết Hàn Thực": "Hàn Thực",
            "Tết Đoan Ngọ": "Đoan Ngọ",
            "Thất Tịch": "Thất Tịch",
            "Tết Trung Thu": "Trung Thu",
            "Tết Trùng Cửu": "Trùng Cửu",
            "Lễ Lạp Bát": "Lạp Bát",
            "Giao thừa": "Giao thừa",
        ]
        if let mapped = map[label] {
            return mapped
        }
        if label.count > 10 {
            return fallbackDay
        }
        return label
    }
}

private enum ResourceBundle {
    static var current: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
}
