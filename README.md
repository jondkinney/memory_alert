# MemoryAlert

A lightweight macOS menu bar app that monitors process memory usage and alerts you when configurable thresholds are exceeded.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar app** — Lives in your menu bar, no Dock icon
- **Monitor multiple processes** — Track memory usage for any running GUI or menu bar app
- **Configurable thresholds** — Set custom alerts at any GB level (e.g., 5GB, 10GB, 15GB)
- **Multiple alert types** — macOS notifications + optional sound alerts
- **Visual indicators** — Status colors show which processes are over threshold
- **Preset configurations** — Quick threshold presets for common use cases
- **Persists across restarts** — Your monitored processes and settings are saved
- **Launch at login** — Optional automatic startup

## Installation

### Download

Download the latest release from the [Releases page](https://github.com/jondkinney/soundsource_monitor/releases).

1. Download `MemoryAlert.zip`
2. Unzip and drag `MemoryAlert.app` to your Applications folder
3. Launch the app — it will appear in your menu bar

### Build from Source

Requirements:
- macOS 13.0 or later
- Xcode 15.0 or later

```bash
git clone https://github.com/jondkinney/soundsource_monitor.git
cd soundsource_monitor/MemoryAlert
xcodebuild -scheme MemoryAlert -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/MemoryAlert-*/Build/Products/Release/`.

## Usage

1. Click the memory chip icon in your menu bar
2. Click **Add Process** to select an app to monitor
3. The app will poll memory usage every 5 seconds
4. When a threshold is breached, you'll receive a notification

### Configuring Thresholds

1. Click the slider icon next to any monitored process
2. Add or remove threshold values (in GB)
3. Use presets for quick configuration

### Settings

- **Play sound on threshold breach** — Enable/disable audio alerts
- **Launch at login** — Start MemoryAlert automatically when you log in
- **Notifications** — Shows notification permission status with easy access to System Settings

## Technical Details

- Uses `proc_pid_rusage()` with `ri_phys_footprint` for accurate memory readings (same as Activity Monitor)
- Monitors GUI apps (`.regular` activation policy) and menu bar apps (`.accessory` activation policy)
- Non-sandboxed for access to process memory information
- Built with SwiftUI and Combine

## License

MIT License — see [LICENSE](LICENSE) for details.
