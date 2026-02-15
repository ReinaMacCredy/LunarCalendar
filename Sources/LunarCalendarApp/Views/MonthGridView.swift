import SwiftUI

struct MonthGridView: View {
    let weekdaySymbols: [String]
    let cells: [CalendarDayCell]
    let onSelect: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(CalendarTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(cells) { cell in
                    dayCell(cell)
                        .frame(maxWidth: .infinity, minHeight: 62)
                }
            }
        }
    }

    private func dayCell(_ cell: CalendarDayCell) -> some View {
        Button {
            if let date = cell.date {
                onSelect(date)
            }
        } label: {
            VStack(spacing: 2) {
                dayNumber(for: cell)

                Text(cell.lunarText)
                    .font(.system(size: 11, weight: cell.highlightsFestival ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(lunarTextColor(for: cell))

                dotMarkers(for: cell)
            }
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cellBackgroundColor(for: cell))
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func dayNumber(for cell: CalendarDayCell) -> some View {
        let text = Text(cell.dayText)
            .font(.system(size: 18, weight: .medium))
            .monospacedDigit()

        if cell.isToday {
            text
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .background(CalendarTheme.accentVermillion, in: Capsule())
        } else {
            text
                .foregroundStyle(dayTextColor(for: cell))
        }
    }

    private func dayTextColor(for cell: CalendarDayCell) -> Color {
        if !cell.isCurrentMonth {
            return CalendarTheme.textTertiary
        }
        if cell.isSelected {
            return CalendarTheme.accentVermillion
        }
        return CalendarTheme.textPrimary
    }

    private func lunarTextColor(for cell: CalendarDayCell) -> Color {
        if !cell.isCurrentMonth {
            return CalendarTheme.textTertiary
        }
        if cell.isToday {
            return CalendarTheme.textSecondary
        }
        if cell.highlightsFestival {
            return CalendarTheme.festivalGold
        }
        if cell.isSelected {
            return CalendarTheme.accentVermillion
        }
        return CalendarTheme.textSecondary
    }

    private func cellBackgroundColor(for cell: CalendarDayCell) -> Color {
        if cell.isSelected && !cell.isToday {
            return CalendarTheme.accentVermillionSoft
        } else if cell.highlightsFestival && cell.isCurrentMonth {
            return CalendarTheme.festivalGlow
        }
        return Color.clear
    }

    @ViewBuilder
    private func dotMarkers(for cell: CalendarDayCell) -> some View {
        if cell.hasAgenda || cell.showsHolidayMarker {
            HStack(spacing: 3) {
                if cell.showsHolidayMarker {
                    Circle()
                        .fill(CalendarTheme.holidayDot)
                        .frame(width: 5, height: 5)
                }
                if cell.hasAgenda {
                    Circle()
                        .fill(CalendarTheme.agendaDot)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        } else {
            Color.clear
                .frame(height: 5)
        }
    }
}
