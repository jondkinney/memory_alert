import Foundation
import AppKit

struct MonitoredProcess: Identifiable, Codable {
    let id: UUID
    var processName: String
    var bundleIdentifier: String?
    var currentPID: pid_t?
    var thresholdsMB: [Int]  // MB values, e.g., [5120, 10240, 15360] for 5GB, 10GB, 15GB
    var currentMemoryBytes: UInt64 = 0
    var isRunning: Bool = true

    // Not persisted - runtime state
    var notifiedThresholds: Set<Int> = []
    var icon: NSImage?

    // Computed property for breached thresholds (returns MB values)
    var breachedThresholds: [Int] {
        let memoryMB = Double(currentMemoryBytes) / 1_048_576  // bytes to MB
        return thresholdsMB.filter { Double($0) < memoryMB }
    }

    // Helper to format threshold for display
    static func formatThreshold(_ mb: Int) -> String {
        if mb >= 1024 && mb % 1024 == 0 {
            return "\(mb / 1024) GB"
        } else if mb >= 1024 {
            let gb = Double(mb) / 1024.0
            return String(format: "%.1f GB", gb)
        } else {
            return "\(mb) MB"
        }
    }

    // Helper to parse threshold input (e.g., "500MB", "5GB", "5")
    static func parseThreshold(_ input: String) -> Int? {
        let trimmed = input.trimmingCharacters(in: .whitespaces).uppercased()

        if trimmed.hasSuffix("MB") {
            let numStr = trimmed.dropLast(2).trimmingCharacters(in: .whitespaces)
            guard let value = Int(numStr), value > 0 else { return nil }
            return value
        } else if trimmed.hasSuffix("GB") {
            let numStr = trimmed.dropLast(2).trimmingCharacters(in: .whitespaces)
            guard let value = Int(numStr), value > 0 else { return nil }
            return value * 1024
        } else if let value = Int(trimmed), value > 0 {
            // Bare number - assume GB for backwards compatibility
            return value * 1024
        }
        return nil
    }

    init(
        id: UUID = UUID(),
        processName: String,
        bundleIdentifier: String? = nil,
        currentPID: pid_t? = nil,
        thresholdsMB: [Int] = [5120, 10240, 15360],  // Default: 5GB, 10GB, 15GB in MB
        currentMemoryBytes: UInt64 = 0,
        isRunning: Bool = true,
        icon: NSImage? = nil
    ) {
        self.id = id
        self.processName = processName
        self.bundleIdentifier = bundleIdentifier
        self.currentPID = currentPID
        self.thresholdsMB = thresholdsMB
        self.currentMemoryBytes = currentMemoryBytes
        self.isRunning = isRunning
        self.icon = icon
    }

    // Custom Codable implementation to exclude runtime state
    enum CodingKeys: String, CodingKey {
        case id, processName, bundleIdentifier, thresholdsMB
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        processName = try container.decode(String.self, forKey: .processName)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        thresholdsMB = try container.decode([Int].self, forKey: .thresholdsMB)
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
        try container.encode(thresholdsMB, forKey: .thresholdsMB)
    }
}
