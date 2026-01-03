# Full SDD workflow

## Configuration
- **Artifacts Path**: {@artifacts_path} → `.zenflow/tasks/{task_id}`

---

## Workflow Steps

### [x] Step: Requirements
<!-- chat-id: e2d8ff6e-dec9-46e4-9156-80cb595ffaee -->

Create a Product Requirements Document (PRD) based on the feature description.

1. Review existing codebase to understand current architecture and patterns
2. Analyze the feature definition and identify unclear aspects
3. Ask the user for clarifications on aspects that significantly impact scope or user experience
4. Make reasonable decisions for minor details based on context and conventions
5. If user can't clarify, make a decision, state the assumption, and continue

Save the PRD to `{@artifacts_path}/requirements.md`.

### [x] Step: Technical Specification
<!-- chat-id: 75667a8d-09ae-4e9e-b0ba-fd34c9e052ce -->

Create a technical specification based on the PRD in `{@artifacts_path}/requirements.md`.

1. Review existing codebase architecture and identify reusable components
2. Define the implementation approach

Save to `{@artifacts_path}/spec.md` with:
- Technical context (language, dependencies)
- Implementation approach referencing existing code patterns
- Source code structure changes
- Data model / API / interface changes
- Delivery phases (incremental, testable milestones)
- Verification approach using project lint/test commands

### [x] Step: Planning
<!-- chat-id: 852302c4-aefa-475d-a4b7-5cb47dc1840d -->

Create a detailed implementation plan based on `{@artifacts_path}/spec.md`.

1. Break down the work into concrete tasks
2. Each task should reference relevant contracts and include verification steps
3. Replace the Implementation step below with the planned tasks

Rule of thumb for step size: each step should represent a coherent unit of work (e.g., implement a component, add an API endpoint, write tests for a module). Avoid steps that are too granular (single function) or too broad (entire feature).

If the feature is trivial and doesn't warrant full specification, update this workflow to remove unnecessary steps and explain the reasoning to the user.

Save to `{@artifacts_path}/plan.md`.

### [ ] Step: Implementation

Implement the work described in `.zenflow/tasks/new-task-02cc/spec.md` by completing the tasks below, in order. Each step includes explicit verification guidance.

#### [ ] Step: Repo hygiene and Xcode scaffolding

- Create an Xcode workspace and two app targets:
  - `Chronoception` (iOS)
  - `ChronoceptionWatch` (watchOS)
- Create a shared module `ChronoceptionShared` (Swift Package or framework target) referenced by both apps.
- Add baseline CI-friendly build scripts (Makefile or scripts folder) to run `xcodebuild` for iOS and watchOS schemes.

Verification:
- `xcodebuild -list -workspace Chronoception.xcworkspace`
- `xcodebuild -workspace Chronoception.xcworkspace -scheme Chronoception -destination 'platform=iOS Simulator,name=iPhone 16' build`
- `xcodebuild -workspace Chronoception.xcworkspace -scheme ChronoceptionWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (45mm)' build`

#### [ ] Step: Shared domain models and utilities (ChronoceptionShared)

Implement the core data types and shared utilities defined in `.zenflow/tasks/new-task-02cc/spec.md`:

- Models: `Mode`, `IntervalPreset`, `Attempt`, `Session`, `SessionSummary`, aggregate types needed for Progress.
- Utilities: `TimeFormatting` implementing duration formatting rules from `docs/PRD.md`.

Verification:
- Add `XCTest` unit tests for time formatting rules (e.g., `45s`, `1m 5s`, `3m 0s`).
- `xcodebuild ... test` for the shared test suite.

#### [ ] Step: Metrics engine parity with web demo

Implement `TimeMetrics` (mean abs error, bias, Time Acuity Score, error zones) in `ChronoceptionShared`.

- Mirror thresholds and definitions from `docs/ModesAndMetrics.md`.
- Validate parity against `web-demo/script.js` by creating fixtures that match web demo outputs for known attempts.

Verification:
- Unit tests covering:
  - Error zone classification (green < 5%, yellow 5–15%, red ≥ 15%).
  - Score computation for representative sessions.
