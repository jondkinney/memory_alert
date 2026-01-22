import Foundation
import AppKit

/// Service for listing running GUI applications
/// Uses NSRunningApplication with .regular activation policy
/// to match the Force Quit menu (unique by bundle ID)
enum ProcessLister {

    /// Get all running GUI applications (same as Force Quit menu)
    static func getRunningGUIApps() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
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
            .filter { $0.activationPolicy == .regular }
            .first { $0.localizedName == name }
    }
}
