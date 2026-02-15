import Observation
import SwiftUI

struct SettingsSectionView: View {
    @Bindable var model: AppState

    var body: some View {
        DisclosureGroup(isExpanded: $model.showSettings) {
            SettingsContentView(model: model, compact: true)
        } label: {
            Label("Settings", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
    }
}
