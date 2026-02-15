import Observation
import SwiftUI

struct SettingsContentView: View {
    @Bindable var model: AppState
    var compact: Bool = false

    private var eventSources: [CalendarSource] {
        model.availableSources.filter { $0.kind == .event }
    }

    private var reminderSources: [CalendarSource] {
        model.availableSources.filter { $0.kind == .reminder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            displayCard
            menuBarCard
            behaviorCard
            sourceCard
        }
        .onChange(of: model.settings) { _, _ in
            model.settingsDidChange()
        }
    }

    private var displayCard: some View {
        SettingsCard(title: "Calendar Display", subtitle: "Control lunar details shown in the calendar", icon: "calendar") {
            Toggle("Show Holidays", isOn: $model.settings.showHolidays)
            Toggle("Show Solar Terms", isOn: $model.settings.showSolarTerms)
            Toggle("Show Reminders", isOn: $model.settings.showReminders)

            HStack {
                Text("First Weekday")
                Spacer()
                Picker("First Weekday", selection: $model.settings.firstWeekday) {
                    Text("Sun").tag(1)
                    Text("Mon").tag(2)
                    Text("Tue").tag(3)
                    Text("Wed").tag(4)
                    Text("Thu").tag(5)
                    Text("Fri").tag(6)
                    Text("Sat").tag(7)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: compact ? 100 : 130)
            }
        }
    }

    private var menuBarCard: some View {
        SettingsCard(title: "Menu Bar", subtitle: "Choose how the top bar label is rendered", icon: "textformat") {
            HStack {
                Text("Style")
                Spacer()
                Picker("Icon", selection: $model.settings.iconStyle) {
                    ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                        Text(style.title).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: compact ? 130 : 180)
            }

            if model.settings.iconStyle == .customFormat {
                TextField("Custom format (DateFormatter)", text: $model.settings.customIconFormat)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Preview")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(model.menuBarTitle)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var behaviorCard: some View {
        SettingsCard(title: "Behavior", subtitle: "Startup and application actions", icon: "gearshape") {
            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            Divider()

            updateRow

            if compact {
                SettingsLink {
                    Label("Open Full Settings", systemImage: "slider.horizontal.3")
                        .font(.footnote)
                }
                .buttonStyle(.link)
            }
        }
    }

    private var updateRow: some View {
        HStack {
            switch model.updateStatus {
            case .idle:
                Text("Check for updates")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Check Now") {
                    model.checkForUpdates()
                }
                .controlSize(.small)

            case .checking:
                ProgressView()
                    .controlSize(.small)
                Text("Checking for updates…")
                    .foregroundStyle(.secondary)
                Spacer()

            case .upToDate(let version):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Up to date (v\(version))")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Dismiss") {
                    model.dismissUpdateStatus()
                }
                .controlSize(.small)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

            case .available(let latestVersion, _):
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text("v\(latestVersion) available")
                Spacer()
                Button("View Release") {
                    model.openLatestRelease()
                }
                .controlSize(.small)

            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Button("Retry") {
                    model.dismissUpdateStatus()
                    model.checkForUpdates()
                }
                .controlSize(.small)
            }
        }
        .font(.footnote)
    }

    private var sourceCard: some View {
        SettingsCard(title: "Calendar Sources", subtitle: "Select which calendars and reminder lists are included", icon: "checklist") {
            if eventSources.isEmpty && reminderSources.isEmpty {
                Text("No sources available yet. Grant Calendar and Reminders access first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !eventSources.isEmpty {
                sourceGroup(title: "Event Calendars", sources: eventSources)
            }

            if !reminderSources.isEmpty {
                sourceGroup(title: "Reminder Lists", sources: reminderSources)
            }
        }
    }

    private func sourceGroup(title: String, sources: [CalendarSource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(sources) { source in
                Toggle(
                    source.title,
                    isOn: Binding(
                        get: { model.isSourceSelected(source) },
                        set: { model.setSource(source, isSelected: $0) }
                    )
                )
                .toggleStyle(.switch)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quinary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
