import SwiftUI

enum CalendarTheme {
    // MARK: - Backgrounds

    static let warmWhite = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0x1E / 255, green: 0x1B / 255, blue: 0x18 / 255, alpha: 1)
            : NSColor(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF5 / 255, alpha: 1)
    }))

    static let warmSurface = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0x2A / 255, green: 0x26 / 255, blue: 0x22 / 255, alpha: 1)
            : NSColor(red: 0xF3 / 255, green: 0xEF / 255, blue: 0xE9 / 255, alpha: 1)
    }))

    static let warmBorder = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0x3D / 255, green: 0x37 / 255, blue: 0x2F / 255, alpha: 1)
            : NSColor(red: 0xE8 / 255, green: 0xE2 / 255, blue: 0xD9 / 255, alpha: 1)
    }))

    // MARK: - Text

    static let textPrimary = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0xED / 255, green: 0xE8 / 255, blue: 0xE2 / 255, alpha: 1)
            : NSColor(red: 0x2C / 255, green: 0x25 / 255, blue: 0x20 / 255, alpha: 1)
    }))

    static let textSecondary = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0x9A / 255, green: 0x90 / 255, blue: 0x88 / 255, alpha: 1)
            : NSColor(red: 0x8A / 255, green: 0x7E / 255, blue: 0x73 / 255, alpha: 1)
    }))

    static let textTertiary = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0x5A / 255, green: 0x52 / 255, blue: 0x49 / 255, alpha: 1)
            : NSColor(red: 0xB5 / 255, green: 0xAC / 255, blue: 0xA2 / 255, alpha: 1)
    }))

    // MARK: - Accent

    static let accentVermillion = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0xE0 / 255, green: 0x5A / 255, blue: 0x3A / 255, alpha: 1)
            : NSColor(red: 0xC8 / 255, green: 0x4B / 255, blue: 0x31 / 255, alpha: 1)
    }))

    static let accentVermillionSoft = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0xE0 / 255, green: 0x5A / 255, blue: 0x3A / 255, alpha: 0.15)
            : NSColor(red: 0xC8 / 255, green: 0x4B / 255, blue: 0x31 / 255, alpha: 0.12)
    }))

    // MARK: - Festival

    static let festivalGold = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0xDA / 255, green: 0xA5 / 255, blue: 0x20 / 255, alpha: 1)
            : NSColor(red: 0xB8 / 255, green: 0x86 / 255, blue: 0x0B / 255, alpha: 1)
    }))

    static let festivalGlow = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0xDA / 255, green: 0xA5 / 255, blue: 0x20 / 255, alpha: 0.10)
            : NSColor(red: 0xB8 / 255, green: 0x86 / 255, blue: 0x0B / 255, alpha: 0.08)
    }))

    // MARK: - Markers

    static let agendaDot = Color(red: 0x5B / 255, green: 0x8C / 255, blue: 0x5A / 255)
    static let holidayDot = Color(red: 0xC8 / 255, green: 0x4B / 255, blue: 0x31 / 255)
}
