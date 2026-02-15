import SwiftUI

struct AgendaListView: View {
    let items: [AgendaItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Lịch trình")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(CalendarTheme.textPrimary)
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(CalendarTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(CalendarTheme.warmSurface, in: Capsule())
            }

            if items.isEmpty {
                Text("Không có sự kiện hay nhắc nhở.")
                    .font(.system(size: 12).italic())
                    .foregroundStyle(CalendarTheme.textTertiary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(items) { item in
                            AgendaRow(item: item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
            }
        }
    }
}

private struct AgendaRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentColor)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CalendarTheme.textPrimary)
                    .strikethrough(item.isCompleted)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.sourceTitle)
                    if let start = item.startDate {
                        Text("·")
                        Text(start, format: .dateTime.hour().minute())
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(CalendarTheme.textSecondary)
                .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .background(CalendarTheme.warmSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var accentColor: Color {
        switch item.kind {
        case .event:
            return CalendarTheme.accentVermillion
        case .reminder:
            return CalendarTheme.agendaDot
        }
    }
}
