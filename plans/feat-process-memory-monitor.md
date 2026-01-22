# ✨ feat: macOS Process Memory Monitor

A native macOS menu bar utility app that monitors process memory usage with configurable threshold alerts.

## Overview

Build a lightweight, native macOS menu bar application using Swift + SwiftUI that allows users to monitor memory usage of multiple processes simultaneously. When memory exceeds user-configured thresholds, the app sends notifications, plays optional sounds, and displays visual indicators in the menu bar.

## Problem Statement / Motivation

Developers and power users often need to monitor memory-hungry processes (browsers, IDEs, Electron apps) to prevent system slowdowns or identify memory leaks. Currently this requires:
- Manually checking Activity Monitor
- Running command-line tools periodically
- Using heavyweight third-party monitoring suites

A simple, native menu bar utility would provide passive monitoring with proactive alerts.

## Proposed Solution

### Core Features

1. **Menu Bar Presence**: Lives in the menu bar with minimal footprint, shows status at a glance
2. **Multi-Process Monitoring**: Monitor multiple processes simultaneously with independent thresholds
3. **Process Picker**: Dropdown list of running processes with search/filtering
4. **Configurable Thresholds**: Add multiple memory thresholds per process (e.g., 5GB, 10GB, 15GB)
5. **Alert System**: macOS notifications, optional sounds, visual menu bar indicator
6. **Persistence**: Settings survive app restarts

### User Interface

```
┌─────────────────────────────────────┐
│  Memory Monitor         [Settings]  │
├─────────────────────────────────────┤
│  + Add Process                      │
├─────────────────────────────────────┤
│  Monitored Processes:               │
│                                     │
│  🟢 Safari (PID 1234)               │
│     Memory: 2.1 GB                  │
│     Thresholds: 5GB, 10GB, 15GB     │
│                                     │
│  🔴 Chrome (PID 5678)               │
│     Memory: 12.4 GB  ⚠️ Over 10GB   │
│     Thresholds: 5GB, 10GB, 15GB     │
│                                     │
│  🟡 Code Helper (PID 9012)          │
│     Memory: 5.2 GB  ⚠️ Over 5GB     │
│     Thresholds: 5GB, 8GB            │
├─────────────────────────────────────┤
│  [Quit]                             │
└─────────────────────────────────────┘
```

## Technical Approach

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    SwiftUI Views Layer                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │
│  │ ContentView│  │ProcessPicker│  │ThresholdConfigView│  │
│  └──────┬─────┘  └──────┬─────┘  └─────────┬──────────┘  │
└─────────┼───────────────┼──────────────────┼─────────────┘
          │               │                  │
┌─────────▼───────────────▼──────────────────▼─────────────┐
│              ObservableObject Services                    │
│  ┌────────────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │ ProcessMonitor │  │ProcessLister│  │AlertManager   │  │
│  │ (polling loop) │  │(enumeration)│  │(notifications)│  │
│  └────────────────┘  └─────────────┘  └───────────────┘  │
└──────────────────────────────────────────────────────────┘
          │
