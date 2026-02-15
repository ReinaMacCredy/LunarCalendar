import Foundation

actor SettingsStore {
    private let key = "lunar_calendar_user_settings"
    private let legacyCustomFormatMigrationKey = "lunar_calendar_custom_icon_format_migration_v1_done"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    init(suiteName: String) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    func load() -> UserSettings {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(UserSettings.self, from: data)
        else {
            return UserSettings()
        }

        return decoded
    }

    func save(_ settings: UserSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    func isLegacyCustomFormatMigrationDone() -> Bool {
        defaults.bool(forKey: legacyCustomFormatMigrationKey)
    }

    func markLegacyCustomFormatMigrationDone() {
        defaults.set(true, forKey: legacyCustomFormatMigrationKey)
    }
}
