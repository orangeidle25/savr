import Foundation
import KeyboardShortcuts

struct Preset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var duration: TimeInterval

    static let maxCount = 10

    static let defaults: [Preset] = [
        Preset(name: "1 minute", duration: 60),
        Preset(name: "2 minutes", duration: 2 * 60),
        Preset(name: "5 minutes", duration: 5 * 60),
        Preset(name: "10 minutes", duration: 10 * 60),
        Preset(name: "20 minutes", duration: 20 * 60),
        Preset(name: "30 minutes", duration: 30 * 60),
        Preset(name: "1 hour", duration: 60 * 60),
        Preset(name: "2 hours", duration: 2 * 60 * 60),
        Preset(name: "3 hours", duration: 3 * 60 * 60)
    ]
}

extension KeyboardShortcuts.Name {
    static let toggleIndefinite = Self("savr.toggle.indefinite")
    static let startScreensaver = Self("savr.start.screensaver")

    static func preset(_ id: UUID) -> Self {
        Self("savr.preset.\(id.uuidString)")
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    if seconds == 0 { return "Indefinite" }
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    if hours == 0 { return "\(minutes)m" }
    if minutes == 0 { return "\(hours)h" }
    return "\(hours)h \(minutes)m"
}

func autoPresetName(for seconds: TimeInterval) -> String {
    if seconds == 0 { return "Indefinite" }
    let total = Int(seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours == 0 {
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
    if minutes == 0 {
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
    return "\(hours)h \(minutes)m"
}