- Run shared tests.

#### [ ] Step: Watch session engines (Challenge/Fear/Passive)

Build the watchOS session execution layer (non-UI logic) as testable engines in `ChronoceptionShared` or `ChronoceptionWatch`:

- Challenge/Fear session state machine: start → attempt cycle → per-attempt feedback → summary.
- Fear Mode penalty trigger behavior per spec.
- Passive mode repetition scheduling and completion logic within watchOS constraints.

Verification:
- Unit tests for state transitions and edge cases (min interval = 10s, cancel/stop flows, repetition counts).

#### [ ] Step: Watch SwiftUI screens (watch-first UX)

Implement watchOS UI per `docs/WatchUX.md`:

- Home, Mode config (interval picker + attempt/repetition selection), Session, Feedback, Summary, Progress, Settings.
- Validate minimum interval and display formatting.

Verification:
- Manual smoke test in Watch Simulator:
  - Complete 1 Challenge session with 3 attempts.
  - Start/stop Passive mode.
- (Optional) watchOS UI test for happy-path Challenge.

#### [ ] Step: Watch persistence (SessionStore)

Implement durable on-watch session history storage:

- `SessionStore` protocol + JSON file-backed implementation (default per spec).
- Indexing sufficient for Progress summaries.

Verification:
- Unit test round-trip encode/decode for sessions and summaries.
- Manual: sessions persist across watch app relaunch.

#### [ ] Step: HealthKit write integration on Watch

Implement `HealthKitService` on watchOS as described in `docs/HealthKitSpec.md`:

- Permission request flow for Mindful Session write.
- Write Mindful Session samples per completed session with metadata keys.
- Graceful behavior when permission denied.

Verification:
- Add tests around metadata dictionary construction.
- Manual smoke test on simulator/device (where possible): create a session and confirm a Mindful Session entry appears (device recommended).

#### [ ] Step: iOS app scaffolding (discovery + companion)

Implement an iOS SwiftUI app that improves discovery and supports the Watch-first experience:

- Tab or navigation structure: Home, Learn, Progress, Settings.
- Onboarding: explains Watch-first nature, helps install watch app, explains Health permissions.
- Learn: static content from `LearnContent` (derived from docs), non-interactive.

Verification:
- Manual smoke test in iOS Simulator: onboarding → Home → Learn → Settings.

#### [ ] Step: WatchConnectivity sync (summaries + preferences)

Implement `ConnectivityService` on both platforms:

- Watch → iOS: send `SessionSummaryPayload` after session completion; maintain bounded outbox and flush on reachability.
- iOS → Watch: send `PreferencesPayload` (default mode/interval, Fear opt-in); last-writer-wins.
- Idempotency: upsert by `sessionId` on iOS.

Verification:
- Unit tests for payload encoding/decoding.
- Manual: run paired simulators and confirm:
  - Completing a watch session adds a summary on iOS.
  - Changing preferences on iOS updates the watch defaults.

#### [ ] Step: iOS persistence and Progress UI

Implement iOS persistence for `SessionSummary` (CoreData per spec) and render Progress:

- Interval performance list (typical error, trend).
- Mode mix summary.
- Empty states.

Verification:
- Unit tests for aggregate computations.
- Manual: inject sample summaries (debug menu or preview) to validate UI states.

#### [ ] Step: Settings, accessibility, and polish

- iOS Settings: default mode/interval, Fear opt-in, Health status guidance, Watch status.
- Watch Settings: mirror key preferences and show Health status.
- Accessibility: Dynamic Type (iOS), VoiceOver labels, sufficient contrast.

Verification:
- Manual accessibility checks in simulators.

#### [ ] Step: Release readiness

- App Store assets plan: iPhone screenshots that explain Watch-first value; watch screenshots.
- Add privacy details (HealthKit usage description strings) and permission rationale copy.
- Add lightweight analytics-free logging for debug builds (optional).
- Ensure no crash on missing permissions / no watch pairing.

Verification:
- `xcodebuild ... test` for iOS + watchOS.
- Manual end-to-end smoke test: fresh install → onboarding → run watch session → see iOS progress update.
