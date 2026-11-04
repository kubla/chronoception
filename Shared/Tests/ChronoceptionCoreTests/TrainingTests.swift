import ChronoceptionCore
import Foundation
import XCTest

final class TrainingTests: XCTestCase {
    private let plan = SessionPlan(interval: PracticeInterval(seconds: 1)!, attemptCount: 3)!

    func testTrainingCuesRepeatAtFixedBoundariesWithoutEstimates() {
        var engine = TrainingEngine(plan: plan)
        engine.send(.start(at: .seconds(10)))
        engine.send(.pulse(at: .milliseconds(10999)))
        XCTAssertEqual(engine.completedIntervals, 0)
        engine.send(.pulse(at: .milliseconds(11100)))
        XCTAssertEqual(engine.completedIntervals, 1)
        XCTAssertEqual(engine.phase, .training(nextCue: .seconds(12)))
        engine.send(.pulse(at: .milliseconds(11100)))
        XCTAssertEqual(engine.completedIntervals, 1)
        engine.send(.pulse(at: .seconds(12)))
        engine.send(.pulse(at: .seconds(13)))
        XCTAssertEqual(engine.phase, .completed)
        engine.send(.pulse(at: .seconds(14)))
        XCTAssertEqual(engine.completedIntervals, 3)
    }

    func testRuntimeFailureBeforeTheStartCueInterruptsWithoutObservations() {
        var engine = TrainingEngine(plan: plan)
        engine.send(.interrupt)
        XCTAssertEqual(engine.phase, .interrupted)
        XCTAssertEqual(engine.completedIntervals, 0)
        engine.send(.start(at: .zero))
        XCTAssertEqual(engine.phase, .interrupted)
    }

    func testDelayedTrainingInterruptsRatherThanInventingMissedCues() {
        var engine = TrainingEngine(plan: plan)
        engine.send(.start(at: .zero))
        engine.send(.pulse(at: .seconds(3)))
        XCTAssertEqual(engine.phase, .interrupted)
        XCTAssertEqual(engine.completedIntervals, 0)
        engine.send(.pulse(at: .seconds(4)))
        XCTAssertEqual(engine.completedIntervals, 0)
    }

    func testCancelledTrainingAndInterruptionRetainOnlyActualCues() {
        for event in [TrainingEngine.Event.cancel, .interrupt] {
            var engine = TrainingEngine(plan: plan)
            engine.send(.start(at: .zero))
            engine.send(.pulse(at: .seconds(1)))
            engine.send(event)
            engine.send(.pulse(at: .seconds(2)))
            XCTAssertEqual(engine.completedIntervals, 1)
            XCTAssertEqual(engine.phase, event.isCancellation ? .cancelled : .interrupted)
        }
    }

    func testTrainingHistorySurvivesCodingWithoutChangingEstimateStatistics() throws {
        var history = PracticeHistory()
        var training = TrainingRecord(id: UUID(), startedAt: Date(), plan: plan)
        training.completedIntervals = 2
        history.upsert(training)
        training.status = .cancelled
        history.upsert(training)
        let decoded = try JSONDecoder().decode(PracticeHistory.self, from: JSONEncoder().encode(history))
        XCTAssertEqual(decoded.trainingRecords, [training])
        XCTAssertTrue(decoded.completedAttempts.isEmpty)
        XCTAssertTrue(decoded.calibration.isEmpty)
        var interrupted = history
        training.status = .active
        interrupted.upsert(training)
        XCTAssertTrue(interrupted.markInterruptedSessions())
        XCTAssertEqual(interrupted.trainingRecords[0].status, .interrupted)
        XCTAssertFalse(interrupted.markInterruptedSessions())
    }

    func testOldHistoryStillLoads() throws {
        let old = Data("{\"records\":[]}".utf8)
        XCTAssertTrue(try JSONDecoder().decode(PracticeHistory.self, from: old).trainingRecords.isEmpty)
    }

    func testCalibrationSeparatesIntervalsAndComparesChronologicalSamples() {
        let interval = PracticeInterval(seconds: 10)!
        let plan = SessionPlan(interval: interval, attemptCount: 10)!
        let attempts = (1...10).map { Attempt(interval: interval, elapsedSeconds: Double($0))! }
        let record = PracticeRecord(id: UUID(), startedAt: Date(), plan: plan, attempts: attempts)
        let other = PracticeRecord(
            id: UUID(), startedAt: Date(), plan: .singleFiveMinutes,
            attempts: [Attempt(interval: .fiveMinutes, elapsedSeconds: 300)!])
        let summary = PracticeHistory(records: [other, record]).calibration
        XCTAssertEqual(summary.map(\.interval.seconds), [10, 300])
        XCTAssertEqual(summary[0].recentErrorPercent, 20, accuracy: 0.001)
        XCTAssertEqual(summary[0].previousErrorPercent!, 70, accuracy: 0.001)
        XCTAssertNil(summary[1].previousErrorPercent)
    }
}

extension TrainingEngine.Event {
    fileprivate var isCancellation: Bool {
        if case .cancel = self { return true }
        return false
    }
}
