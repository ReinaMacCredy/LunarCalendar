import SwiftUI

@main
struct LunarCalendarMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let appState = AppContainer.sharedState

    var body: some Scene {
        Settings {
            AppSettingsView(model: appState)
        }
    }
}
