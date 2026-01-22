import SwiftUI

struct ContentView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    @State private var showingProcessPicker = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Memory Alert")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Add Process Button
            Button(action: { showingProcessPicker = true }) {
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
                            ProcessRowView(process: process)
                            Divider()
                        }
                    }
                }
            }

            Divider()

            // Quit Button
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding()
        }
        .sheet(isPresented: $showingProcessPicker) {
            ProcessPickerView(isPresented: $showingProcessPicker)
                .environmentObject(processMonitor)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProcessMonitor())
        .frame(width: 350, height: 450)
}