┌─────────▼────────────────────────────────────────────────┐
│                    System APIs                            │
│  proc_pid_rusage()  proc_listallpids()  UNNotifications  │
└──────────────────────────────────────────────────────────┘
```

### Key Technologies

| Component | Technology | Notes |
|-----------|------------|-------|
| UI Framework | SwiftUI with MenuBarExtra | macOS 13.0+ required |
| Menu Bar | MenuBarExtra with `.window` style | Provides rich UI in dropdown |
| Memory API | `proc_pid_rusage()` → `ri_phys_footprint` | Matches Activity Monitor |
| Process List | `NSRunningApplication` with `.regular` activation policy | GUI apps only (same as Force Quit menu) - unique by bundle ID |
| Notifications | UserNotifications framework | Request permission on first launch |
| Sounds | AudioServicesPlayAlertSound | System sounds |
| Persistence | @AppStorage + Codable | UserDefaults-backed |
| Polling | Combine Timer.publish | Fixed 5-second interval |
| Distribution | Developer ID (non-sandboxed) | Mac App Store not supported (proc_pid_rusage requires sandbox exemption) |

### Minimum Requirements

- **macOS 13.0 (Ventura)** - Required for MenuBarExtra
- **Xcode 14+** - For SwiftUI development

## Implementation Phases

### Phase 1: Foundation

**Goal:** Basic app structure with menu bar presence

- [x] Create Xcode project (macOS App, SwiftUI lifecycle)
- [x] Configure as agent app (LSUIElement = YES, no Dock icon)
- [x] Implement MenuBarExtra with `.window` style
- [x] Add basic ContentView with placeholder UI
- [x] Add Quit button functionality
- [x] Test menu bar appearance and basic interaction

**Files:**
- `SoundSourceMonitorApp.swift` - App entry point with MenuBarExtra
- `ContentView.swift` - Main menu bar content view
- `Info.plist` - LSUIElement configuration

### Phase 2: Process Enumeration

**Goal:** Display list of running GUI applications (same as Force Quit menu)

- [x] Implement `ProcessLister` service using `NSRunningApplication`
- [x] Filter to `activationPolicy == .regular` (GUI apps with Dock presence)
- [x] Create `ProcessInfo` model (pid, bundleIdentifier, localizedName, icon)
- [x] Build `ProcessPickerView` with searchable list
- [x] Show app icon + localized name (no duplicates since each app has unique bundle ID)
- [x] Add search/filter functionality
- [x] Refresh process list on dropdown open

**Files:**
- `Services/ProcessLister.swift` - Process enumeration via NSRunningApplication
- `Models/ProcessInfo.swift` - Process data model
- `Views/ProcessPickerView.swift` - Process selection UI

**Note:** Using `NSRunningApplication` with `.regular` activation policy limits monitoring to GUI apps that appear in the Dock and Force Quit menu. This eliminates the "multiple node processes" ambiguity problem since each app has a unique bundle identifier.

### Phase 3: Memory Monitoring

**Goal:** Monitor memory usage of selected processes

- [x] Implement `ProcessMonitor` ObservableObject
- [x] Use `proc_pid_rusage()` for memory footprint
- [x] Create `MonitoredProcess` model with thresholds
- [x] Implement polling loop with Combine Timer
- [x] Display current memory usage in UI
- [x] Handle process termination gracefully
- [x] Auto-reattach when process restarts (by name)

**Files:**
- `Services/ProcessMonitor.swift` - Memory monitoring service
- `Models/MonitoredProcess.swift` - Monitored process with thresholds

### Phase 4: Threshold Configuration

**Goal:** Allow users to configure memory thresholds

- [x] Build `ThresholdConfigView` for adding/editing thresholds
- [x] Support thresholds in GB (e.g., 1, 2, 5, 10, 15, 20)
- [x] Validate threshold values (positive, non-duplicate)
- [x] Allow up to 5 thresholds per process
- [x] Default thresholds: 5GB, 10GB, 15GB
- [x] Store threshold configuration with process

**Files:**
- `Views/ThresholdConfigView.swift` - Threshold editing UI
- `Models/ThresholdConfig.swift` - Threshold data model

### Phase 5: Alert System

**Goal:** Notify users when thresholds are exceeded

- [x] Implement `AlertManager` service
- [x] Request notification permission on first launch
- [x] Send notification when threshold breached
- [x] Track notified thresholds (don't re-alert until cleared)
- [x] Clear notification state when memory drops below threshold
- [x] Add optional alert sound (using system sounds)
- [x] Add settings for sound on/off

**Files:**
- `Services/AlertManager.swift` - Notification handling
- `Views/SettingsView.swift` - Alert preferences

### Phase 6: Visual Indicators

**Goal:** Show breach status at a glance

- [x] Update menu bar icon based on state:
  - Normal: `memorychip` (SF Symbol)
  - Warning: `exclamationmark.triangle.fill`
- [x] Show badge or color change when thresholds breached
- [x] Highlight breached processes in list view
- [ ] Show breach count in menu bar (optional)

**Files:**
- Updates to `SoundSourceMonitorApp.swift` for dynamic icon

### Phase 7: Persistence & Settings

**Goal:** Save settings across app restarts

- [x] Implement Codable for `MonitoredProcess` and thresholds
- [x] Use @AppStorage for monitored processes list
- [x] Add settings view with:
  - Sound alerts toggle
  - Launch at Login toggle
- [x] Implement Launch at Login using SMAppService (macOS 13+)

**Note:** Polling interval is hardcoded at 5 seconds. This is a sensible default that balances responsiveness with resource usage - no user configuration needed.

**Files:**
- `Views/SettingsView.swift` - Settings UI
- Extensions for Codable + RawRepresentable

### Phase 8: Polish & Edge Cases

**Goal:** Handle edge cases and improve UX

- [x] Handle notification permission denied (show UI indicator)
- [x] Handle process read failures gracefully (see Error Handling below)
- [x] Add empty state for no monitored processes
- [ ] Add first-run onboarding/guidance
- [ ] Test with various process types
- [ ] Test memory/CPU usage of the app itself
- [ ] Code signing and notarization for distribution (Developer ID, non-sandboxed)

## Error Handling

Explicit error cases for `proc_pid_rusage()` and process monitoring:

| Error Code | Constant | Cause | User-Facing Action |
|------------|----------|-------|-------------------|
| 3 | `ESRCH` | Process does not exist (terminated) | Mark as "Not Running", keep in list for re-attach |
| 1 | `EPERM` | Permission denied (different user's process) | Show "Permission Denied" warning |
| 22 | `EINVAL` | Invalid PID or argument | Log internally, retry next poll cycle |

```swift
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

