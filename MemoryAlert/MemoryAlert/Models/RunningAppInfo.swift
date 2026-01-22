import Foundation
import AppKit

/// Information about a running GUI application
struct RunningAppInfo: Identifiable {
    let id: String  // Bundle identifier or PID string
    let pid: pid_t
    let bundleIdentifier: String?
    let localizedName: String
    let icon: NSImage?

    init(from app: NSRunningApplication) {
        self.pid = app.processIdentifier
        self.bundleIdentifier = app.bundleIdentifier
        self.localizedName = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
        self.icon = app.icon
        self.id = app.bundleIdentifier ?? String(app.processIdentifier)
    }
}
