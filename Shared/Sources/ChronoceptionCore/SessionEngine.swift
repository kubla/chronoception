import Foundation

public struct SessionEngine: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case ready
        case estimating(start: Duration)
        case feedback(Attempt)
        case completed
        case cancelled
        case interrupted
    }

    public enum Event: Sendable {
        case start(at: Duration)
        case estimate(at: Duration)
        case advance(at: Duration)
        case cancel
        case interrupt
    }

    public let plan: SessionPlan
    public private(set) var phase: Phase = .ready
    public private(set) var attempts: [Attempt] = []

    public init(plan: SessionPlan) {
        self.plan = plan
    }

    public mutating func send(_ event: Event) {
        switch (phase, event) {
        case (.ready, .start(let tick)):
            phase = .estimating(start: tick)
        case (.estimating(let start), .estimate(let tick)):
            let elapsed = tick - start
            let components = elapsed.components
            let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
            guard let attempt = Attempt(interval: plan.interval, elapsedSeconds: seconds) else {
                phase = .interrupted
                return
            }
            attempts.append(attempt)
            phase = .feedback(attempt)
        case (.feedback, .advance(let tick)):
            phase = attempts.count == plan.attemptCount ? .completed : .estimating(start: tick)
        case (.ready, .cancel), (.estimating, .cancel), (.feedback, .cancel):
            phase = .cancelled
        case (.estimating, .interrupt), (.feedback, .interrupt):
            phase = .interrupted
        default:
            break
        }
    }
}
