import Foundation
import AppKit

struct MonitoredProcess: Identifiable, Codable {
    let id: UUID
    var processName: String
    var bundleIdentifier: String?
    var currentPID: pid_t?
    var thresholds: [Int]  // GB values, e.g., [5, 10, 15]
    var currentMemoryBytes: UInt64 = 0
    var isRunning: Bool = true

    // Not persisted - runtime state
    var notifiedThresholds: Set<Int> = []
    var icon: NSImage?

    // Computed property for breached thresholds
    var breachedThresholds: [Int] {
        let memoryGB = Double(currentMemoryBytes) / 1_073_741_824  // bytes to GB
        return thresholds.filter { Double($0) < memoryGB }
    }

    init(
        id: UUID = UUID(),
        processName: String,
        bundleIdentifier: String? = nil,
        currentPID: pid_t? = nil,
        thresholds: [Int] = [5, 10, 15],
        currentMemoryBytes: UInt64 = 0,
        isRunning: Bool = true,
        icon: NSImage? = nil
    ) {
        self.id = id
        self.processName = processName
        self.bundleIdentifier = bundleIdentifier
        self.currentPID = currentPID
        self.thresholds = thresholds
        self.currentMemoryBytes = currentMemoryBytes
        self.isRunning = isRunning
        self.icon = icon
    }

    // Custom Codable implementation to exclude runtime state
    enum CodingKeys: String, CodingKey {
        case id, processName, bundleIdentifier, thresholds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        processName = try container.decode(String.self, forKey: .processName)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        thresholds = try container.decode([Int].self, forKey: .thresholds)
        // Runtime state initialized to defaults
        currentPID = nil
        currentMemoryBytes = 0
        isRunning = false
        notifiedThresholds = []
        icon = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(processName, forKey: .processName)
        try container.encodeIfPresent(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(thresholds, forKey: .thresholds)
    }
}
