import ChronoceptionCore
import SwiftUI

struct TrainingView: View {
    @Bindable var store: PracticeStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let sessionID = store.trainingSessionID
        VStack(spacing: 16) {
            Text(store.training.plan.interval.label)
                .font(.system(.title, design: .serif))
            switch store.training.phase {
            case .training:
                Text("Feel each interval.").font(.headline)
                Text("\(store.training.completedIntervals) of \(store.training.plan.attemptCount) cues")
                    .accessibilityIdentifier("training-cues")
                Text("A cue marks each interval. Keep this app open.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("End training", action: store.cancelTraining)
                    .accessibilityIdentifier("end-training")
            case .completed, .cancelled, .interrupted:
                Text(finishedTitle)
                    .font(.system(.title2, design: .serif))
                    .accessibilityIdentifier("training-finished")
                Text("\(store.training.completedIntervals) cued intervals saved.")
                if store.training.phase == .interrupted {
                    Text("Timing stopped when the app left the foreground or a cue was delayed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Practice again", action: store.resetTraining)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("training-again")
            case .ready: EmptyView()
            }
        }
        .multilineTextAlignment(.center)
        .task(id: sessionID) { await store.runTraining(sessionID: sessionID) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.interruptTraining() }
        }
    }

    private var finishedTitle: String {
        switch store.training.phase {
        case .completed: "Training complete"
        case .cancelled: "Training ended"
        default: "Training interrupted"
        }
    }
}
