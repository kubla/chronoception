import Foundation

public struct TrainingEngine: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case ready
        case training(nextCue: Duration)
        case completed
        case cancelled
        case interrupted
    }

    public enum Event: Sendable {
        case start(at: Duration)
        case pulse(at: Duration)
        case cancel
        case interrupt
    }

    public let plan: SessionPlan
    public private(set) var phase: Phase = .ready
    public private(set) var completedIntervals = 0

    public init(plan: SessionPlan) { self.plan = plan }

    public mutating func send(_ event: Event) {
        switch (phase, event) {
        case (.ready, .start(let tick)):
            phase = .training(nextCue: tick + .seconds(plan.interval.seconds))
        case (.training(let deadline), .pulse(let tick)):
            guard tick >= deadline else { return }
            guard tick - deadline <= .milliseconds(500) else {
                phase = .interrupted
                return
            }
            completedIntervals += 1
            phase =
                completedIntervals == plan.attemptCount
                ? .completed : .training(nextCue: deadline + .seconds(plan.interval.seconds))
        case (.ready, .cancel), (.training, .cancel): phase = .cancelled
        case (.ready, .interrupt), (.training, .interrupt): phase = .interrupted
        default: break
        }
    }
}

public struct TrainingRecord: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let startedAt: Date
    public let interval: PracticeInterval
    public let plannedRepetitions: Int
    public var completedIntervals: Int
    public var screenOffRequested: Bool?
    public var status: PracticeRecord.Status

    public init(id: UUID, startedAt: Date, plan: SessionPlan) {
        self.id = id
        self.startedAt = startedAt
        interval = plan.interval
        plannedRepetitions = plan.attemptCount
        completedIntervals = 0
        status = .active
    }
}

public struct CalibrationSummary: Identifiable, Equatable, Sendable {
    public var id: PracticeInterval { interval }
    public let interval: PracticeInterval
    public let recent: [Attempt]
    public let previous: [Attempt]

    public var recentErrorPercent: Double { Self.mean(recent) }
    public var previousErrorPercent: Double? { previous.isEmpty ? nil : Self.mean(previous) }

    private static func mean(_ attempts: [Attempt]) -> Double {
        attempts.reduce(0) { $0 + $1.absoluteErrorFraction } / Double(attempts.count) * 100
    }

    public init(interval: PracticeInterval, newestFirst: [Attempt]) {
        self.interval = interval
        recent = Array(newestFirst.prefix(5))
        previous = Array(newestFirst.dropFirst(5).prefix(5))
    }
}