func readProcessMemory(pid: pid_t) throws -> UInt64 {
    var info = rusage_info_v4()
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
            proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
        }
    }

    guard result == 0 else {
        switch errno {
        case ESRCH: throw ProcessMonitorError.processNotFound(name: "Unknown")
        case EPERM: throw ProcessMonitorError.permissionDenied(name: "Unknown")
        default: throw ProcessMonitorError.readFailed(errno: errno)
        }
    }

    return info.ri_phys_footprint
}
```

**Notification Permission Handling:**

If the user denies notification permission:
- Show a persistent indicator in the menu bar dropdown: "⚠️ Notifications disabled"
- Add button: "Enable in System Settings" that opens `x-apple.systempreferences:com.apple.Notifications-Settings`
- Continue monitoring and showing visual indicators in the app UI

## Acceptance Criteria

### Functional Requirements

- [ ] App appears as menu bar icon only (no Dock icon)
- [ ] User can add processes from a dropdown list of running processes
- [ ] Process list is searchable
- [ ] User can configure 1-5 memory thresholds per process (in GB)
- [ ] App polls memory at fixed 5-second intervals
- [ ] Notification is sent when a threshold is first exceeded
- [ ] Sound plays when threshold exceeded (if enabled)
- [ ] Menu bar icon changes when any threshold is breached
- [ ] Settings persist across app restarts
- [ ] User can remove monitored processes
- [ ] User can quit app from dropdown menu

### Non-Functional Requirements

- [ ] App uses < 30MB memory itself
- [ ] Polling has negligible CPU impact (< 1%)
- [ ] UI is responsive (< 100ms to open dropdown)
- [ ] Works on macOS 13.0+

## Data Model

```swift
// MonitoredProcess.swift
struct MonitoredProcess: Identifiable, Codable {
    let id: UUID
    var processName: String          // Used for re-attachment after restart
    var currentPID: pid_t?           // Current PID (nil if not running)
    var thresholds: [Int]            // GB values, e.g., [5, 10, 15]
    var notifiedThresholds: Set<Int> // Thresholds already alerted
    var currentMemoryBytes: UInt64   // Last known memory
    var isRunning: Bool              // Whether process is currently found
}

