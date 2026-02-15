import Foundation

extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        guard let interval = calendar.dateInterval(of: .month, for: self) else {
            return self
        }
        return interval.start
    }

    func addingDays(_ days: Int, using calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}

struct CalendarGridBuilder {
    static func weekdaySymbols(calendar: Calendar, firstWeekday: Int) -> [String] {
        let raw = ["S", "M", "T", "W", "T", "F", "S"]
        let shift = max(0, min(6, firstWeekday - 1))
        return Array(raw[shift...] + raw[..<shift])
    }

    static func monthCells(
        monthStart: Date,
        selectedDate: Date,
        monthInfos: [Date: LunarDayInfo],
        agendaDays: Set<Date>,
        firstWeekday: Int,
        calendar: Calendar
    ) -> [CalendarDayCell] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstDayWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstDayWeekday - firstWeekday + 7) % 7
        let cellCount = 42

        var cells: [CalendarDayCell] = []
        cells.reserveCapacity(cellCount)

        for index in 0..<cellCount {
            let dayOffset = index - leading
            let dayDate = monthStart.addingDays(dayOffset, using: calendar)
            let dayStart = calendar.startOfDay(for: dayDate)
            let info = monthInfos[dayStart]

            let lunarText = info?.compactDisplayLabel ?? ""
            let dayText = "\(calendar.component(.day, from: dayDate))"
            let isToday = calendar.isDateInToday(dayDate)
            let isSelected = calendar.isDate(dayDate, inSameDayAs: selectedDate)
            let hasAgenda = agendaDays.contains(dayStart)
            let showsHolidayMarker = info?.holiday != nil
            let highlightsFestival = info?.isImportantFestivalDay ?? false
            let isCurrentMonth = dayOffset >= 0 && dayOffset < monthRange.count

            cells.append(
                CalendarDayCell(
                    id: "date-\(Int(dayStart.timeIntervalSince1970))",
                    date: dayDate,
                    dayText: dayText,
                    lunarText: lunarText,
                    isCurrentMonth: isCurrentMonth,
                    showsHolidayMarker: showsHolidayMarker,
                    hasAgenda: hasAgenda,
                    isToday: isToday,
                    isSelected: isSelected,
                    highlightsFestival: highlightsFestival
                )
            )
        }

        return cells
    }
}
