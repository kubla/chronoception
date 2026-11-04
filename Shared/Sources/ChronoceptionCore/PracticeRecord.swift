import Foundation

public struct PracticeRecord: Identifiable, Equatable, Sendable, Codable {
    public enum Status: String, Codable, Sendable {
        case active, completed, cancelled, interrupted
    }

    public let id: UUID
    public let startedAt: Date
    public let interval: PracticeInterval
    public let plannedAttempts: Int
    public var attempts: [Attempt]
    public var status: Status

    public init(
        id: UUID, startedAt: Date, plan: SessionPlan, attempts: [Attempt] = [], status: Status = .active
    ) {
        self.id = id
        self.startedAt = startedAt
        interval = plan.interval
        plannedAttempts = plan.attemptCount
        self.attempts = attempts
        self.status = status
    }

    public var meanAbsoluteErrorSeconds: Double? {
        guard !attempts.isEmpty else { return nil }
        return attempts.reduce(0) { $0 + abs($1.signedErrorSeconds) } / Double(attempts.count)
    }
}

public struct PracticeHistory: Equatable, Sendable, Codable {
    public private(set) var records: [PracticeRecord]
    public private(set) var trainingRecords: [TrainingRecord]

    public init(records: [PracticeRecord] = [], trainingRecords: [TrainingRecord] = []) {
        self.records = records
        self.trainingRecords = trainingRecords
    }

    private enum CodingKeys: String, CodingKey { case records, trainingRecords }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        records = try values.decode([PracticeRecord].self, forKey: .records)
        trainingRecords = try values.decodeIfPresent([TrainingRecord].self, forKey: .trainingRecords) ?? []
    }

    public mutating func upsert(_ record: TrainingRecord) {
        if let index = trainingRecords.firstIndex(where: { $0.id == record.id }) {
            trainingRecords[index] = record
        } else {
            trainingRecords.insert(record, at: 0)
        }
    }

    public var calibration: [CalibrationSummary] {
        let attempts = records.sorted { $0.startedAt > $1.startedAt }.flatMap { $0.attempts.reversed() }
        let intervals = Set(attempts.map(\.interval)).sorted { $0.seconds < $1.seconds }
        return intervals.map { interval in
            CalibrationSummary(interval: interval, newestFirst: attempts.filter { $0.interval == interval })
        }
    }

    public mutating func upsert(_ record: PracticeRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
    }

    @discardableResult
    public mutating func markInterruptedSessions() -> Bool {
        var changed = false
        for index in records.indices where records[index].status == .active {
            records[index].status = .interrupted
            changed = true
        }
        for index in trainingRecords.indices where trainingRecords[index].status == .active {
            trainingRecords[index].status = .interrupted
            changed = true
        }
        return changed
    }

    public var completedAttempts: [Attempt] {
        records.flatMap(\.attempts)
    }
}
