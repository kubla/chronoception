import ChronoceptionCore
import ChronoceptionStorage
import Foundation
import OSLog
import Observation

#if os(watchOS)
    import WatchKit
#endif

@MainActor @Observable
final class PracticeStore {
    var interval: PracticeInterval = .fiveMinutes
    var attemptCount = 1
    var trainingSelected = false
    var training = TrainingEngine(plan: .singleFiveMinutes)
    private var trainingRecord: TrainingRecord?
    private var trainingTask: Task<Void, Never>?
    var quietTrainingSelected = false
    #if os(iOS)
        let pocketExperiment = PocketCueExperiment()
    #endif
    private(set) var trainingMessage: String?
    #if os(watchOS)
        private var quietRuntime: WatchTrainingRuntime?
    #endif
    var engine = SessionEngine(plan: .singleFiveMinutes)
    private(set) var history = PracticeHistory()
    private(set) var storageMessage: String?
    private(set) var hapticSequence = 0

    private let clock = ContinuousClock()
    private let origin = ContinuousClock.now
    private let repository: HistoryRepository
    private let logger = Logger(subsystem: "io.mjjt.chronoception", category: "history")
    private var currentRecord: PracticeRecord?
    private var historyLoadFailed = false

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Chronoception")) {
        var directory = directory
        #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                if let key = environment["CHRONOCEPTION_TEST_HISTORY"] {
                    directory = directory.appending(path: "Testing/\(key)")
                }
                if let raw = environment["CHRONOCEPTION_TEST_INTERVAL"],
                    let seconds = Int(raw), let value = PracticeInterval(seconds: seconds)
                {
                    interval = value
                }
                if let raw = environment["CHRONOCEPTION_TEST_ATTEMPTS"], let count = Int(raw), count > 0 {
                    attemptCount = count
                }
            }
        #endif
        repository = HistoryRepository(url: directory.appending(path: "history.json"))
        loadHistory()
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                let raw = ProcessInfo.processInfo.environment["CHRONOCEPTION_TEST_SEED_HISTORY"]
            {
                history = try! JSONDecoder().decode(PracticeHistory.self, from: Data(raw.utf8))
                saveHistory()
            }
        #endif
    }

    private var tick: Duration { origin.duration(to: clock.now) }

    func beginTraining() {
        guard let plan = SessionPlan(interval: interval, attemptCount: attemptCount) else { return }
        #if os(watchOS)
            if quietTrainingSelected && plan.interval.seconds > 3600 / plan.attemptCount {
                trainingMessage = "Quiet practice must fit within one hour."
                return
            }
        #endif
        trainingMessage = nil
        stopTrainingRuntime()
        training = TrainingEngine(plan: plan)
        let sessionID = UUID()
        trainingRecord = TrainingRecord(id: sessionID, startedAt: Date(), plan: plan)
        #if os(watchOS)
            trainingRecord?.screenOffRequested = quietTrainingSelected
        #endif
        persistTraining()
        #if os(watchOS)
            if quietTrainingSelected {
                let runtime = WatchTrainingRuntime(
                    onStarted: { [weak self] in self?.startTrainingClock(sessionID: sessionID) },
                    onStopped: { [weak self] detail in
                        guard let self, trainingRecord?.id == sessionID else { return }
                        trainingMessage = detail
                        interruptTraining()
                    })
                quietRuntime = runtime
                runtime.start()
                return
            }
        #endif
        startTrainingClock(sessionID: sessionID)
    }

    private func startTrainingClock(sessionID: UUID) {
        guard trainingRecord?.id == sessionID, training.phase == .ready else { return }
        training.send(.start(at: tick))
        persistTraining()
        emitTrainingCue()
        trainingTask = Task { [weak self] in await self?.runTraining(sessionID: sessionID) }
    }

    private func emitTrainingCue() {
        #if os(watchOS)
            WKInterfaceDevice.current().play(.notification)
        #else
            hapticSequence += 1
        #endif
    }

    func trainingLeftActiveScene() {
        #if os(watchOS)
            if quietRuntime != nil { return }
        #endif
        interruptTraining()
    }

    private func stopTrainingRuntime() {
        trainingTask?.cancel()
        trainingTask = nil
        #if os(watchOS)
            quietRuntime?.stop()
            quietRuntime = nil
        #endif
    }

    var trainingSessionID: UUID? { trainingRecord?.id }

    func runTraining(sessionID: UUID?) async {
        guard let sessionID, !Task.isCancelled, trainingRecord?.id == sessionID else { return }
        while trainingRecord?.id == sessionID, case .training(let deadline) = training.phase {
            do {
                try await clock.sleep(until: origin.advanced(by: deadline), tolerance: .milliseconds(20))
            } catch {
                if trainingRecord?.id == sessionID { interruptTraining() }
                return
            }
            guard !Task.isCancelled, trainingRecord?.id == sessionID else { return }
            let previous = training.completedIntervals
            training.send(.pulse(at: tick))
            if training.completedIntervals > previous { emitTrainingCue() }
            persistTraining()
        }
        if trainingRecord?.id == sessionID { stopTrainingRuntime() }
    }

    func interruptTraining() {
        training.send(.interrupt)
        persistTraining()
        stopTrainingRuntime()
    }

    func cancelTraining() {
        training.send(.cancel)
        persistTraining()
        stopTrainingRuntime()
    }

    func resetTraining() {
        stopTrainingRuntime()
        trainingMessage = nil
        training = TrainingEngine(plan: .singleFiveMinutes)
        trainingRecord = nil
    }

    private func persistTraining() {
        guard var record = trainingRecord else { return }
        record.completedIntervals = training.completedIntervals
        switch training.phase {
        case .completed: record.status = .completed
        case .cancelled: record.status = .cancelled
        case .interrupted: record.status = .interrupted
        default: record.status = .active
        }
        trainingRecord = record
        history.upsert(record)
        saveHistory()
    }

    func begin() {
        guard let plan = SessionPlan(interval: interval, attemptCount: attemptCount) else { return }
        engine = SessionEngine(plan: plan)
        currentRecord = PracticeRecord(id: UUID(), startedAt: Date(), plan: plan)
        engine.send(.start(at: tick))
        persistCurrent()
        hapticSequence += 1
    }

    func estimate() {
        let count = engine.attempts.count
        engine.send(.estimate(at: tick))
        if engine.attempts.count != count {
            persistCurrent()
            hapticSequence += 1
        }
    }

    func advance() {
        engine.send(.advance(at: tick))
        persistCurrent()
    }

    func cancel() {
        engine.send(.cancel)
        persistCurrent()
    }

    func reset() {
        engine = SessionEngine(plan: .singleFiveMinutes)
        currentRecord = nil
    }

    func retryStorage() {
        if historyLoadFailed { loadHistory() } else { saveHistory() }
    }

    private func loadHistory() {
        do {
            var loaded = try repository.load()
            let recovered = loaded.markInterruptedSessions()
            for record in history.records.reversed() { loaded.upsert(record) }
            for record in history.trainingRecords.reversed() { loaded.upsert(record) }
            history = loaded
            historyLoadFailed = false
            storageMessage = nil
            if recovered || !history.records.isEmpty || !history.trainingRecords.isEmpty { saveHistory() }
        } catch {
            historyLoadFailed = true
            storageMessage = "Saved history couldn’t be read. The file has been preserved."
            logger.error("History load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persistCurrent() {
        guard var record = currentRecord else { return }
        record.attempts = engine.attempts
        switch engine.phase {
        case .completed: record.status = .completed
        case .cancelled: record.status = .cancelled
        case .interrupted: record.status = .interrupted
        default: record.status = .active
        }
        currentRecord = record
        history.upsert(record)
        saveHistory()
    }

    private func saveHistory() {
        guard !historyLoadFailed else { return }
        do {
            try repository.save(history)
            storageMessage = nil
        } catch {
            storageMessage = "This result hasn’t been saved yet. Try again."
            logger.error("History save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
