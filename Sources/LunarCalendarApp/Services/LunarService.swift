import Foundation

actor LunarService {
    private enum SupportedLanguage {
        case vi
        case en
        case zhHans

        static func from(locale: Locale) -> SupportedLanguage {
            let languageCode = locale.language.languageCode?.identifier.lowercased()
            switch languageCode {
            case "zh":
                return .zhHans
            case "vi":
                return .vi
            default:
                return .en
            }
        }
    }

    private let lunarMonthNamesVI = [
        "Tháng Giêng", "Tháng Hai", "Tháng Ba", "Tháng Tư", "Tháng Năm", "Tháng Sáu",
        "Tháng Bảy", "Tháng Tám", "Tháng Chín", "Tháng Mười", "Tháng Mười Một", "Tháng Chạp",
    ]

    private let lunarMonthNamesEN = [
        "Month 1", "Month 2", "Month 3", "Month 4", "Month 5", "Month 6",
        "Month 7", "Month 8", "Month 9", "Month 10", "Month 11", "Month 12",
    ]

    private let lunarMonthNamesZH = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月",
    ]

    private let lunarDayNamesVI = [
        "Mùng 1", "Mùng 2", "Mùng 3", "Mùng 4", "Mùng 5", "Mùng 6", "Mùng 7", "Mùng 8", "Mùng 9", "Mùng 10",
        "11", "12", "13", "14", "Rằm", "16", "17", "18", "19", "20",
        "21", "22", "23", "24", "25", "26", "27", "28", "29", "30",
    ]

    private let lunarDayNamesEN = [
        "Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7", "Day 8", "Day 9", "Day 10",
        "Day 11", "Day 12", "Day 13", "Day 14", "Day 15", "Day 16", "Day 17", "Day 18", "Day 19", "Day 20",
        "Day 21", "Day 22", "Day 23", "Day 24", "Day 25", "Day 26", "Day 27", "Day 28", "Day 29", "Day 30",
    ]

    private let lunarDayNamesZH = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十",
    ]

    private let lunarFestivalMapVI: [String: String] = [
        "1-1": "Tết Nguyên Đán",
        "1-15": "Rằm tháng Giêng",
        "3-3": "Tết Hàn Thực",
        "5-5": "Tết Đoan Ngọ",
        "7-7": "Thất Tịch",
        "8-15": "Tết Trung Thu",
        "9-9": "Tết Trùng Cửu",
        "12-8": "Lễ Lạp Bát",
    ]

    private let lunarFestivalMapEN: [String: String] = [
        "1-1": "Lunar New Year",
        "1-15": "Lantern Festival",
        "3-3": "Cold Food Festival",
        "5-5": "Dragon Boat Festival",
        "7-7": "Qixi Festival",
        "8-15": "Mid-Autumn Festival",
        "9-9": "Double Ninth Festival",
        "12-8": "Laba Festival",
    ]

    private let lunarFestivalMapZH: [String: String] = [
        "1-1": "春节",
        "1-15": "元宵节",
        "3-3": "寒食节",
        "5-5": "端午节",
        "7-7": "七夕",
        "8-15": "中秋节",
        "9-9": "重阳节",
        "12-8": "腊八节",
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

    private let solarTermMapZH: [String: String] = [
        "Start of Spring": "立春",
        "Rain Water": "雨水",
        "Awakening of Insects": "惊蛰",
        "Spring Equinox": "春分",
        "Clear and Bright": "清明",
        "Grain Rain": "谷雨",
        "Start of Summer": "立夏",
        "Grain Full": "小满",
        "Grain in Ear": "芒种",
        "Summer Solstice": "夏至",
        "Minor Heat": "小暑",
        "Major Heat": "大暑",
        "Start of Autumn": "立秋",
        "Limit of Heat": "处暑",
        "White Dew": "白露",
        "Autumn Equinox": "秋分",
        "Cold Dew": "寒露",
        "Frost Descent": "霜降",
        "Start of Winter": "立冬",
        "Minor Snow": "小雪",
        "Major Snow": "大雪",
        "Winter Solstice": "冬至",
        "Minor Cold": "小寒",
        "Major Cold": "大寒",
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

        let language = SupportedLanguage.from(locale: locale)
        let lunar = chinese.dateComponents([.month, .day, .isLeapMonth], from: date)
        let lunarMonth = max(1, lunar.month ?? 1)
        let lunarDay = max(1, lunar.day ?? 1)
        let monthIndex = lunarMonth - 1
        let dayIndex = lunarDay - 1

        let monthNames = lunarMonthNames(for: language)
        let dayNames = lunarDayNames(for: language)
        let monthText = monthNames[min(monthIndex, monthNames.count - 1)]
        let dayText = dayNames[min(dayIndex, dayNames.count - 1)]
        let yearText = lunarYearText(for: date, calendar: chinese, timeZone: timeZone, locale: locale, language: language)
        let fullLunarDateText = fullLunarDateText(for: date, calendar: chinese, timeZone: timeZone, locale: locale)

        let isLeapMonth = lunar.isLeapMonth ?? false
        let monthDayKey = "\(lunarMonth)-\(lunarDay)"

        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateKeyFormatter.calendar = gregorian
        dateKeyFormatter.timeZone = timeZone
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"

        let dateKey = dateKeyFormatter.string(from: date)
        let solarTerm = showSolarTerms ? localizedSolarTerm(solarTerms[dateKey], language: language) : nil

        let isNewYearsEve = isChineseNewYearsEve(date: date, gregorian: gregorian, chinese: chinese)
        var lunarFestival = lunarFestivalMap(for: language)[monthDayKey]
        if isNewYearsEve {
            lunarFestival = newYearsEveLabel(for: language)
        }
        let isTetHoliday = lunarMonth == 1 && (1...3).contains(lunarDay)

        let holiday = showHolidays ? holidayInfo(for: date, locale: locale, calendar: gregorian, language: language) : nil

        var display = (lunar.day == 1) ? monthText : dayText
        if let solarTerm {
            display = solarTerm
        }
        if let lunarFestival {
            display = lunarFestival
        }
        let compactDisplay = compactLabel(for: display, fallbackDay: dayText, language: language)

        return LunarDayInfo(
            gregorianDate: gregorian.startOfDay(for: date),
            lunarYearText: yearText,
            fullLunarDateText: fullLunarDateText,
            lunarMonthText: leapMonthText(monthText: monthText, isLeapMonth: isLeapMonth, language: language),
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

    private func holidayInfo(
        for date: Date,
        locale: Locale,
        calendar: Calendar,
        language: SupportedLanguage
    ) -> HolidayInfo? {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let region = locale.region?.identifier.uppercased() ?? ""

        if region == "VN" {
            if month == 1, day == 1 {
                return HolidayInfo(name: holidayName(.newYear, language: language), kind: .holiday)
            }
            if month == 4, day == 30 {
                return HolidayInfo(name: holidayName(.vnReunificationDay, language: language), kind: .holiday)
            }
            if month == 5, day == 1 {
                return HolidayInfo(name: holidayName(.laborDay, language: language), kind: .holiday)
            }
            if month == 9, day == 2 {
                return HolidayInfo(name: holidayName(.vnNationalDay, language: language), kind: .holiday)
            }
        } else if region == "US" {
            if month == 1, day == 1 {
                return HolidayInfo(name: holidayName(.newYear, language: language), kind: .holiday)
            }
            if month == 7, day == 4 {
                return HolidayInfo(name: holidayName(.usIndependenceDay, language: language), kind: .holiday)
            }
            if month == 12, day == 25 {
                return HolidayInfo(name: holidayName(.christmasDay, language: language), kind: .holiday)
            }
            if isThanksgiving(date: date, calendar: calendar) {
                return HolidayInfo(name: holidayName(.thanksgiving, language: language), kind: .holiday)
            }
        }

        if region == "CN" || region == "TW" || region == "HK" {
            if month == 1, day == 1 {
                return HolidayInfo(name: holidayName(.newYear, language: language), kind: .holiday)
            }
            if month == 5, day == 1 {
                return HolidayInfo(name: holidayName(.laborDay, language: language), kind: .holiday)
            }
            if month == 10, day == 1 {
                return HolidayInfo(name: holidayName(.cnNationalDay, language: language), kind: .holiday)
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

    private func lunarYearText(
        for date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        locale: Locale,
        language: SupportedLanguage
    ) -> String {
        let cyclicalFormatter = DateFormatter()
        cyclicalFormatter.calendar = calendar
        cyclicalFormatter.locale = locale
        cyclicalFormatter.timeZone = timeZone
        cyclicalFormatter.dateFormat = "U"

        let cyclical = cyclicalFormatter.string(from: date)
        if cyclical.isEmpty {
            return lunarYearFallback(for: language)
        }
        return "\(lunarYearPrefix(for: language)) \(cyclical)"
    }

    private func fullLunarDateText(for date: Date, calendar: Calendar, timeZone: TimeZone, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func localizedSolarTerm(_ term: String?, language: SupportedLanguage) -> String? {
        guard let term else {
            return nil
        }

        switch language {
        case .vi:
            return solarTermMapVI[term] ?? term
        case .en:
            return term
        case .zhHans:
            return solarTermMapZH[term] ?? term
        }
    }

    private func compactLabel(for label: String, fallbackDay: String, language: SupportedLanguage) -> String {
        let map = compactFestivalMap(for: language)
        if let mapped = map[label] {
            return mapped
        }
        if label.count > 10 {
            return fallbackDay
        }
        return label
    }

    private func lunarMonthNames(for language: SupportedLanguage) -> [String] {
        switch language {
        case .vi:
            lunarMonthNamesVI
        case .en:
            lunarMonthNamesEN
        case .zhHans:
            lunarMonthNamesZH
        }
    }

    private func lunarDayNames(for language: SupportedLanguage) -> [String] {
        switch language {
        case .vi:
            lunarDayNamesVI
        case .en:
            lunarDayNamesEN
        case .zhHans:
            lunarDayNamesZH
        }
    }

    private func lunarFestivalMap(for language: SupportedLanguage) -> [String: String] {
        switch language {
        case .vi:
            lunarFestivalMapVI
        case .en:
            lunarFestivalMapEN
        case .zhHans:
            lunarFestivalMapZH
        }
    }

    private func compactFestivalMap(for language: SupportedLanguage) -> [String: String] {
        switch language {
        case .vi:
            return [
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
        case .en:
            return [
                "Lunar New Year": "LNY",
                "Lantern Festival": "Lantern",
                "Cold Food Festival": "Cold Food",
                "Dragon Boat Festival": "Boat Fest",
                "Qixi Festival": "Qixi",
                "Mid-Autumn Festival": "Mid-Autumn",
                "Double Ninth Festival": "Ninth",
                "Laba Festival": "Laba",
                "Lunar New Year's Eve": "NY Eve",
            ]
        case .zhHans:
            return [
                "春节": "春节",
                "元宵节": "元宵",
                "寒食节": "寒食",
                "端午节": "端午",
                "七夕": "七夕",
                "中秋节": "中秋",
                "重阳节": "重阳",
                "腊八节": "腊八",
                "除夕": "除夕",
            ]
        }
    }

    private func leapMonthText(monthText: String, isLeapMonth: Bool, language: SupportedLanguage) -> String {
        guard isLeapMonth else {
            return monthText
        }

        switch language {
        case .vi:
            return "Nhuận \(monthText)"
        case .en:
            return "Leap \(monthText)"
        case .zhHans:
            return "闰\(monthText)"
        }
    }

    private func newYearsEveLabel(for language: SupportedLanguage) -> String {
        switch language {
        case .vi:
            return "Giao thừa"
        case .en:
            return "Lunar New Year's Eve"
        case .zhHans:
            return "除夕"
        }
    }

    private func lunarYearPrefix(for language: SupportedLanguage) -> String {
        switch language {
        case .vi:
            return "Năm"
        case .en:
            return "Year"
        case .zhHans:
            return "农历年"
        }
    }

    private func lunarYearFallback(for language: SupportedLanguage) -> String {
        switch language {
        case .vi:
            return "Năm âm lịch"
        case .en:
            return "Lunar Year"
        case .zhHans:
            return "农历年"
        }
    }

    private enum HolidayName {
        case newYear
        case vnReunificationDay
        case laborDay
        case vnNationalDay
        case usIndependenceDay
        case christmasDay
        case thanksgiving
        case cnNationalDay
    }

    private func holidayName(_ holiday: HolidayName, language: SupportedLanguage) -> String {
        switch language {
        case .vi:
            switch holiday {
            case .newYear:
                return "Tết Dương lịch"
            case .vnReunificationDay:
                return "Ngày Giải phóng miền Nam"
            case .laborDay:
                return "Quốc tế Lao động"
            case .vnNationalDay:
                return "Quốc khánh"
            case .usIndependenceDay:
                return "Quốc khánh Hoa Kỳ"
            case .christmasDay:
                return "Lễ Giáng sinh"
            case .thanksgiving:
                return "Lễ Tạ ơn"
            case .cnNationalDay:
                return "Quốc khánh Trung Quốc"
            }
        case .en:
            switch holiday {
            case .newYear:
                return "New Year's Day"
            case .vnReunificationDay:
                return "Reunification Day"
            case .laborDay:
                return "Labor Day"
            case .vnNationalDay:
                return "National Day"
            case .usIndependenceDay:
                return "Independence Day"
            case .christmasDay:
                return "Christmas Day"
            case .thanksgiving:
                return "Thanksgiving"
            case .cnNationalDay:
                return "National Day"
            }
        case .zhHans:
            switch holiday {
            case .newYear:
                return "元旦"
            case .vnReunificationDay:
                return "南方解放日"
            case .laborDay:
                return "劳动节"
            case .vnNationalDay:
                return "越南国庆日"
            case .usIndependenceDay:
                return "美国独立日"
            case .christmasDay:
                return "圣诞节"
            case .thanksgiving:
                return "感恩节"
            case .cnNationalDay:
                return "国庆节"
            }
        }
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
