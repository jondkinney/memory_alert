import SwiftUI

enum ContentViewMode {
    case main
    case processPicker
    case settings
    case thresholdConfig(MonitoredProcess)
}

struct ContentView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    @State private var mode: ContentViewMode = .main

    var body: some View {
        Group {
            switch mode {
            case .main:
                MainView(mode: $mode)
                    .environmentObject(processMonitor)
            case .processPicker:
                ProcessPickerView(mode: $mode)
                    .environmentObject(processMonitor)
            case .settings:
                SettingsView(mode: $mode)
            case .thresholdConfig(let process):
                ThresholdConfigView(process: process, mode: $mode)
                    .environmentObject(processMonitor)
            }
        }
        .frame(width: 350, height: 450)
    }
}

struct MainView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    @Binding var mode: ContentViewMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Memory Alert")
                    .font(.headline)
                Spacer()
                Button {
                    mode = .settings
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Add Process Button
            Button {
                mode = .processPicker
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Process")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding()

            Divider()

            // Monitored Processes List
            if processMonitor.monitoredProcesses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No processes monitored")
                        .foregroundColor(.secondary)
                    Text("Click \"Add Process\" to start monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(processMonitor.monitoredProcesses) { process in
                            ProcessRowView(process: process, mode: $mode)
                            Divider()
                        }
                    }
                }
            }

            Divider()

            // Quit Button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProcessMonitor())
        .frame(width: 350, height: 450)
}
