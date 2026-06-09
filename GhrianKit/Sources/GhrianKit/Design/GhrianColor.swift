#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The ghrian palette. Two kinds of token:
///
/// - **Accents** (`pv`/`grid`/`battery`/`load`/…) are fixed brand colors that read on
///   both light and dark — they tint content the same everywhere.
/// - **Structural** tokens (`background`/`card`/`cardBorder`/text) are **adaptive**: they
///   map to platform system colors so the flat *content layer* follows the system
///   appearance. The floating Liquid Glass control layer comes from `.glassEffect` and
///   the standard components, not from a fill here.
public enum GhrianColor {
    // MARK: Fixed accents (mirror the web Tailwind palette)

    public static let pv = Color(hex: 0xEAB308)          // yellow-500 — solar
    public static let grid = Color(hex: 0x38BDF8)        // sky-400 — grid
    public static let battery = Color(hex: 0x22C55E)     // green-500 — storage
    public static let load = Color(hex: 0xA855F7)        // purple-500 — consumption
    public static let inverter = Color(hex: 0xF59E0B)    // amber-500 — hub
    public static let importColor = Color(hex: 0xF87171) // red-400 — import cost

    public static let online = Color(hex: 0x22C55E)
    public static let offline = Color(hex: 0xF87171)

    // MARK: Adaptive structural tokens (the content layer, follows light/dark)

    public static var background: Color { platformGroupedBackground }
    public static var card: Color { platformSecondaryGroupedBackground }
    public static var cardBorder: Color { platformSeparator }
    public static var textPrimary: Color { .primary }
    public static var textSecondary: Color { .secondary }

    /// Color for a flow node by its key ("pv"/"grid"/"battery"/"load").
    public static func flow(_ key: String) -> Color {
        switch key {
        case "pv": pv
        case "grid": grid
        case "battery": battery
        case "load": load
        default: inverter
        }
    }

    public static func status(_ status: InverterStatus) -> Color {
        switch status {
        case .online: online
        case .offline: offline
        case .unknown: textSecondary
        }
    }

    // MARK: Platform system colors

    private static var platformGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    private static var platformSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.2)
        #endif
    }

    private static var platformSeparator: Color {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        Color.gray.opacity(0.3)
        #endif
    }
}

public extension Color {
    /// 0xRRGGBB literal.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
#endif
