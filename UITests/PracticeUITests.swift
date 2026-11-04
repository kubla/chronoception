import XCTest

@MainActor
final class PracticeUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launchFixture(attempts: Int = 1, interval: Int = 300, seed: String? = nil) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["CHRONOCEPTION_TEST_HISTORY"] = UUID().uuidString
        app.launchEnvironment["CHRONOCEPTION_TEST_INTERVAL"] = String(interval)
        app.launchEnvironment["CHRONOCEPTION_TEST_ATTEMPTS"] = String(attempts)
        app.launchEnvironment["CHRONOCEPTION_TEST_SEED_HISTORY"] = seed
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
        XCTAssertTrue(app.staticTexts["5 min calibration"].exists)
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
        launchFixture()
        tap("choose-interval")
        tap("interval-30")
        chooseThreeRepetitions()
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
        XCTAssertTrue(app.staticTexts["30s calibration"].exists)
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

    private func chooseThreeRepetitions() {
        #if os(watchOS)
            tap("choose-repetitions")
            tap("repetitions-3")
        #else
            app.segmentedControls["choose-repetitions"].buttons["3"].tap()
        #endif
    }

    func testCalibrationComparesIntervalsAndEarlierObservations() {
        let first: [String: Any] = [
            "id": UUID().uuidString, "startedAt": 0, "interval": 10, "plannedAttempts": 10,
            "attempts": (1...10).map { ["interval": 10, "elapsedSeconds": $0] },
            "status": "completed",
        ]
        let other: [String: Any] = [
            "id": UUID().uuidString, "startedAt": 1, "interval": 300, "plannedAttempts": 1,
            "attempts": [["interval": 300, "elapsedSeconds": 300]], "status": "completed",
        ]
        let data = try! JSONSerialization.data(withJSONObject: ["records": [other, first]])
        launchFixture(seed: String(data: data, encoding: .utf8)!)
        tap("open-history")
        let recent = app.staticTexts["Latest 5: 20.0% error"]
        for _ in 0..<5 where !recent.isHittable { app.swipeUp() }
        XCTAssertTrue(recent.exists)
        XCTAssertTrue(app.staticTexts["Previous 5: 70.0% error"].exists)
        let otherInterval = app.staticTexts["5 min calibration"]
        for _ in 0..<5 where !otherInterval.isHittable { app.swipeUp() }
        XCTAssertTrue(otherInterval.exists)
        XCTAssertTrue(app.staticTexts["Latest 1: 0.0% error"].exists)
        capture("Calibration comparison")
    }

    private func chooseTraining() {
        #if os(watchOS)
            tap("practice-mode")
        #else
            app.buttons["Train yourself"].tap()
        #endif
    }

    func testTrainingRepeatsAndPersistsWithoutCreatingEstimates() {
        launchFixture(interval: 2)
        chooseTraining()
        chooseThreeRepetitions()
        tap("begin-session")
        XCTAssertTrue(app.staticTexts["training-cues"].waitForExistence(timeout: 5))
        capture("Training running")
        XCTAssertTrue(app.staticTexts["training-finished"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["training-finished"].label, "Training complete")
        capture("Training complete")
        app.terminate()
        app.launch()
        tap("open-history")
        XCTAssertTrue(app.staticTexts["3 of 3 cued intervals"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["history-count"].label, "0 recorded attempts")
        capture("Training history")
    }

    func testTrainingCancellationRetainsNoInventedCues() {
        launchFixture()
        chooseTraining()
        tap("begin-session")
        tap("end-training")
        XCTAssertEqual(app.staticTexts["training-finished"].label, "Training ended")
        tap("open-history")
        XCTAssertTrue(app.staticTexts["0 of 1 cued intervals"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["history-count"].label, "0 recorded attempts")
        capture("Cancelled training")
    }

    func testTrainingRelaunchInterruptsInsteadOfCompleting() {
        launchFixture()
        chooseTraining()
        tap("begin-session")
        app.terminate()
        app.launch()
        tap("open-history")
        XCTAssertTrue(app.staticTexts["Interrupted"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 of 1 cued intervals"].exists)
        capture("Interrupted training")
    }

    #if os(iOS)
        func testPocketExperimentSchedulesAndCancelsSystemRequests() {
            launchFixture(attempts: 3)
            chooseTraining()
            tap("open-pocket-experiment")
            XCTAssertTrue(app.staticTexts["pocket-status"].waitForExistence(timeout: 5))
            tap("schedule-pocket-cues")
            let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if system.buttons["Allow"].waitForExistence(timeout: 5) { system.buttons["Allow"].tap() }
            let scheduled = NSPredicate(format: "label == %@", "3 cues pending")
            expectation(for: scheduled, evaluatedWith: app.staticTexts["pocket-status"])
            waitForExpectations(timeout: 10)
            capture("Pocket cues scheduled")
            tap("cancel-pocket-cues")
            let cancelled = NSPredicate(format: "label == %@", "No cues pending")
            expectation(for: cancelled, evaluatedWith: app.staticTexts["pocket-status"])
            waitForExpectations(timeout: 10)
            capture("Pocket cues cancelled")
        }
    #else
        func testQuietPracticeRejectsAWindowBeyondTheRuntimeLimit() {
            launchFixture(interval: 3601)
            chooseTraining()
            app.switches["quiet-training"].tap()
            tap("begin-session")
            XCTAssertTrue(app.staticTexts["training-configuration-message"].waitForExistence(timeout: 5))
            XCTAssertEqual(
                app.staticTexts["training-configuration-message"].label,
                "Quiet practice must fit within one hour.")
            capture("Quiet practice limit")
        }
    #endif

    private func tap(_ identifier: String) {
        let button = app.buttons.matching(identifier: identifier).firstMatch
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
        if name == "Ready" {
            #if os(watchOS)
                let title = app.navigationBars.staticTexts["Practice"].firstMatch
            #else
                let title = app.navigationBars.staticTexts["Chronoception"].firstMatch
            #endif
            XCTAssertTrue(title.exists)
            let frame = title.frame
            let viewport = app.frame
            let geometry = [
                "x": frame.minX / viewport.width, "y": frame.minY / viewport.height,
                "width": frame.width / viewport.width, "height": frame.height / viewport.height,
            ]
            let data = try! JSONEncoder().encode(geometry)
            let capture = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            capture.name = "Navigation title bounds"
            capture.lifetime = .keepAlways
            add(capture)
        }
    }
}
