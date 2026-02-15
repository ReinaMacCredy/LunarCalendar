import SwiftUI

struct MenuBarSettingsTab: View {
    @Bindable var model: AppState

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Text(model.menuBarTitle)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                }
            } header: {
                Text("Menu Bar Preview")
            }

            Section("Appearance") {
                Picker("Style", selection: $model.settings.iconStyle) {
                    ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                        Text(style.title).tag(style)
                    }
                }

                if model.settings.iconStyle == .customFormat {
                    TextField("Custom format (DateFormatter)", text: $model.settings.customIconFormat)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .formStyle(.grouped)
    }
}
