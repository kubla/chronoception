import XCTest

@MainActor
final class PracticeUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launchFixture(attempts: Int = 1) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["CHRONOCEPTION_TEST_HISTORY"] = UUID().uuidString
        app.launchEnvironment["CHRONOCEPTION_TEST_INTERVAL"] = "300"
        app.launchEnvironment["CHRONOCEPTION_TEST_ATTEMPTS"] = String(attempts)
        let started = ContinuousClock.now
        app.launch()
        XCTAssertTrue(app.buttons["begin-session"].waitForExistence(timeout: 15))
        let elapsed = started.duration(to: ContinuousClock.now).components
        let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
        let timing = XCTAttachment(string: "launch_to_ready_seconds_including_automation=\(seconds)")
        timing.name = "Launch to ready (automation)"
        timing.lifetime = .keepAlways
        add(timing)
    }

    func testRealEstimateFeedbackAndHistorySurviveRelaunch() {
        launchFixture()
        capture("Ready")
        tap("begin-session")
        XCTAssertTrue(app.buttons["mark-estimate"].waitForExistence(timeout: 5))
        let labels = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(
            app.staticTexts.allElementsBoundByIndex.map { $0.label }, labels,
            "Estimating must not reveal a ticking clock.")
        capture("Estimating")
        tap("mark-estimate")
        let feedback = app.staticTexts["attempt-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains("early"), feedback.label)
        capture("Feedback")
        tap("advance-session")
        XCTAssertTrue(app.staticTexts["session-finished"].waitForExistence(timeout: 5))
        capture("Finished")
        app.terminate()
        app.launch()
        tap("open-history")
        XCTAssertTrue(app.staticTexts["history-count"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["history-count"].label, "1 recorded attempt")
        capture("Persisted history")
    }

    func testRelaunchInterruptsAnUnfinishedSession() {
        launchFixture()
        tap("begin-session")
        XCTAssertTrue(app.buttons["mark-estimate"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        tap("open-history")
        XCTAssertTrue(app.staticTexts["Interrupted"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Completed"].exists)
        capture("Interrupted history")
    }

    func testCancelDoesNotManufactureAnEstimate() {
        launchFixture()
        tap("begin-session")
        tap("end-session")
        XCTAssertEqual(app.staticTexts["session-finished"].label, "Session ended")
        tap("open-history")
        XCTAssertTrue(app.staticTexts["history-count"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["history-count"].label, "0 recorded attempts")
        capture("Cancelled history")
    }

    func testRepeatedPracticeRequiresEachEstimateAndExplicitAdvance() {
        launchFixture(attempts: 3)
        tap("begin-session")
        for index in 1...3 {
            tap("mark-estimate")
            XCTAssertTrue(app.staticTexts["attempt-feedback"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["advance-session"].label, index == 3 ? "Finish" : "Next attempt")
            tap("advance-session")
        }
        XCTAssertEqual(app.staticTexts["session-finished"].label, "Session complete")
        tap("open-history")
        XCTAssertTrue(app.staticTexts["history-count"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["history-count"].label, "3 recorded attempts")
        capture("Repeated practice history")
    }

    func testPrivacyIsAvailableWithoutStartingPractice() {
        launchFixture()
        tap("open-about")
        let privacy = app.staticTexts["privacy-summary"]
        for _ in 0..<5 where !privacy.exists { app.swipeUp() }
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        XCTAssertTrue(privacy.label.contains("stored locally"))
        capture("About and privacy")
    }

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<5 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable, identifier)
        button.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
