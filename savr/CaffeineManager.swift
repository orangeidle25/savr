import Foundation
import IOKit.pwr_mgt
import KeyboardShortcuts

@MainActor
@Observable
final class CaffeineManager {
    var isActive = false
    var endsAt: Date?
    var presets: [Preset] = [] {
        didSet {
            persist()
            syncShortcutHandlers()
        }
    }

    @ObservationIgnored private var assertionID: IOPMAssertionID = 0
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var registeredIDs: Set<UUID> = []
    @ObservationIgnored private let storageKey = "savr.presets.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Preset].self, from: data) {
            presets = decoded
        } else {
            presets = Preset.defaults
        }

        KeyboardShortcuts.onKeyDown(for: .toggleIndefinite) { [weak self] in
            Task { @MainActor in self?.toggleIndefinite() }
        }
        KeyboardShortcuts.onKeyDown(for: .startScreensaver) { [weak self] in
            Task { @MainActor in self?.startScreensaver() }
        }
        syncShortcutHandlers()
    }

    func activate(for duration: TimeInterval) {
        if isActive { deactivate() }
        let reason = "savr is holding the screensaver back" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        guard result == kIOReturnSuccess else { return }
        isActive = true

        if duration > 0 {
            endsAt = Date().addingTimeInterval(duration)
            scheduleTimer()
        } else {
            endsAt = nil
        }
    }

    func deactivate() {
        if isActive {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        timer?.invalidate()
        timer = nil
        endsAt = nil
        isActive = false
    }

    func toggle(_ preset: Preset) {
        isActive ? deactivate() : activate(for: preset.duration)
    }

    func toggleIndefinite() {
        isActive ? deactivate() : activate(for: 0)
    }

    func startScreensaver() {
        if isActive { deactivate() }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "ScreenSaverEngine"]
        try? task.run()
    }

    func addPreset() {
        guard presets.count < Preset.maxCount else { return }
        let defaultDuration: TimeInterval = 30 * 60
        presets.append(Preset(name: autoPresetName(for: defaultDuration), duration: defaultDuration))
    }

    func removePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        KeyboardShortcuts.reset(.preset(id))
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let endsAt = self.endsAt else { return }
                if Date() >= endsAt { self.deactivate() }
            }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func syncShortcutHandlers() {
        for preset in presets where !registeredIDs.contains(preset.id) {
            let id = preset.id
            KeyboardShortcuts.onKeyDown(for: .preset(id)) { [weak self] in
                Task { @MainActor in
                    guard let self, let p = self.presets.first(where: { $0.id == id }) else { return }
                    self.toggle(p)
                }
            }
            registeredIDs.insert(id)
        }
    }
}
