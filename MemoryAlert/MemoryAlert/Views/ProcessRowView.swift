import SwiftUI

struct ProcessRowView: View {
    @EnvironmentObject var processMonitor: ProcessMonitor
    let process: MonitoredProcess
    @Binding var mode: ContentViewMode

    private var statusColor: Color {
        if !process.isRunning {
            return .gray
        }
        if process.breachedThresholds.isEmpty {
            return .green
        }
        return .red
    }

    private var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(process.currentMemoryBytes), countStyle: .memory)
    }

    private var formattedThresholds: String {
        process.thresholds.sorted().map { "\($0)GB" }.joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            // Process info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let icon = process.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    Text(process.processName)
                        .fontWeight(.medium)
                    if !process.isRunning {
                        Text("(Not Running)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                if process.isRunning {
                    HStack {
                        Text("Memory: \(formattedMemory)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !process.breachedThresholds.isEmpty {
                            Text("Over \(process.breachedThresholds.min() ?? 0)GB")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Text("Thresholds: \(formattedThresholds)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            VStack(spacing: 4) {
                Button {
                    mode = .thresholdConfig(process)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .help("Configure thresholds")

                Button {
                    processMonitor.removeProcess(process)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove from monitoring")
            }
        }
        .padding()
        .background(process.breachedThresholds.isEmpty ? Color.clear : Color.red.opacity(0.1))
    }
}
