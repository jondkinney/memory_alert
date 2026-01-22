import SwiftUI
import ServiceManagement
import UserNotifications

struct SettingsView: View {
    @Binding var mode: ContentViewMode
    @AppStorage("soundAlertsEnabled") private var soundAlertsEnabled = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    mode = .main
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                // Alerts Section
                Section("Alerts") {
                    Toggle("Play sound on threshold breach", isOn: $soundAlertsEnabled)

                    HStack {
                        Text("Notifications")
                        Spacer()
                        notificationStatusView
                    }
                }

                // Startup Section
                Section("Startup") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            updateLaunchAtLogin(newValue)
                        }
                }

                // Info Section
                Section("About") {
                    HStack {
                        Text("Polling interval")
                        Spacer()
                        Text("5 seconds")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    @ViewBuilder
    private var notificationStatusView: some View {
        switch notificationStatus {
        case .authorized:
            Label("Enabled", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .denied:
            Button {
                openNotificationSettings()
            } label: {
                Label("Disabled - Enable", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        case .notDetermined:
            Button("Request Permission") {
                requestNotificationPermission()
            }
            .font(.caption)
        default:
            Text("Unknown")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                checkNotificationStatus()
            }
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
            NSWorkspace.shared.open(url)
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

#Preview {
    SettingsView(mode: .constant(.settings))
        .frame(width: 350, height: 450)
}
