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
    func sendMemoryAlert(processName: String, currentMemoryMB: Double, thresholdMB: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Memory Alert"

        // Format current memory
        let currentFormatted: String
        if currentMemoryMB >= 1024 {
            currentFormatted = String(format: "%.1f GB", currentMemoryMB / 1024)
        } else {
            currentFormatted = String(format: "%.0f MB", currentMemoryMB)
        }

        // Format threshold
        let thresholdFormatted = MonitoredProcess.formatThreshold(thresholdMB)

        content.body = "\(processName) is using \(currentFormatted) (over \(thresholdFormatted) threshold)"
        content.sound = soundAlertsEnabled ? .default : nil
        content.categoryIdentifier = "MEMORY_ALERT"
        content.interruptionLevel = .timeSensitive

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
