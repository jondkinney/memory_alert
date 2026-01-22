import SwiftUI
import UserNotifications

@main
struct MemoryAlertApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var processMonitor = ProcessMonitor()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(processMonitor)
                .frame(width: 350, height: 450)
        } label: {
            Label(
                "Memory Alert",
                systemImage: processMonitor.hasWarning ? "exclamationmark.triangle.fill" : "memorychip"
            )
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        requestNotificationPermission()
    }

    private func setupNotificationCategories() {
        // Create category for memory alerts
        let memoryAlertCategory = UNNotificationCategory(
            identifier: "MEMORY_ALERT",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([memoryAlertCategory])
    }

    private func requestNotificationPermission() {
        // Request with criticalAlert for high-priority memory warnings
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .criticalAlert]
        ) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }

    // Show notifications even when app is in foreground - use list style for alerts
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.list, .banner, .sound])
    }
}
