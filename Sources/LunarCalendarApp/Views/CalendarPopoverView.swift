import AppKit
import EventKit
import Observation
import SwiftUI

struct CalendarPopoverView: View {
    @Bindable var model: AppState
    @State private var isJumpDatePopoverPresented = false
    @State private var jumpYear = Calendar(identifier: .gregorian).component(.year, from: .now)
    @State private var jumpMonth = Calendar(identifier: .gregorian).component(.month, from: .now)
    @State private var jumpDay = Calendar(identifier: .gregorian).component(.day, from: .now)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            MonthGridView(
                weekdaySymbols: model.weekdaySymbols,
                cells: model.monthCells,
                onSelect: model.selectDate
            )

            if !model.agendaItems.isEmpty {
                Divider()
                    .overlay(CalendarTheme.warmBorder)

                AgendaListView(items: model.agendaItems)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(width: 480, height: 620)
        .background(CalendarTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CalendarTheme.warmBorder.opacity(0.5), lineWidth: 0.5)
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
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            model.refresh(reason: .eventStoreChanged)
        }
        .environment(\.locale, model.appLocale)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(monthName)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(CalendarTheme.textPrimary)

                Text(yearText)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(CalendarTheme.textSecondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 16) {
                navButton(systemName: "chevron.left", action: model.showPreviousMonth)

                Button {
                    syncJumpSelection(with: model.selectedDate)
                    isJumpDatePopoverPresented.toggle()
                } label: {
                    Circle()
                        .fill(CalendarTheme.accentVermillion)
                        .frame(width: 7, height: 7)
                }
                .buttonStyle(.plain)
                .help(L10n.tr("Hôm nay", locale: model.appLocale, fallback: "Hôm nay"))
                .popover(isPresented: $isJumpDatePopoverPresented, arrowEdge: .top) {
                    jumpDatePopover
                }

                navButton(systemName: "chevron.right", action: model.showNextMonth)

                Button(action: openSettingsWindow) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(CalendarTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.tr("Cài đặt", locale: model.appLocale, fallback: "Cài đặt"))
            }
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CalendarTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private func openSettingsWindow() {
        SettingsWindowPresenter.show(model: model)
    }

    // MARK: - Header text

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = model.appLocale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "MMMM"
        return formatter.string(from: model.displayMonth)
    }

    private var yearText: String {
        let formatter = DateFormatter()
        formatter.locale = model.appLocale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy"
        return formatter.string(from: model.displayMonth)
    }

    // MARK: - Jump date popover

    private var jumpDatePopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("Đi đến ngày", locale: model.appLocale, fallback: "Đi đến ngày"))
                    .font(.headline)
                Spacer()
                Button(L10n.tr("Hôm nay", locale: model.appLocale, fallback: "Hôm nay")) {
                    syncJumpSelection(with: .now)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                quickJumpButton(title: L10n.tr("-1 năm", locale: model.appLocale, fallback: "-1 năm"), yearOffset: -1)
                quickJumpButton(title: L10n.tr("+1 năm", locale: model.appLocale, fallback: "+1 năm"), yearOffset: 1)
                Spacer(minLength: 0)
                Text(jumpDatePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                jumpPicker(title: L10n.tr("Ngày", locale: model.appLocale, fallback: "Ngày")) {
                    Picker(L10n.tr("Ngày", locale: model.appLocale, fallback: "Ngày"), selection: $jumpDay) {
                        ForEach(1...maxJumpDay, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                jumpPicker(title: L10n.tr("Tháng", locale: model.appLocale, fallback: "Tháng")) {
                    Picker(L10n.tr("Tháng", locale: model.appLocale, fallback: "Tháng"), selection: $jumpMonth) {
                        ForEach(1...12, id: \.self) { month in
                            let monthLabel = String(
                                format: L10n.tr("Tháng %@", locale: model.appLocale, fallback: "Tháng %@"),
                                locale: model.appLocale,
                                "\(month)"
                            )
                            Text(monthLabel).tag(month)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                jumpPicker(title: L10n.tr("Năm", locale: model.appLocale, fallback: "Năm")) {
                    Picker(L10n.tr("Năm", locale: model.appLocale, fallback: "Năm"), selection: $jumpYear) {
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
                Button(L10n.tr("Hủy", locale: model.appLocale, fallback: "Hủy")) {
                    isJumpDatePopoverPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(L10n.tr("Đi", locale: model.appLocale, fallback: "Đi")) {
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

    private var jumpYearRange: ClosedRange<Int> {
        let currentYear = jumpCalendar.component(.year, from: .now)
        return (currentYear - 100)...(currentYear + 100)
    }

    private var maxJumpDay: Int {
        var components = DateComponents()
        components.year = jumpYear
        components.month = jumpMonth
        components.day = 1
        guard let date = jumpCalendar.date(from: components),
              let range = jumpCalendar.range(of: .day, in: .month, for: date)
        else {
            return 31
        }
        return range.count
    }

    private var jumpSelectionDate: Date? {
        var components = DateComponents()
        components.year = jumpYear
        components.month = jumpMonth
        components.day = min(jumpDay, maxJumpDay)
        components.hour = 12
        return jumpCalendar.date(from: components)
    }

    private var jumpDatePreview: String {
        guard let date = jumpSelectionDate else {
            return "--"
        }
        return date.formatted(.dateTime.locale(model.appLocale).day().month().year())
    }

    private func syncJumpSelection(with date: Date) {
        let components = jumpCalendar.dateComponents([.year, .month, .day], from: date)
        jumpYear = components.year ?? jumpYear
        jumpMonth = components.month ?? jumpMonth
        jumpDay = components.day ?? jumpDay
        clampJumpDay()
    }

    private func clampJumpDay() {
        jumpDay = min(jumpDay, maxJumpDay)
    }

    private var jumpCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = model.appLocale
        calendar.timeZone = model.appCalendar.timeZone
        return calendar
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
