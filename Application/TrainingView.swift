import ChronoceptionCore
import SwiftUI

struct TrainingView: View {
    @Bindable var store: PracticeStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: spacing) {
            if let message = store.trainingMessage {
                Text(message).font(.caption).accessibilityIdentifier("training-runtime-message")
            }
            Text(store.training.plan.interval.label)
                .font(.system(.title2, design: .serif))
            switch store.training.phase {
            case .training:
                Text("Feel each interval.").font(.headline)
                Text("\(store.training.completedIntervals) of \(store.training.plan.attemptCount) cues")
                    .accessibilityIdentifier("training-cues")
                Text(
                    store.quietTrainingSelected
                        ? "Quiet practice. You may lower your wrist; switching apps ends training."
                        : "A cue marks each interval. Keep this app open."
                )
                .font(.caption).foregroundStyle(.secondary)
                Button("End training", action: store.cancelTraining)
                    .accessibilityIdentifier("end-training")
            case .completed, .cancelled, .interrupted:
                Text(finishedTitle)
                    .font(finishedFont)
                    .accessibilityIdentifier("training-finished")
                Text("\(store.training.completedIntervals) cued intervals saved.").font(.caption)
                if store.training.phase == .interrupted {
                    Text("Timing stopped when the app left the foreground or a cue was delayed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Practice again", action: store.resetTraining)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("training-again")
            case .ready:
                Text("Starting quiet practice…")
                Button("End training", action: store.cancelTraining)
                    .accessibilityIdentifier("end-training")
            }
        }
        .multilineTextAlignment(.center)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.trainingLeftActiveScene() }
        }
    }

    private var finishedFont: Font {
        #if os(watchOS)
            .system(.title3, design: .serif)
        #else
            .system(size: PracticeStyle.heroSize, weight: .regular, design: .serif)
        #endif
    }

    private var spacing: CGFloat {
        #if os(watchOS)
            10
        #else
            16
        #endif
    }

    private var finishedTitle: String {
        switch store.training.phase {
        case .completed: "Training complete"
        case .cancelled: "Training ended"
        default: "Training interrupted"
        }
    }
}
