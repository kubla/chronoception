import ChronoceptionCore
import SwiftUI

struct PracticeView: View {
    @Bindable var store: PracticeStore
    @State private var showIntervals = false
    @State private var showHistory = false
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let message = store.storageMessage {
                        VStack(spacing: 8) {
                            Text(message).font(.footnote)
                            Button("Try again", action: store.retryStorage)
                        }
                        .padding(12)
                        .background(PracticeStyle.surface, in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityIdentifier("storage-status")
                    }
                    switch store.engine.phase {
                    case .ready: configuration
                    case .estimating: estimation
                    case .feedback(let attempt): feedback(attempt)
                    case .completed: finished(title: "Session complete", detail: savedDetail)
                    case .cancelled: finished(title: "Session ended", detail: savedDetail)
                    case .interrupted:
                        finished(title: "Timing interrupted", detail: "Completed attempts are retained.")
                    }
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .foregroundStyle(PracticeStyle.ink)
            }
            .id(phaseIdentity)
            .background(PracticeStyle.background)
            #if os(watchOS)
                .navigationTitle("Practice")
            #else
                .navigationTitle("Chronoception")
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showInfo = true
                    } label: {
                        Label("About Chronoception", systemImage: "info.circle")
                            .foregroundStyle(PracticeStyle.toolbarInk)
                    }
                    .accessibilityIdentifier("open-about")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(PracticeStyle.toolbarInk)
                    }
                    .accessibilityIdentifier("open-history")
                }
            }
            .sheet(isPresented: $showInfo) { AppInfoView() }
            .sheet(isPresented: $showIntervals) {
                IntervalSelection(interval: $store.interval)
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(history: store.history)
            }
            .sensoryFeedback(.selection, trigger: store.hapticSequence)
        }
    }

    private var spacing: CGFloat {
        #if os(watchOS)
            10
        #else
            22
        #endif
    }

    private var phaseIdentity: Int {
        switch store.engine.phase {
        case .ready: 0
        case .estimating: 1
        case .feedback: 2
        case .completed: 3
        case .cancelled: 4
        case .interrupted: 5
        }
    }

    private var configuration: some View {
        #if os(watchOS)
            VStack(spacing: 10) {
                Button {
                    showIntervals = true
                } label: {
                    HStack {
                        Text(store.interval.label).font(.system(.title2, design: .serif))
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption)
                    }
                }
                .accessibilityLabel("Interval, \(store.interval.label)")
                .accessibilityIdentifier("choose-interval")
                Picker("Attempts", selection: $store.attemptCount) {
                    ForEach([1, 3, 5], id: \.self) { count in Text("\(count)").tag(count) }
                }
                .pickerStyle(.navigationLink)
                Button("Begin", action: store.begin)
                    .buttonStyle(.borderedProminent)
                    .tint(PracticeStyle.accent)
                    .foregroundStyle(PracticeStyle.buttonInk)
                    .accessibilityIdentifier("begin-session")
            }
        #else
            VStack(spacing: 26) {
                Text("Feel the interval.")
                    .font(.system(size: PracticeStyle.heroSize, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                Text("Choose a duration. Mark it when it feels complete.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showIntervals = true
                } label: {
                    VStack(spacing: 6) {
                        Text("INTERVAL").font(.caption2).tracking(2)
                        HStack(spacing: 8) {
                            Text(store.interval.label).font(.system(.largeTitle, design: .serif))
                            Image(systemName: "chevron.down").font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(PracticeStyle.surface, in: RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("choose-interval")
                Text("Attempts").font(.caption).foregroundStyle(.secondary)
                Picker("Attempts", selection: $store.attemptCount) {
                    ForEach([1, 3, 5], id: \.self) { count in Text("\(count)").tag(count) }
                }
                #if os(iOS)
                    .pickerStyle(.segmented)
                #endif
                .accessibilityLabel("Number of attempts")
                Button("Begin", action: store.begin)
                    .buttonStyle(.borderedProminent)
                    .tint(PracticeStyle.accent)
                    .foregroundStyle(PracticeStyle.buttonInk)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("begin-session")
                Text("A practice in noticing time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        #endif
    }

    private var estimation: some View {
        VStack(spacing: spacing) {
            #if os(watchOS)
                HStack {
                    Text(store.engine.plan.interval.label)
                    Spacer()
                    Text("\(store.engine.attempts.count + 1) of \(store.engine.plan.attemptCount)")
                }
                .font(.caption)
            #else
                Text(store.engine.plan.interval.label)
                    .font(.system(size: PracticeStyle.heroSize, weight: .regular, design: .serif))
                Text("Attempt \(store.engine.attempts.count + 1) of \(store.engine.plan.attemptCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            #endif
            Button(action: store.estimate) {
                Text("Now")
                    .font(.system(.title2, design: .serif))
                    .frame(width: PracticeStyle.markSize, height: PracticeStyle.markSize)
                    .background(PracticeStyle.surface, in: Circle())
                    .overlay(Circle().stroke(PracticeStyle.accent.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark my estimate")
            .accessibilityIdentifier("mark-estimate")
            #if os(iOS)
                Text("Tap when the interval feels complete.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            #endif
            Button("End session", action: store.cancel)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("end-session")
        }
    }

    private func feedback(_ attempt: Attempt) -> some View {
        VStack(spacing: spacing) {
            Text(attempt.feedback)
                .font(.system(size: PracticeStyle.heroSize, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("attempt-feedback")
            #if os(watchOS)
                Text("Estimated \(DurationText.seconds(attempt.elapsedSeconds)) of \(attempt.interval.label)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            #else
                VStack(spacing: 8) {
                    LabeledContent("Your estimate", value: DurationText.seconds(attempt.elapsedSeconds))
                    LabeledContent("Interval", value: attempt.interval.label)
                }
                .font(.subheadline)
                .padding()
                .background(PracticeStyle.surface, in: RoundedRectangle(cornerRadius: 18))
            #endif
            Button(
                store.engine.attempts.count == store.engine.plan.attemptCount ? "Finish" : "Next attempt",
                action: store.advance
            )
            .buttonStyle(.borderedProminent)
            .tint(PracticeStyle.accent)
            .foregroundStyle(PracticeStyle.buttonInk)
            .accessibilityIdentifier("advance-session")
            if store.engine.attempts.count < store.engine.plan.attemptCount {
                Button("End session", action: store.cancel)
                    .accessibilityIdentifier("end-session")
            }
        }
    }

    private var savedDetail: String {
        let count = store.engine.attempts.count
        if count == 0 { return "No estimates were recorded." }
        return count == 1 ? "1 attempt in your history." : "\(count) attempts in your history."
    }

    private func finished(title: String, detail: String) -> some View {
        VStack(spacing: spacing) {
            #if os(iOS)
                Image(systemName: "circle.dotted")
                    .font(.system(size: 54, weight: .ultraLight))
                    .foregroundStyle(PracticeStyle.accent)
            #endif
            Text(title)
                .font(.system(size: PracticeStyle.heroSize, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("session-finished")
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            Button("Practice again", action: store.reset)
                .buttonStyle(.borderedProminent)
                .tint(PracticeStyle.accent)
                .foregroundStyle(PracticeStyle.buttonInk)
                .accessibilityIdentifier("practice-again")
            Button("View history") { showHistory = true }
        }
    }
}

private struct IntervalSelection: View {
    @Binding var interval: PracticeInterval
    @Environment(\.dismiss) private var dismiss
    @State private var minutes = 5
    @State private var seconds = 0

    var body: some View {
        NavigationStack {
            List {
                ForEach(PracticeInterval.presets, id: \.self) { value in
                    Button(value.label) {
                        interval = value
                        dismiss()
                    }
                    .foregroundStyle(PracticeStyle.ink)
                    .accessibilityIdentifier("interval-\(value.seconds)")
                }
                Section("Custom interval") {
                    Stepper("\(minutes) min", value: $minutes, in: 0...120)
                    Stepper("\(seconds) sec", value: $seconds, in: 0...59)
                    Button("Use interval") {
                        if let value = PracticeInterval(seconds: minutes * 60 + seconds) {
                            interval = value
                            dismiss()
                        }
                    }
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
            .navigationTitle("Interval")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(PracticeStyle.toolbarInk)
                }
            }
        }
    }
}
