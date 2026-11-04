import Foundation

public struct PracticeInterval: Equatable, Hashable, Sendable, Codable {
    public let seconds: Int

    public init?(seconds: Int) {
        guard seconds > 0 else { return nil }
        self.seconds = seconds
    }

    private init(validatedSeconds: Int) {
        seconds = validatedSeconds
    }

    public static let fiveMinutes = PracticeInterval(validatedSeconds: 300)
    public static let presets = [30, 60, 180, 300, 600].map(PracticeInterval.init(validatedSeconds:))

    public var label: String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 { return "\(remainder)s" }
        if remainder == 0 { return "\(minutes) min" }
        return "\(minutes)m \(remainder)s"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let seconds = try container.decode(Int.self)
        guard let interval = PracticeInterval(seconds: seconds) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "A practice interval must be positive.")
        }
        self = interval
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(seconds)
    }
}

public struct SessionPlan: Equatable, Sendable {
    public let interval: PracticeInterval
    public let attemptCount: Int

    public init?(interval: PracticeInterval, attemptCount: Int) {
        guard attemptCount > 0 else { return nil }
        self.interval = interval
        self.attemptCount = attemptCount
    }

    public static let singleFiveMinutes = SessionPlan(interval: .fiveMinutes, validatedCount: 1)

    private init(interval: PracticeInterval, validatedCount: Int) {
        self.interval = interval
        attemptCount = validatedCount
    }
}
