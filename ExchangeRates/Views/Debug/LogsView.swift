//
//  LogsView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI
import UIKit

struct LogsView: View {
    @ObservedObject private var logManager = LogManager.shared
    @State private var selectedLevel: LogLevel? = nil
    @State private var showingShareSheet = false
    
    private var filteredLogs: [LogEntry] {
        logManager.getLogs(level: selectedLevel)
    }
    
    var body: some View {
        List {
            // Filter section
            Section {
                Picker("Filter", selection: $selectedLevel) {
                    Text("All").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level as LogLevel?)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Logs section
            Section {
                if filteredLogs.isEmpty {
                    Text("No logs available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredLogs) { entry in
                        LogEntryRow(entry: entry)
                    }
                }
            } header: {
                HStack {
                    Text("Logs (\(filteredLogs.count))")
                    Spacer()
                    if !logManager.logs.isEmpty {
                        Button("Clear") {
                            logManager.clearLogs()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !filteredLogs.isEmpty {
                    Button(action: {
                        shareLogs()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [exportLogsAsText()])
        }
    }
    
    private func shareLogs() {
        showingShareSheet = true
    }
    
    private func exportLogsAsText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        return filteredLogs.map { entry in
            let dateString = formatter.string(from: entry.timestamp)
            return "[\(dateString)] [\(entry.level.rawValue.uppercased())] [\(entry.source)] \(entry.message)"
        }.joined(separator: "\n")
    }
    
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    private var levelColor: Color {
        switch entry.level {
        case .debug:
            return .gray
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .success:
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelColor)
                    .cornerRadius(4)
                
                if !entry.source.isEmpty {
                    Text(entry.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.message)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                copyLogToClipboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
    
    private func copyLogToClipboard() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let dateString = formatter.string(from: entry.timestamp)
        let logText = "[\(dateString)] [\(entry.level.rawValue.uppercased())] [\(entry.source)] \(entry.message)"
        
        UIPasteboard.general.string = logText
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        LogsView()
    }
}

