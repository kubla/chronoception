import ChronoceptionCore
import SwiftUI

struct HistoryView: View {
    let history: PracticeHistory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if history.records.isEmpty && history.trainingRecords.isEmpty {
                        ContentUnavailableView(
                            "No attempts yet", systemImage: "circle.dotted",
                            description: Text("Your observations will appear here."))
                    } else {
                        summary
                        ForEach(history.calibration) { summary in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(summary.interval.label) calibration").font(.headline)
                                Text(
                                    "Latest \(summary.recent.count): \(summary.recentErrorPercent, specifier: "%.1f")% error"
                                )
                                if let previous = summary.previousErrorPercent {
                                    Text(
                                        "Previous \(summary.previous.count): \(previous, specifier: "%.1f")% error"
                                    )
                                } else {
                                    Text("Keep practicing to compare with earlier estimates.")
                                }
                            }
                            .font(.caption)
                            .accessibilityIdentifier("calibration-summary")
                        }
                        ForEach(history.trainingRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Training · \(record.interval.label)").font(.headline)
                                Text(
                                    "\(record.completedIntervals) of \(record.plannedRepetitions) cued intervals"
                                )
                                Text(record.status.rawValue.capitalized)
                                Text(
                                    record.startedAt,
                                    format: .dateTime.month(.abbreviated).day().hour().minute())
                            }
                            .font(.caption)
                            .accessibilityIdentifier("training-record")
                        }
                        ForEach(history.records) { record in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(record.interval.label).font(.system(.title3, design: .serif))
                                    Spacer()
                                    Text(record.status.rawValue.capitalized).font(.caption)
                                }
                                Text(
                                    record.startedAt,
                                    format: .dateTime.month(.abbreviated).day().hour().minute()
                                )
                                .font(.caption).foregroundStyle(.secondary)
                                if record.attempts.isEmpty {
                                    Text("No estimate recorded.").font(.subheadline)
                                }
                                ForEach(Array(record.attempts.enumerated()), id: \.offset) { index, attempt in
                                    LabeledContent("Attempt \(index + 1)", value: attempt.feedback)
                                        .font(.subheadline)
                                }
                            }
                            .padding()
                            .background(PracticeStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityIdentifier("history-record")
                        }
                    }
                }
                .padding()
                .foregroundStyle(PracticeStyle.ink)
            }
            .background(PracticeStyle.background)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(PracticeStyle.toolbarInk)
                        .accessibilityIdentifier("close-history")
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                history.completedAttempts.count == 1
                    ? "1 recorded attempt" : "\(history.completedAttempts.count) recorded attempts"
            )
            .font(.headline)
            .accessibilityIdentifier("history-count")
            if !history.completedAttempts.isEmpty {
                let mean =
                    history.completedAttempts.reduce(0) { $0 + $1.absoluteErrorFraction }
                    / Double(history.completedAttempts.count)
                Text("Mean absolute error: \(mean * 100, specifier: "%.1f")%")
                    .font(.subheadline)
                Text("Completed attempts are retained when a session ends early.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
