import Observation
import SwiftUI

struct SettingsSectionView: View {
    @Bindable var model: AppState

    var body: some View {
        DisclosureGroup(isExpanded: $model.showSettings) {
            CompactSettingsView(model: model)
        } label: {
            Label("Settings", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
    }
}
