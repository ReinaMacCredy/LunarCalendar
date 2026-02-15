import Foundation

enum L10n {
    private static let languageDefaultsKey = "lunar_calendar_app_language"

    static var appLanguage: AppLanguage {
        guard
            let rawValue = UserDefaults.standard.string(forKey: languageDefaultsKey),
            let appLanguage = AppLanguage(rawValue: rawValue)
        else {
            return .vietnamese
        }
        return appLanguage
    }

    static var locale: Locale {
        appLanguage.locale
    }

    static var baseBundle: Bundle {
        #if SWIFT_PACKAGE
        .module
        #else
        .main
        #endif
    }

    static func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageDefaultsKey)
    }

    static func tr(_ key: String, locale: Locale? = nil, fallback: String? = nil) -> String {
        let selectedLocale = locale ?? self.locale
        let localizedBundle = bundle(for: selectedLocale)
        return NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: localizedBundle,
            value: fallback ?? key,
            comment: ""
        )
    }

    private static func bundle(for locale: Locale) -> Bundle {
        for identifier in localizationIdentifiers(for: locale) {
            if let path = baseBundle.path(forResource: identifier, ofType: "lproj"),
               let localizedBundle = Bundle(path: path)
            {
                return localizedBundle
            }
        }
        return baseBundle
    }

    private static func localizationIdentifiers(for locale: Locale) -> [String] {
        let normalizedIdentifier = locale.identifier.replacingOccurrences(of: "_", with: "-")
        let languageCode = locale.language.languageCode?.identifier.lowercased() ?? normalizedIdentifier
        var identifiers: [String] = [normalizedIdentifier]

        if normalizedIdentifier != languageCode {
            identifiers.append(languageCode)
        }

        if languageCode == "zh" {
            identifiers.append("zh-Hans")
            identifiers.append("zh")
        }

        var unique: [String] = []
        unique.reserveCapacity(identifiers.count)
        for identifier in identifiers where !unique.contains(identifier) {
            unique.append(identifier)
        }
        return unique
    }
}
