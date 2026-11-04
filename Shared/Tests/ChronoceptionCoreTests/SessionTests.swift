import ChronoceptionStorage
import Foundation
import XCTest

@testable import ChronoceptionCore

final class SessionTests: XCTestCase {
    func testEarlyLateAndExactFeedback() throws {
        let target = try XCTUnwrap(PracticeInterval(seconds: 300))
        XCTAssertEqual(try XCTUnwrap(Attempt(interval: target, elapsedSeconds: 270)).feedback, "30s early")
        XCTAssertEqual(try XCTUnwrap(Attempt(interval: target, elapsedSeconds: 330)).feedback, "30s late")
        XCTAssertEqual(try XCTUnwrap(Attempt(interval: target, elapsedSeconds: 300)).feedback, "On time")
        XCTAssertEqual(
            try XCTUnwrap(Attempt(interval: target, elapsedSeconds: 270)).absoluteErrorFraction, 0.1,
            accuracy: 1e-12)
    }

    func testSubsecondErrorIsNotReportedAsZero() throws {
        let result = try XCTUnwrap(Attempt(interval: .fiveMinutes, elapsedSeconds: 299.99))
        XCTAssertEqual(result.feedback, "<0.1s early")
    }

    func testIntervalValidationAndDecoding() throws {
        XCTAssertNil(PracticeInterval(seconds: 0))
        XCTAssertNil(PracticeInterval(seconds: -1))
        XCTAssertNil(SessionPlan(interval: .fiveMinutes, attemptCount: 0))
        XCTAssertThrowsError(try JSONDecoder().decode(PracticeInterval.self, from: Data("-1".utf8)))
        let interval = try XCTUnwrap(PracticeInterval(seconds: 65))
        XCTAssertEqual(interval.label, "1m 5s")
        XCTAssertEqual(
            try JSONDecoder().decode(PracticeInterval.self, from: JSONEncoder().encode(interval)), interval)
    }

    func testInvalidElapsedValuesAreRejected() {
        for value in [-1.0, .nan, .infinity, -.infinity] {
            XCTAssertNil(Attempt(interval: .fiveMinutes, elapsedSeconds: value))
        }
    }

    func testDuplicateTapResolvesOnlyOnce() {
        var engine = SessionEngine(plan: .singleFiveMinutes)
        engine.send(.start(at: .seconds(0)))
        engine.send(.estimate(at: .seconds(270)))
        let first = engine
        engine.send(.estimate(at: .seconds(271)))
        XCTAssertEqual(engine, first)
        XCTAssertEqual(engine.attempts.count, 1)
    }

    func testCancellationIsTerminalAndKeepsCompletedAttempts() throws {
        let plan = try XCTUnwrap(SessionPlan(interval: .fiveMinutes, attemptCount: 2))
        var engine = SessionEngine(plan: plan)
        engine.send(.start(at: .seconds(0)))
        engine.send(.estimate(at: .seconds(270)))
        engine.send(.advance(at: .seconds(280)))
        engine.send(.cancel)
        XCTAssertEqual(engine.phase, .cancelled)
        XCTAssertEqual(engine.attempts.count, 1)
        let cancelled = engine
        engine.send(.start(at: .seconds(300)))
        engine.send(.estimate(at: .seconds(600)))
        engine.send(.advance(at: .seconds(601)))
        XCTAssertEqual(engine, cancelled)
    }

    func testCompletionRequiresExplicitAdvance() {
        var engine = SessionEngine(plan: .singleFiveMinutes)
        engine.send(.start(at: .seconds(0)))
        engine.send(.estimate(at: .seconds(300)))
        XCTAssertNotEqual(engine.phase, .completed)
        engine.send(.advance(at: .seconds(301)))
        XCTAssertEqual(engine.phase, .completed)
        let completed = engine
        engine.send(.cancel)
        engine.send(.interrupt)
        engine.send(.start(at: .seconds(400)))
        XCTAssertEqual(engine, completed)
    }

    func testBackwardClockInterruptsWithoutInventingAResult() {
        var engine = SessionEngine(plan: .singleFiveMinutes)
        engine.send(.start(at: .seconds(30)))
        engine.send(.estimate(at: .seconds(10)))
        XCTAssertEqual(engine.phase, .interrupted)
        XCTAssertTrue(engine.attempts.isEmpty)
    }

    func testDrillRequiresThePlannedNumberOfAttempts() throws {
        let plan = try XCTUnwrap(SessionPlan(interval: .fiveMinutes, attemptCount: 3))
        var engine = SessionEngine(plan: plan)
        engine.send(.start(at: .zero))
        for index in 0..<3 {
            engine.send(.estimate(at: .seconds(index * 300 + 300)))
            XCTAssertEqual(engine.attempts.count, index + 1)
            engine.send(.advance(at: .seconds((index + 1) * 300)))
        }
        XCTAssertEqual(engine.phase, .completed)
    }

    func testGeneratedEventTracesPreserveInvariants() throws {
        let plan = try XCTUnwrap(SessionPlan(interval: .fiveMinutes, attemptCount: 3))
        var random: UInt64 = 0xC470
        for _ in 0..<1000 {
            var engine = SessionEngine(plan: plan)
            for tick in 0..<60 {
                random = random &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                let before = engine
                switch random % 5 {
                case 0: engine.send(.start(at: .seconds(tick)))
                case 1: engine.send(.estimate(at: .seconds(tick)))
                case 2: engine.send(.advance(at: .seconds(tick)))
                case 3: engine.send(.cancel)
                default: engine.send(.interrupt)
                }
                XCTAssertLessThanOrEqual(engine.attempts.count, plan.attemptCount)
                switch before.phase {
                case .completed, .cancelled, .interrupted: XCTAssertEqual(engine, before)
                default: break
                }
            }
        }
    }

    func testHistoryUpsertDoesNotDuplicateAndRecoversInterruptedWork() {
        let id = UUID()
        var record = PracticeRecord(id: id, startedAt: Date(), plan: .singleFiveMinutes)
        var history = PracticeHistory()
        history.upsert(record)
        record.attempts = [Attempt(interval: .fiveMinutes, elapsedSeconds: 270)].compactMap { $0 }
        history.upsert(record)
        XCTAssertEqual(history.records.count, 1)
        XCTAssertEqual(history.completedAttempts.count, 1)
        XCTAssertTrue(history.markInterruptedSessions())
        XCTAssertEqual(history.records[0].status, .interrupted)
        XCTAssertEqual(history.completedAttempts.count, 1)
        XCTAssertFalse(history.markInterruptedSessions())
    }

    func testPersistenceRoundTripAndCorruptionDoesNotBecomeEmptySuccess() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = HistoryRepository(url: directory.appendingPathComponent("history.json"))
        XCTAssertTrue(try repository.load().records.isEmpty)
        let record = PracticeRecord(id: UUID(), startedAt: Date(), plan: .singleFiveMinutes)
        let history = PracticeHistory(records: [record])
        try repository.save(history)
        XCTAssertEqual(try repository.load(), history)
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: repository.url)
        XCTAssertThrowsError(try repository.load())
        XCTAssertEqual(try Data(contentsOf: repository.url), corrupt)
    }
}
