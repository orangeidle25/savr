import SwiftUI
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        TabView {
            PresetsTab()
                .tabItem { Label("Presets", systemImage: "list.bullet") }
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 400)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

private struct PresetsTab: View {
    @Environment(CaffeineManager.self) private var manager

    var body: some View {
        @Bindable var manager = manager
        VStack(spacing: 0) {
            List {
                ForEach($manager.presets) { $preset in
                    PresetRow(preset: $preset) {
                        manager.removePreset(id: preset.id)
                    }
                }
            }
            .listStyle(.inset)
            Divider()
            HStack(spacing: 8) {
                Button(action: manager.addPreset) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .disabled(manager.presets.count >= Preset.maxCount)
                Text("\(manager.presets.count) of \(Preset.maxCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(8)
        }
    }
}

private struct PresetRow: View {
    @Binding var preset: Preset
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Name", text: $preset.name)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 8) {
                    DurationField(seconds: $preset.duration)
                        .disabled(preset.duration == 0)
                        .opacity(preset.duration == 0 ? 0.4 : 1)
                    Toggle("Indefinite", isOn: Binding(
                        get: { preset.duration == 0 },
                        set: { preset.duration = $0 ? 0 : 30 * 60 }
                    ))
                    .controlSize(.small)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .preset(preset.id))
                }
            }
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

private struct DurationField: View {
    @Binding var seconds: TimeInterval

    var body: some View {
        HStack(spacing: 4) {
            TextField("", value: hours, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 44)
                .multilineTextAlignment(.trailing)
            Text("h").foregroundStyle(.secondary)
            TextField("", value: minutes, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 44)
                .multilineTextAlignment(.trailing)
            Text("m").foregroundStyle(.secondary)
        }
    }

    private var hours: Binding<Int> {
        Binding(
            get: { Int(seconds) / 3600 },
            set: { newHours in
                let m = (Int(seconds) % 3600) / 60
                seconds = TimeInterval(newHours * 3600 + m * 60)
            }
        )
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { (Int(seconds) % 3600) / 60 },
            set: { newMinutes in
                let h = Int(seconds) / 3600
                seconds = TimeInterval(h * 3600 + newMinutes * 60)
            }
        )
    }
}

private struct GeneralTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                if SMAppService.mainApp.status != .enabled {
                                    try SMAppService.mainApp.register()
                                }
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            Section("Global Shortcuts") {
                KeyboardShortcuts.Recorder("Toggle indefinite hold", name: .toggleIndefinite)
                KeyboardShortcuts.Recorder("Start screensaver now", name: .startScreensaver)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)
            Text("savr")
                .font(.title.weight(.semibold))
            VStack(spacing: 4) {
                Text("Developed by Jacob Bolduc")
                    .foregroundStyle(.secondary)
                Link("jacobbolduc.com", destination: URL(string: "https://jacobbolduc.com")!)
            }
            .font(.subheadline)
            Spacer()
            Text("© 2026 Jacob Bolduc")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
