import SwiftUI

struct ThresholdConfigView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    let process: MonitoredProcess
    @Binding var mode: ContentViewMode

    @State private var thresholds: [Int]
    @State private var newThreshold: String = ""

    init(process: MonitoredProcess, mode: Binding<ContentViewMode>) {
        self.process = process
        self._mode = mode
        self._thresholds = State(initialValue: process.thresholds.sorted())
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
                Text("Memory Thresholds (GB)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(thresholds, id: \.self) { threshold in
                    HStack {
                        Text("\(threshold) GB")
                        Spacer()
                        Button {
                            removeThreshold(threshold)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(thresholds.count <= 1)
                    }
                    .padding(.vertical, 4)
                }

                // Add new threshold
                if thresholds.count < 5 {
                    HStack {
                        TextField("Add threshold (GB)", text: $newThreshold)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
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
                Button("5, 10, 15") {
                    thresholds = [5, 10, 15]
                }
                .buttonStyle(.bordered)
                Button("2, 4, 8") {
                    thresholds = [2, 4, 8]
                }
                .buttonStyle(.bordered)
                Button("10, 20") {
                    thresholds = [10, 20]
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private var isValidThreshold: Bool {
        guard let value = Int(newThreshold), value > 0, value <= 100 else {
            return false
        }
        return !thresholds.contains(value)
    }

    private func addThreshold() {
        guard let value = Int(newThreshold), value > 0, value <= 100 else { return }
        guard !thresholds.contains(value) else { return }
        thresholds.append(value)
        thresholds.sort()
        newThreshold = ""
    }

    private func removeThreshold(_ threshold: Int) {
        thresholds.removeAll { $0 == threshold }
    }

    private func saveAndClose() {
        processMonitor.updateThresholds(for: process, thresholds: thresholds)
        mode = .main
    }
}
