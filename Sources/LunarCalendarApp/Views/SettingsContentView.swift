import Observation
import SwiftUI

struct CompactSettingsView: View {
    @Bindable var model: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Show Holidays", isOn: $model.settings.showHolidays)
            Toggle("Show Solar Terms", isOn: $model.settings.showSolarTerms)
            Toggle("Show Reminders", isOn: $model.settings.showReminders)

            Divider()

            HStack {
                Text("Menu Bar Style")
                Spacer()
                Picker("Style", selection: $model.settings.iconStyle) {
                    ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                        Text(style.title).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 130)
            }

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLogin($0) }
                )
            )

            SettingsLink {
                Label("All Settings…", systemImage: "slider.horizontal.3")
                    .font(.footnote)
            }
            .buttonStyle(.link)
        }
        .onChange(of: model.settings) { _, _ in
            model.settingsDidChange()
        }
    }
}
