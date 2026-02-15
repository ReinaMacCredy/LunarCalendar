import SwiftUI

struct GeneralSettingsTab: View {
    @Bindable var model: AppState

    var body: some View {
        Form {
            Section("Calendar Display") {
                Picker("Language", selection: $model.settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.title).tag(language)
                    }
                }
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
                Toggle("Auto Check for Updates", isOn: $model.settings.autoCheckForUpdates)
                Toggle("Auto Download Updates", isOn: $model.settings.autoDownloadUpdates)

                updateRow
            }
        }
        .formStyle(.grouped)
    }

    private var updateRow: some View {
        HStack {
            switch model.updateStatus {
            case .idle:
                Text("No recent update check")
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
                Text(
                    String(
                        format: L10n.tr("Up to date (v%@)", locale: model.appLocale, fallback: "Up to date (v%@)"),
                        locale: model.appLocale,
                        version
                    )
                )
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Check Again") {
                    model.checkForUpdates()
                }
                .controlSize(.small)

            case .available(let release):
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text(
                    String(
                        format: L10n.tr("v%@ available", locale: model.appLocale, fallback: "v%@ available"),
                        locale: model.appLocale,
                        release.latestVersion
                    )
                )
                Spacer()
                if release.asset != nil {
                    Button(L10n.tr("Download and Relaunch", fallback: "Download and Relaunch")) {
                        model.downloadAndRelaunchAvailableUpdate()
                    }
                    .controlSize(.small)
                }
                Button(L10n.tr("Check Update", fallback: "Check Update")) {
                    model.checkForUpdates()
                }
                .controlSize(.small)
                Button("View Release") {
                    model.openLatestRelease()
                }
                .controlSize(.small)

            case .downloading(let latestVersion):
                ProgressView()
                    .controlSize(.small)
                Text(
                    String(
                        format: L10n.tr("Downloading v%@…", locale: model.appLocale, fallback: "Downloading v%@…"),
                        locale: model.appLocale,
                        latestVersion
                    )
                )
                    .foregroundStyle(.secondary)
                Spacer()

            case .downloaded(let downloaded):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(
                    String(
                        format: L10n.tr("Downloaded v%@", locale: model.appLocale, fallback: "Downloaded v%@"),
                        locale: model.appLocale,
                        downloaded.latestVersion
                    )
                )
                    .foregroundStyle(.secondary)
                Spacer()
                if downloaded.extractedAppURL != nil {
                    Button("Relaunch") {
                        model.relaunchFromDownloadedUpdate()
                    }
                    .controlSize(.small)
                } else {
                    Button("Open Installer") {
                        model.openDownloadedInstaller()
                    }
                    .controlSize(.small)
                }
                Button(L10n.tr("Check Update", fallback: "Check Update")) {
                    model.checkForUpdates()
                }
                .controlSize(.small)
            case .installing(let latestVersion):
                ProgressView()
                    .controlSize(.small)
                Text(
                    String(
                        format: L10n.tr("Relaunching v%@…", locale: model.appLocale, fallback: "Relaunching v%@…"),
                        locale: model.appLocale,
                        latestVersion
                    )
                )
                    .foregroundStyle(.secondary)
                Spacer()

            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Button("Retry") {
                    model.checkForUpdates()
                }
                .controlSize(.small)
            }
        }
        .font(.footnote)
    }
}
