import SwiftUI

struct MenuView: View {
    @Environment(CaffeineManager.self) private var manager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        statusView
        Divider()
        ForEach(manager.presets) { preset in
            Button(preset.name) {
                manager.toggle(preset)
            }
        }
        if manager.isActive {
            Divider()
            Button("Stop") {
                manager.deactivate()
            }
        }
        Divider()
        Button("Start Screensaver") {
            manager.startScreensaver()
        }
        Divider()
        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        Button("Quit savr") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    @ViewBuilder
    private var statusView: some View {
        if manager.isActive {
            if let endsAt = manager.endsAt {
                Text("Active until \(endsAt, format: .dateTime.hour().minute())")
            } else {
                Text("Active · Indefinite")
            }
        } else {
            Text("Idle")
        }
    }
}
