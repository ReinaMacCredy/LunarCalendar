import AppKit
import EventKit
import Observation
import SwiftUI

struct CalendarPopoverView: View {
    @Bindable var model: AppState
    @State private var isJumpDatePopoverPresented = false
    @State private var jumpYear = Calendar.current.component(.year, from: .now)
    @State private var jumpMonth = Calendar.current.component(.month, from: .now)
    @State private var jumpDay = Calendar.current.component(.day, from: .now)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            MonthGridView(
                weekdaySymbols: model.weekdaySymbols,
                cells: model.monthCells,
                onSelect: model.selectDate
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(width: 536, height: 660)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.97),
                    Color(nsColor: .windowBackgroundColor).opacity(0.94),
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .task {
            await model.bootstrapIfNeeded()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await MainActor.run {
                    model.refresh(reason: .timerTick)
                }
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                await MainActor.run {
                    model.refresh(reason: .eventStoreChanged)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(monthHeaderTitle)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            HStack(spacing: 20) {
                navButton(systemName: "chevron.left", action: model.showPreviousMonth)

                Button {
                    syncJumpSelection(with: model.selectedDate)
                    isJumpDatePopoverPresented.toggle()
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.primary.opacity(0.88))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isJumpDatePopoverPresented, arrowEdge: .top) {
                    jumpDatePopover
                }

                navButton(systemName: "chevron.right", action: model.showNextMonth)

                Button(action: openSettingsWindow) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.78))
                }
                .buttonStyle(.plain)
                .help("Cài đặt")
            }
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.88))
        }
        .buttonStyle(.plain)
    }

    private func openSettingsWindow() {
        SettingsWindowPresenter.show(model: model)
    }

    private var jumpDatePopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Đi đến ngày")
                    .font(.headline)
                Spacer()
                Button("Hôm nay") {
                    syncJumpSelection(with: .now)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                quickJumpButton(title: "-1 năm", yearOffset: -1)
                quickJumpButton(title: "+1 năm", yearOffset: 1)
                Spacer(minLength: 0)
                Text(jumpDatePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                jumpPicker(title: "Ngày") {
                    Picker("Ngày", selection: $jumpDay) {
                        ForEach(1...maxJumpDay, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                jumpPicker(title: "Tháng") {
                    Picker("Tháng", selection: $jumpMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("Tháng \(month)").tag(month)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                jumpPicker(title: "Năm") {
                    Picker("Năm", selection: $jumpYear) {
                        ForEach(jumpYearRange, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
            .onChange(of: jumpMonth) { _, _ in
                clampJumpDay()
            }
            .onChange(of: jumpYear) { _, _ in
                clampJumpDay()
            }

            HStack {
                Button("Hủy") {
                    isJumpDatePopoverPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Đi") {
                    if let selectedDate = jumpSelectionDate {
                        model.jumpToDate(selectedDate)
                        isJumpDatePopoverPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .frame(width: 350)
    }

    private var monthHeaderTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: model.displayMonth)
    }

    private var jumpYearRange: ClosedRange<Int> {
        let currentYear = Calendar.current.component(.year, from: .now)
        return (currentYear - 100)...(currentYear + 100)
    }

    private var maxJumpDay: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = jumpYear
        components.month = jumpMonth
        components.day = 1
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date)
        else {
            return 31
        }
        return range.count
    }

    private var jumpSelectionDate: Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = jumpYear
        components.month = jumpMonth
        components.day = min(jumpDay, maxJumpDay)
        components.hour = 12
        return calendar.date(from: components)
    }

    private var jumpDatePreview: String {
        guard let date = jumpSelectionDate else {
            return "--"
        }
        return date.formatted(.dateTime.locale(Locale(identifier: "vi_VN")).day().month().year())
    }

    private func syncJumpSelection(with date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        jumpYear = components.year ?? jumpYear
        jumpMonth = components.month ?? jumpMonth
        jumpDay = components.day ?? jumpDay
        clampJumpDay()
    }

    private func clampJumpDay() {
        jumpDay = min(jumpDay, maxJumpDay)
    }

    private func quickJumpButton(title: String, yearOffset: Int) -> some View {
        Button(title) {
            jumpYear += yearOffset
            clampJumpDay()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func jumpPicker<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
