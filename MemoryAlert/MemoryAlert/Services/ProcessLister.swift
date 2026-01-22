import Foundation
import AppKit

/// Service for listing running GUI applications
/// Uses NSRunningApplication with .regular and .accessory activation policies
/// to include both standard apps and menu bar apps (LSUIElement)
enum ProcessLister {

    /// Get all running GUI applications (standard apps + menu bar apps)
    static func getRunningGUIApps() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .filter { $0.bundleIdentifier != nil } // Must have bundle ID for reliable tracking
            .map { RunningAppInfo(from: $0) }
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    /// Find a running app by bundle identifier
    static func findApp(bundleIdentifier: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleIdentifier }
    }

    /// Find a running app by name (fallback if bundle ID not available)
    static func findApp(name: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .first { $0.localizedName == name }
    }
}
