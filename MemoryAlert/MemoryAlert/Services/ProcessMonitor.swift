import Foundation
import Combine
import AppKit

/// Error types for process monitoring
enum ProcessMonitorError: Error, LocalizedError {
    case processNotFound(name: String)
    case permissionDenied(name: String)
    case readFailed(errno: Int32)

    var errorDescription: String? {
        switch self {
        case .processNotFound(let name):
            return "\(name) is not running"
        case .permissionDenied(let name):
            return "Cannot read memory for \(name) - permission denied"
        case .readFailed(let errno):
            return "Failed to read process memory (error \(errno))"
        }
    }
}

/// Main service for monitoring process memory usage
@MainActor
class ProcessMonitor: ObservableObject {
    @Published var monitoredProcesses: [MonitoredProcess] = []
    @Published var hasWarning: Bool = false

    private var timer: AnyCancellable?
    private let pollingInterval: TimeInterval = 5.0

    private let persistenceKey = "monitoredProcesses"

    init() {
        loadPersistedProcesses()
        startMonitoring()
    }

    deinit {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Public API

    func addProcess(_ process: MonitoredProcess) {
        guard !monitoredProcesses.contains(where: { $0.id == process.id }) else { return }
        monitoredProcesses.append(process)
        saveProcesses()
        updateMemoryForProcess(at: monitoredProcesses.count - 1)
    }

    func removeProcess(_ process: MonitoredProcess) {
        monitoredProcesses.removeAll { $0.id == process.id }
        saveProcesses()
        updateWarningState()
    }

    func updateThresholds(for process: MonitoredProcess, thresholdsMB: [Int]) {
        guard let index = monitoredProcesses.firstIndex(where: { $0.id == process.id }) else { return }
        monitoredProcesses[index].thresholdsMB = thresholdsMB
        monitoredProcesses[index].notifiedThresholds = []  // Reset notifications for new thresholds
        saveProcesses()
        updateWarningState()
    }

    // MARK: - Monitoring Loop

    private func startMonitoring() {
        timer = Timer.publish(every: pollingInterval, tolerance: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.pollAllProcesses()
                }
            }
    }

    private func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }

    private func pollAllProcesses() {
        for index in monitoredProcesses.indices {
            updateMemoryForProcess(at: index)
        }
        updateWarningState()
    }

    private func updateMemoryForProcess(at index: Int) {
        guard index < monitoredProcesses.count else { return }

        var process = monitoredProcesses[index]

        // Try to find the running app
        let runningApp: NSRunningApplication?
        if let bundleId = process.bundleIdentifier {
            runningApp = ProcessLister.findApp(bundleIdentifier: bundleId)
        } else {
            runningApp = ProcessLister.findApp(name: process.processName)
        }

        if let app = runningApp {
            // Process is running
            process.currentPID = app.processIdentifier
            process.isRunning = true
            process.icon = app.icon

            // Read memory
            do {
                let memoryBytes = try readProcessMemory(pid: app.processIdentifier)
                let previousMemory = process.currentMemoryBytes
                process.currentMemoryBytes = memoryBytes

                // Check for threshold breaches
                checkThresholds(for: &process, previousMemory: previousMemory)
            } catch {
                // Memory read failed but process exists
                print("Failed to read memory for \(process.processName): \(error)")
            }
        } else {
            // Process not running
            process.currentPID = nil
            process.isRunning = false
            process.currentMemoryBytes = 0
            process.notifiedThresholds = []  // Reset notifications when process stops
        }

        monitoredProcesses[index] = process
    }

    private func checkThresholds(for process: inout MonitoredProcess, previousMemory: UInt64) {
        let memoryMB = Double(process.currentMemoryBytes) / 1_048_576
        let previousMB = Double(previousMemory) / 1_048_576

        for thresholdMB in process.thresholdsMB {
            let thresholdDouble = Double(thresholdMB)

            if memoryMB >= thresholdDouble {
                // Currently over threshold
                if !process.notifiedThresholds.contains(thresholdMB) {
                    // First time exceeding this threshold - alert!
                    process.notifiedThresholds.insert(thresholdMB)
                    AlertManager.shared.sendMemoryAlert(
                        processName: process.processName,
                        currentMemoryMB: memoryMB,
                        thresholdMB: thresholdMB
                    )
                }
            } else if previousMB >= thresholdDouble && memoryMB < thresholdDouble {
                // Memory dropped below threshold - reset notification state
                process.notifiedThresholds.remove(thresholdMB)
            }
        }
    }

    private func updateWarningState() {
        hasWarning = monitoredProcesses.contains { !$0.breachedThresholds.isEmpty }
    }

    // MARK: - Memory Reading

    private func readProcessMemory(pid: pid_t) throws -> UInt64 {
        var info = rusage_info_v4()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
            }
        }

        guard result == 0 else {
            let err = errno
            switch err {
            case ESRCH:
                throw ProcessMonitorError.processNotFound(name: "PID \(pid)")
            case EPERM:
                throw ProcessMonitorError.permissionDenied(name: "PID \(pid)")
            default:
                throw ProcessMonitorError.readFailed(errno: err)
            }
        }

        return info.ri_phys_footprint
    }

    // MARK: - Persistence

    private func loadPersistedProcesses() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let processes = try? JSONDecoder().decode([MonitoredProcess].self, from: data) else {
            return
        }
        monitoredProcesses = processes
    }

    private func saveProcesses() {
        guard let data = try? JSONEncoder().encode(monitoredProcesses) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }
}
