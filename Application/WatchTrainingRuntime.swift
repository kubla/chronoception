#if os(watchOS)
    import Foundation
    import WatchKit

    @MainActor
    final class WatchTrainingRuntime: NSObject, WKExtendedRuntimeSessionDelegate {
        private let session = WKExtendedRuntimeSession()
        private let onStarted: @MainActor () -> Void
        private let onStopped: @MainActor (String) -> Void
        private var stopped = false

        init(onStarted: @escaping @MainActor () -> Void, onStopped: @escaping @MainActor (String) -> Void) {
            self.onStarted = onStarted
            self.onStopped = onStopped
        }

        func start() {
            session.delegate = self
            session.start()
        }

        func stop() {
            stopped = true
            if session.state != .invalid { session.invalidate() }
        }

        nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if stopped { stop() } else if session.state == .running { onStarted() }
            }
        }

        nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession)
        {
            Task { @MainActor [weak self] in
                guard let self, !stopped else { return }
                onStopped("Quiet practice reached its runtime limit.")
            }
        }

        nonisolated func extendedRuntimeSession(
            _ extendedRuntimeSession: WKExtendedRuntimeSession,
            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?
        ) {
            let detail =
                error?.localizedDescription
                ?? "Quiet practice stopped when its runtime ended or you left the app."
            Task { @MainActor [weak self] in
                guard let self, !stopped else { return }
                onStopped(detail)
            }
        }
    }
#endif
