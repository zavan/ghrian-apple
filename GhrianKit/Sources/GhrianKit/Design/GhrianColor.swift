#if canImport(SwiftUI)
import SwiftUI

/// Semantic colors mirroring the web frontend's Tailwind palette (dark theme).
public enum GhrianColor {
    public static let pv = Color(hex: 0xEAB308)        // yellow-500 — solar
    public static let grid = Color(hex: 0x38BDF8)      // sky-400 — grid
    public static let battery = Color(hex: 0x22C55E)   // green-500 — storage
    public static let load = Color(hex: 0xA855F7)      // purple-500 — consumption
    public static let inverter = Color(hex: 0xF59E0B)  // amber-500 — hub
    public static let importColor = Color(hex: 0xF87171) // red-400 — import cost

    public static let background = Color(hex: 0x0F172A)   // slate-900
    public static let card = Color(hex: 0x1E293B)         // slate-800
    public static let cardBorder = Color(hex: 0x334155)   // slate-700
    public static let textPrimary = Color(hex: 0xF1F5F9)  // slate-100
    public static let textSecondary = Color(hex: 0x94A3B8) // slate-400

    public static let online = Color(hex: 0x22C55E)
    public static let offline = Color(hex: 0xF87171)

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
