import SwiftUI

struct MonthGridView: View {
    let weekdaySymbols: [String]
    let cells: [CalendarDayCell]
    let onSelect: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 8), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(cells) { cell in
                    dayCell(cell)
                        .frame(maxWidth: .infinity, minHeight: 72)
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
            VStack(spacing: 1) {
                Text(cell.dayText)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(dayTextColor(for: cell))

                Text(cell.lunarText)
                    .font(.system(size: 12, weight: cell.highlightsFestival ? .semibold : .regular, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(lunarTextColor(for: cell))
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 72)
            .opacity(cell.isCurrentMonth ? 1 : 0.35)
            .overlay(markerOverlay(for: cell), alignment: .topTrailing)
            .overlay(selectionOverlay(for: cell))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func dayTextColor(for cell: CalendarDayCell) -> Color {
        if cell.isSelected {
            return .accentColor
        }
        return .primary
    }

    private func lunarTextColor(for cell: CalendarDayCell) -> Color {
        if cell.isSelected {
            return .accentColor
        }
        if cell.highlightsFestival {
            return .red
        }
        return .primary
    }

    @ViewBuilder
    private func selectionOverlay(for cell: CalendarDayCell) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(cell.isSelected ? Color.accentColor : .clear, lineWidth: 3)
    }

    @ViewBuilder
    private func markerOverlay(for cell: CalendarDayCell) -> some View {
        if cell.hasAgenda || cell.showsHolidayMarker {
            HStack(spacing: 2) {
                if cell.showsHolidayMarker {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
                if cell.hasAgenda {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                }
            }
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
    }
}
