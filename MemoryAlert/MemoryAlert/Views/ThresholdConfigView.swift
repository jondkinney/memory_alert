import SwiftUI

struct ThresholdConfigView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    let process: MonitoredProcess
    @Binding var mode: ContentViewMode

    @State private var thresholdsMB: [Int]
    @State private var newThreshold: String = ""

    init(process: MonitoredProcess, mode: Binding<ContentViewMode>) {
        self.process = process
        self._mode = mode
        self._thresholdsMB = State(initialValue: process.thresholdsMB.sorted())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    saveAndClose()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text("Configure Thresholds")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            // Process info
            HStack {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Text(process.processName)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()

            Divider()

            // Thresholds list
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory Thresholds")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(thresholdsMB, id: \.self) { threshold in
                    HStack {
                        Text(MonitoredProcess.formatThreshold(threshold))
                        Spacer()
                        Button {
                            removeThreshold(threshold)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(thresholdsMB.count <= 1)
                    }
                    .padding(.vertical, 4)
                }

                // Add new threshold
                if thresholdsMB.count < 5 {
                    HStack {
                        TextField("e.g. 5GB, 500MB", text: $newThreshold)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                            .onSubmit {
                                addThreshold()
                            }
                        Button {
                            addThreshold()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isValidThreshold)
                    }

                    Text("Enter as GB (e.g. 5) or MB (e.g. 500MB)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Maximum 5 thresholds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Spacer()

            // Preset buttons
            Divider()
            HStack {
                Text("Presets:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("5, 10, 15 GB") {
                    thresholdsMB = [5120, 10240, 15360]
                }
                .buttonStyle(.bordered)
                Button("2, 4, 8 GB") {
                    thresholdsMB = [2048, 4096, 8192]
                }
                .buttonStyle(.bordered)
                Button("500MB, 1GB") {
                    thresholdsMB = [500, 1024]
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private var isValidThreshold: Bool {
        guard let valueMB = MonitoredProcess.parseThreshold(newThreshold) else {
            return false
        }
        return !thresholdsMB.contains(valueMB)
    }

    private func addThreshold() {
        guard let valueMB = MonitoredProcess.parseThreshold(newThreshold) else { return }
        guard !thresholdsMB.contains(valueMB) else { return }
        thresholdsMB.append(valueMB)
        thresholdsMB.sort()
        newThreshold = ""
    }

    private func removeThreshold(_ threshold: Int) {
        thresholdsMB.removeAll { $0 == threshold }
    }

    private func saveAndClose() {
        processMonitor.updateThresholds(for: process, thresholdsMB: thresholdsMB)
        mode = .main
    }
}
