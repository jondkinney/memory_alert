import Foundation
import UserNotifications
import AudioToolbox
import AppKit

/// Manages notifications and sound alerts for memory threshold breaches
class AlertManager {
    static let shared = AlertManager()

    private var soundAlertsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "soundAlertsEnabled")
    }

    private init() {
        // Set default value if not already set
        if UserDefaults.standard.object(forKey: "soundAlertsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundAlertsEnabled")
        }
    }

    /// Send a memory alert notification
    func sendMemoryAlert(processName: String, currentMemoryGB: Double, thresholdGB: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Memory Alert"
        content.body = "\(processName) is using \(String(format: "%.1f", currentMemoryGB)) GB (over \(thresholdGB) GB threshold)"
        content.sound = soundAlertsEnabled ? .default : nil
        content.categoryIdentifier = "MEMORY_ALERT"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }

        // Play alert sound separately if enabled (in case notification sound is muted)
        if soundAlertsEnabled {
            playAlertSound()
        }
    }

    /// Play the system alert sound
    private func playAlertSound() {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert)
    }
}