// Settings (polling interval is hardcoded at 5s, not configurable)
struct AppSettings: Codable {
    var soundAlertsEnabled: Bool = true
    var launchAtLogin: Bool = false
}
```

## Key Decisions & Assumptions

| Decision | Rationale |
|----------|-----------|
| **Identify by process name** | PIDs change on restart; name-based allows auto-reattach |
| **Alert once per threshold** | Prevents alert fatigue; re-alerts when memory drops below then exceeds again |
| **Fixed 5-second polling** | Balance between responsiveness and resource usage; not user-configurable |
| **GB-only thresholds** | Simplicity; MB would add UI complexity for marginal benefit |
| **Max 5 thresholds per process** | Prevents UI clutter; more than enough for practical use |
| **macOS 13.0 minimum** | Required for MenuBarExtra; acceptable for new utility app |

## Open Questions (Addressed)

| Question | Resolution |
|----------|------------|
| How to identify processes persistently? | By process name; auto-reattach to new PID on restart |
| What happens when process terminates? | Show "Not Running" state; keep in list; auto-reattach when restarts |
| How often to re-alert? | Once per threshold breach; clear when drops below |
| How to filter process list? | GUI apps only via `NSRunningApplication` with `.regular` activation policy (same as Force Quit menu) |
| What notification actions? | Click opens app to breaching process |

## File Structure

```
SoundSourceMonitor/
├── SoundSourceMonitor.xcodeproj/
├── SoundSourceMonitor/
│   ├── SoundSourceMonitorApp.swift      # App entry with MenuBarExtra
│   ├── Models/
│   │   ├── MonitoredProcess.swift       # Process + thresholds model
│   │   ├── ProcessInfo.swift            # Basic process info
│   │   └── AppSettings.swift            # App preferences
│   ├── Views/
│   │   ├── ContentView.swift            # Main menu bar content
│   │   ├── ProcessPickerView.swift      # Process selection
│   │   ├── ProcessRowView.swift         # Single process display
│   │   ├── ThresholdConfigView.swift    # Threshold editing
│   │   └── SettingsView.swift           # App settings
│   ├── Services/
│   │   ├── ProcessMonitor.swift         # Memory monitoring loop
│   │   ├── ProcessLister.swift          # Process enumeration
│   │   └── AlertManager.swift           # Notifications + sounds
│   ├── Utilities/
│   │   └── MemoryFormatter.swift        # Byte formatting
│   ├── Resources/
│   │   └── Assets.xcassets
│   └── Info.plist
├── README.md
└── CLAUDE.md                            # Project conventions
```

## References & Research

### Apple Documentation
- [MenuBarExtra](https://developer.apple.com/documentation/SwiftUI/MenuBarExtra) - SwiftUI menu bar scene
- [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) - Notification management
- [AppStorage](https://developer.apple.com/documentation/swiftui/appstorage) - SwiftUI UserDefaults wrapper
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) - Launch at Login

### External Resources
- [Build a macOS menu bar utility in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) - Nil Coalescing
- [Activity Monitor Anatomy](https://www.bazhenov.me/posts/activity-monitor-anatomy/) - Memory metric explanation
- [proc_pid_rusage documentation](https://developer.apple.com/documentation/kernel/rusage_info_v4)

### Code Examples
- [libproc-swift](https://github.com/x13a/libproc-swift) - Swift wrapper for libproc
- [Swift benchmark DriverUtils](https://github.com/apple/swift/blob/master/benchmark/utils/DriverUtils.swift) - Memory reading example

---

*Plan created: 2026-01-21*
*Generated with Claude Code*
