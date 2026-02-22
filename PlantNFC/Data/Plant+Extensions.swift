import Foundation
import SwiftUI

extension PlantEntity {

    // MARK: - Safe accessors
    var wrappedName: String       { name ?? "Onbekende plant" }
    var wrappedEmoji: String      { emoji ?? "🌿" }
    var wrappedNfcID: String?     { nfcID }
    var isLinkedToNFC: Bool       { nfcID != nil && !(nfcID!.isEmpty) }

    // MARK: - Time calculations
    var nextWaterDate: Date? {
        guard let last = lastWatered else { return nil }
        return last.addingTimeInterval(waterIntervalHours * 3600)
    }

    var hoursUntilWater: Double {
        guard let next = nextWaterDate else { return 0 }
        return next.timeIntervalSinceNow / 3600
    }

    var waterStatus: WaterStatus {
        guard lastWatered != nil else { return .overdue }
        let h = hoursUntilWater
        if h < 0 { return .overdue }
        let fraction = h / waterIntervalHours
        return fraction > 0.30 ? .ok : .soon
    }

    var urgencyScore: Double {
        switch waterStatus {
        case .overdue: return -hoursUntilWater + 10000
        case .soon:    return -hoursUntilWater + 100
        case .ok:      return hoursUntilWater
        }
    }

    // MARK: - Countdown string
    var countdownText: String {
        guard lastWatered != nil else { return "Nog nooit gescand" }
        let h = hoursUntilWater
        if h <= 0 {
            let overdue = -h
            if overdue < 1 { return "Water nodig nu!" }
            if overdue < 24 { return "\(Int(overdue))u te laat" }
            let days = Int(overdue / 24)
            return "\(days)d te laat"
        }
        if h < 1 { return "< 1 uur" }
        if h < 24 { return "Over \(Int(h))u \(Int((h.truncatingRemainder(dividingBy: 1)) * 60))m" }
        let days = Int(h / 24)
        let remH = Int(h.truncatingRemainder(dividingBy: 24))
        return remH > 0 ? "Over \(days)d \(remH)u" : "Over \(days) dag\(days == 1 ? "" : "en")"
    }

    // MARK: - Last watered display
    var lastWateredText: String {
        guard let date = lastWatered else { return "Nooit gescand" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var lastWateredFullText: String {
        guard let date = lastWatered else { return "Nog nooit water gegeven" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Interval display
    var intervalDisplayText: String {
        let h = waterIntervalHours
        if h < 24 { return h == 1 ? "Elk uur" : "Elke \(Int(h)) uur" }
        let d = Int(h / 24)
        return d == 1 ? "Elke dag" : "Elke \(d) dagen"
    }
}
