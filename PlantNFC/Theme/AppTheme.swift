import SwiftUI

// MARK: - Color Palette
extension Color {
    static let plantGreen      = Color(red: 0.22, green: 0.65, blue: 0.38)
    static let plantGreenDark  = Color(red: 0.13, green: 0.45, blue: 0.26)
    static let plantGreenLight = Color(red: 0.72, green: 0.92, blue: 0.76)
    static let plantAmber      = Color(red: 0.95, green: 0.65, blue: 0.15)
    static let plantRed        = Color(red: 0.90, green: 0.28, blue: 0.28)
    static let plantBg         = Color(.systemGroupedBackground)
    static let plantCard       = Color(.secondarySystemGroupedBackground)
    static let plantSurface    = Color(.tertiarySystemGroupedBackground)
}

// MARK: - Water Status
enum WaterStatus {
    case ok       // > 30% time remaining
    case soon     // 0–30% time remaining
    case overdue  // past due

    var color: Color {
        switch self {
        case .ok:      return .plantGreen
        case .soon:    return .plantAmber
        case .overdue: return .plantRed
        }
    }

    var emoji: String {
        switch self {
        case .ok:      return "🟢"
        case .soon:    return "🟠"
        case .overdue: return "🔴"
        }
    }

    var label: String {
        switch self {
        case .ok:      return "Genoeg water"
        case .soon:    return "Binnenkort water"
        case .overdue: return "Water nodig!"
        }
    }
}

// MARK: - Water Interval Presets
enum WaterIntervalPreset: String, CaseIterable, Identifiable {
    case everyDay       = "Elke dag"
    case everyTwoDays   = "Elke 2 dagen"
    case everyWeek      = "Elke week"
    case everyHour      = "Elk uur"
    case custom         = "Aangepast"

    var id: String { rawValue }

    var hours: Double? {
        switch self {
        case .everyHour:     return 1
        case .everyDay:      return 24
        case .everyTwoDays:  return 48
        case .everyWeek:     return 168
        case .custom:        return nil
        }
    }
}

// MARK: - Plant Emojis
let plantEmojis = ["🌿", "🪴", "🌵", "🌸", "🌺", "🌻", "🌹", "🌱", "🍀", "🎋", "🎍", "🌾", "🍃", "🍂", "🌳", "🌲"]

// MARK: - Helper Extensions
extension View {
    func plantCard() -> some View {
        self
            .background(Color.plantCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
