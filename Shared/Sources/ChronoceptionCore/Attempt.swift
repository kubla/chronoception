import Foundation

public struct Attempt: Equatable, Sendable, Codable {
    public let interval: PracticeInterval
    public let elapsedSeconds: Double

    public init?(interval: PracticeInterval, elapsedSeconds: Double) {
        guard elapsedSeconds.isFinite, elapsedSeconds >= 0 else { return nil }
        self.interval = interval
        self.elapsedSeconds = elapsedSeconds
    }

    public var signedErrorSeconds: Double {
        elapsedSeconds - Double(interval.seconds)
    }

    public var absoluteErrorFraction: Double {
        abs(signedErrorSeconds) / Double(interval.seconds)
    }

    public var feedback: String {
        let error = signedErrorSeconds
        if error == 0 { return "On time" }
        let amount = DurationText.seconds(abs(error))
        return error < 0 ? "\(amount) early" : "\(amount) late"
    }

    private enum CodingKeys: String, CodingKey { case interval, elapsedSeconds }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let interval = try container.decode(PracticeInterval.self, forKey: .interval)
        let seconds = try container.decode(Double.self, forKey: .elapsedSeconds)
        guard let attempt = Attempt(interval: interval, elapsedSeconds: seconds) else {
            throw DecodingError.dataCorruptedError(
                forKey: .elapsedSeconds, in: container,
                debugDescription: "Elapsed time must be finite and nonnegative.")
        }
        self = attempt
    }
}

public enum DurationText {
    public static func seconds(_ seconds: Double) -> String {
        if seconds == 0 { return "0s" }
        if seconds < 0.1 { return "<0.1s" }
        if seconds < 10 { return String(format: "%.1fs", locale: Locale(identifier: "en_US_POSIX"), seconds) }
        let rounded = Int(seconds.rounded())
        if rounded < 60 { return "\(rounded)s" }
        let minutes = rounded / 60
        let remainder = rounded % 60
        return remainder == 0 ? "\(minutes) min" : "\(minutes)m \(remainder)s"
    }
}
