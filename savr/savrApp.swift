import SwiftUI
import ServiceManagement

@main
struct SavrApp: App {
    @State private var manager: CaffeineManager

    init() {
        let key = "savr.didFirstLaunchSetup"
        if !UserDefaults.standard.bool(forKey: key) {
            try? SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: key)
        }
        _manager = State(initialValue: CaffeineManager())
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(manager)
        } label: {
            Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }

        Settings {
            SettingsView()
                .environment(manager)
        }
    }
}
