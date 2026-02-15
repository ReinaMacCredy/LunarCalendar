import SwiftUI

struct GeneralSettingsTab: View {
    @Bindable var model: AppState

    var body: some View {
        Form {
            Section("Calendar Display") {
                Toggle("Show Holidays", isOn: $model.settings.showHolidays)
                Toggle("Show Solar Terms", isOn: $model.settings.showSolarTerms)
                Toggle("Show Reminders", isOn: $model.settings.showReminders)

                Picker("First Weekday", selection: $model.settings.firstWeekday) {
                    Text("Sun").tag(1)
                    Text("Mon").tag(2)
                    Text("Tue").tag(3)
                    Text("Wed").tag(4)
                    Text("Thu").tag(5)
                    Text("Fri").tag(6)
                    Text("Sat").tag(7)
                }
            }

            Section("Behavior") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
            }

            Section("Updates") {
                updateRow
            }
        }
        .formStyle(.grouped)
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
}
