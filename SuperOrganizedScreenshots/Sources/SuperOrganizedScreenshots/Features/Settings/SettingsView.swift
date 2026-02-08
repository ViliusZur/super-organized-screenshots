import SwiftUI
import HotKey

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            HotkeySettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject private var preferences = UserPreferences.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Toggle("Play sound after capture", isOn: $preferences.playCaptureSound)
                Toggle("Show notification after capture", isOn: $preferences.showNotification)
            }

            Section {
                Picker("Image format", selection: $preferences.imageFormat) {
                    ForEach(ImageFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }

            Section {
                HStack {
                    Text("Screenshot folder:")
                    Spacer()
                    Button("Open in Finder") {
                        if let url = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?
                            .appendingPathComponent("Super Organized Screenshots") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Screen Recording Permission:")
                    Spacer()
                    if appState.hasScreenRecordingPermission {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Granted")
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Button("Open Settings") {
                            appState.requestPermissions()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HotkeySettingsView: View {
    @ObservedObject private var hotkeyManager = HotkeyManager.shared

    var body: some View {
        Form {
            Section("Screenshot Mode Shortcut") {
                HStack {
                    Text("Activate Screenshot Mode:")
                    Spacer()
                    KeyRecorderView(keyCombo: $hotkeyManager.shortcut)
                        .frame(width: 120, height: 28)
                }

                HStack {
                    Spacer()
                    Button("Reset to Default") {
                        hotkeyManager.resetToDefault()
                    }
                    .controlSize(.small)
                }
            }

            Section {
                Text("Press the shortcut field above and type a new key combination to change it. The shortcut must include at least one modifier key (Cmd, Option, or Control).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("This shortcut opens screenshot mode where you can choose Rectangle or Full Screen capture.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
