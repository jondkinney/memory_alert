import SwiftUI
import AppKit

struct ProcessPickerView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var runningApps: [RunningAppInfo] = []

    private var filteredApps: [RunningAppInfo] {
        if searchText.isEmpty {
            return runningApps
        }
        return runningApps.filter {
            $0.localizedName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Process")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .padding()

            Divider()

            // App List
            if filteredApps.isEmpty {
                VStack {
                    Text("No apps found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredApps) { app in
                            AppRowView(app: app) {
                                addProcess(app)
                            }
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(width: 350, height: 400)
        .onAppear {
            refreshAppList()
        }
    }

    private func refreshAppList() {
        runningApps = ProcessLister.getRunningGUIApps()
            .filter { app in
                // Exclude already monitored processes
                !processMonitor.monitoredProcesses.contains { $0.bundleIdentifier == app.bundleIdentifier }
            }
    }

    private func addProcess(_ app: RunningAppInfo) {
        let process = MonitoredProcess(
            processName: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            currentPID: app.pid,
            thresholds: [5, 10, 15], // Default thresholds
            icon: app.icon
        )
        processMonitor.addProcess(process)
        isPresented = false
    }
}

struct AppRowView: View {
    let app: RunningAppInfo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 24))
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading) {
                    Text(app.localizedName)
                        .fontWeight(.medium)
                    Text("PID: \(app.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProcessPickerView(isPresented: .constant(true))
        .environmentObject(ProcessMonitor())
}
