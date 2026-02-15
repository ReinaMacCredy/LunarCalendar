import Observation
import SwiftUI

struct AppSettingsView: View {
    @Bindable var model: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lunar Calendar Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Tune calendar display, menu bar style, and data sources.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Menu Bar Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(model.menuBarTitle)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                SettingsContentView(model: model, compact: false)

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 680, minHeight: 620)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor).opacity(0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .task {
            await model.bootstrapIfNeeded()
        }
    }
}
