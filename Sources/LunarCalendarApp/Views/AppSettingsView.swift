import Observation
import SwiftUI

struct AppSettingsView: View {
    @Bindable var model: AppState

    var body: some View {
        TabView {
            GeneralSettingsTab(model: model)
                .tabItem {
                    Label("General", systemImage: "calendar")
                }

            MenuBarSettingsTab(model: model)
                .tabItem {
                    Label("Menu Bar", systemImage: "menubar.rectangle")
                }

            SourcesSettingsTab(model: model)
                .tabItem {
                    Label("Sources", systemImage: "checklist")
                }
        }
        .frame(minWidth: 520, minHeight: 420)
        .onChange(of: model.settings) { _, _ in
            model.settingsDidChange()
        }
        .task {
            await model.bootstrapIfNeeded()
        }
        .environment(\.locale, model.appLocale)
        .overlay(alignment: .bottom) {
            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
            }
        }
    }
}
