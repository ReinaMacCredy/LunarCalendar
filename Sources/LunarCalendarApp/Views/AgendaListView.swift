import SwiftUI

struct AgendaListView: View {
    let items: [AgendaItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Agenda")
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quinary, in: Capsule())
            }

            if items.isEmpty {
                Text("No events or reminders for the selected range.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(items) { item in
                            AgendaRow(item: item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 210)
            }
        }
    }
}

private struct AgendaRow: View {
    let item: AgendaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .foregroundStyle(item.kind == .event ? .blue : .orange)
                Text(item.title)
                    .font(.subheadline)
                    .strikethrough(item.isCompleted)
                Spacer(minLength: 0)
                Text(kindText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quinary, in: Capsule())
            }

            HStack {
                Text(item.sourceTitle)
                Spacer(minLength: 0)
                Text(item.sortDate, format: .dateTime.month().day().hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(9)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch item.kind {
        case .event:
            return "calendar"
        case .reminder:
            return "checkmark.circle"
        }
    }

    private var kindText: String {
        switch item.kind {
        case .event:
            return "Event"
        case .reminder:
            return "Reminder"
        }
    }
}
