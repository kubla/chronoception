# Chronoception iOS + watchOS v1 Technical Specification

This document translates the revised PRD in `.zenflow/tasks/new-task-02cc/requirements.md` and the existing watchOS‑first docs (`docs/PRD.md`, `docs/ModesAndMetrics.md`, `docs/HealthKitSpec.md`, `docs/WatchUX.md`) into a concrete technical plan for a combined iOS + watchOS v1 release.

The emphasis remains on the Watch experience; the iOS app improves discovery, onboarding, configuration, and reflection.

---

## 1. Technical context

### 1.1 Platforms, targets, and languages

- **Languages**
  - `Swift 5.x` for all production code.
  - `SwiftUI` for UI on both iOS and watchOS.
  - `Combine` for reactive bindings where useful (e.g., shared stores).
- **Minimum OS versions (subject to refinement)**
  - iOS: `iOS 17` or later.
  - watchOS: `watchOS 10` or later.
- **Targets / bundles**
  - `Chronoception` (iOS app target; primary App Store surface).
  - `ChronoceptionWatch` (watchOS app + extension, delivered as a companion to the iOS app).
  - `ChronoceptionShared` (Swift package or framework containing shared models, metrics, and services used by both apps).
- **Framework dependencies**
  - `SwiftUI` – UI layer and navigation.
  - `HealthKit` – writing Mindful Session entries and optionally reading app‑owned entries on iOS.
  - `WatchConnectivity` – syncing preferences and summary‑level session aggregates between Watch and iPhone.
  - `UserNotifications` – optional local reminders on iOS (if included in v1 scope per requirements).
  - `Foundation` / `Combine` – core types, async coordination.

### 1.2 Existing assets and how they are reused

- **Product & UX docs**  
  The existing docs remain the **primary source of truth** for:
  - Modes, metrics, and state machines (`docs/ModesAndMetrics.md`).
  - HealthKit fields, schemas, and permission flows (`docs/HealthKitSpec.md`).
  - Watch UX flows and screen content (`docs/WatchUX.md`).
  These are not re‑implemented from scratch; the implementation mirrors their definitions.

- **Web demo (`web-demo/`)**
  - Provides a working reference for:
    - Interval picker behavior and validation (min 10s).
    - Challenge/Fear session flow and feedback screens.
    - Passive mode haptic loop and repetition logic.
    - Metric computation (mean absolute error, Time Acuity Score).
  - Reuse plan:
    - Port state and metric logic to Swift in `ChronoceptionShared`, preserving naming where it improves clarity.
    - Use web demo as a behavior oracle for unit tests (matching scores, time formatting, and error classification).

- **HealthKit schemas**  
  - The existing v1 HealthKit spec is the baseline; iOS introduces no new HK types, only:
    - Same Mindful Session entries written from Watch.
    - Optional **read** of the app’s own Mindful Session entries on iOS to reconstruct historical summaries (v1.0 stretch or v1.1).

---

## 2. High‑level architecture

### 2.1 Layered overview

- **Presentation layer (SwiftUI)**
  - Watch:
    - Home, Mode config, Session, Feedback, Summary, Progress, and minimal Settings views as defined in `docs/WatchUX.md`.
  - iOS:
    - `Home` – Watch status, quick introduction, “Open on Watch” affordances.
    - `Learn` – Non‑interactive onboarding tour and persistent educational content.
    - `Progress` – Aggregated summaries from Watch sessions.
    - `Settings` – Health permission status, Watch status, defaults/preferences.

- **Domain & state layer (`ChronoceptionShared`)**
  - Mode and session models (Challenge, Fear, Passive).
  - Attempt and summary metrics (error, bias, Time Acuity Score).
  - Time formatting utilities (shared `formatDuration(interval:)` functions matching the spec).
  - Session stores:
    - On Watch: full‑fidelity session store for on‑device summaries.
    - On iOS: summary store for aggregates (synced from Watch).
  - Preference store:
    - Shared defaults for default mode, interval, and Fear Mode opt‑in.

- **Integration layer**
  - `HealthKitService`
    - Watch: writes Mindful Session entries with metadata defined in `docs/HealthKitSpec.md`.
    - iOS: reads permission state and optionally reads app‑owned Mindful Session entries.
  - `ConnectivityService` (WatchConnectivity)
    - Syncs summary‑level session data and preferences.
    - Abstracted behind protocol(s) for easy mocking in tests.
  - `SettingsService`
    - Wraps `UserDefaults` (with App Group for cross‑process sharing) for non‑HealthKit state.

### 2.2 Target responsibilities

- **Watch app (primary training surface)**
  - Owns **session execution** and **raw data** (attempt timing, per‑session metrics).
  - Writes HealthKit Mindful Session entries.
  - Provides immediate feedback, session summaries, and on‑watch Progress views.
  - Publishes **summary records** to iOS via WatchConnectivity when possible.

- **iOS app (companion / discovery)**
  - Drives App Store discovery with clear explanation and screenshots.
  - Hosts onboarding and education (“Chronoception 101”, mode explanations, FAQ).
  - Surfaces Watch status and installation guidance.
  - Shows read‑only summaries of training (aggregates and trends).
  - Allows configuration of defaults/preferences that are synced to Watch.
  - Does **not** run sessions or attempt to replace the Watch experience.

---

## 3. Source structure and modules

### 3.1 Proposed repository / project structure

At a high level (exact folder names may evolve within the Xcode project):

- `ChronoceptionShared/`
  - `Models/`
    - `Mode.swift` (enum: `challenge`, `fear`, `passive`).
    - `IntervalPreset.swift`.
    - `Attempt.swift`.
    - `SessionSummary.swift` (per session).
    - `AggregateMetrics.swift` (rollups for Progress views).
  - `Metrics/`
    - `TimeMetrics.swift` (mean error, bias, Time Acuity Score calculation, error zones).
    - `TimeFormatting.swift` (shared duration formatting rules).
  - `Services/`
    - `HealthKitService.swift`.
    - `ConnectivityService.swift`.
    - `SettingsService.swift`.
    - `SessionStore.swift` (protocol + in‑memory / persistent implementations).
  - `Specs/`
    - `LearnContent.swift` (static content derived from `docs/PRD.md`, etc.).

- `ChronoceptioniOS/`
  - `App/ChronoceptionApp.swift` (entry point).
  - `Screens/Home/` (Watch status, entry to Learn/Progress/Settings).
  - `Screens/Learn/` (onboarding tour + documentation views).
  - `Screens/Progress/` (aggregated metrics, charts if any).
  - `Screens/Settings/` (Health & Watch status, preferences).
  - `ViewModels/` (HomeViewModel, ProgressViewModel, SettingsViewModel).

- `ChronoceptionWatch/`
  - `App/ChronoceptionWatchApp.swift` (entry).
  - `Screens/Home/`.
  - `Screens/Config/` (interval and attempt/repetition configuration).
  - `Screens/Session/` (Challenge/Fear full screen, Passive status).
  - `Screens/Summary/`.
  - `Screens/Progress/`.
  - `Screens/Settings/`.
  - `ViewModels/` (Mode‑specific view models backed by shared domain model).

- `Tests/`
  - `SharedTests/` – metrics, formatting, session aggregation, HealthKit payloads.
  - `iOSTests/` – view model tests, connectivity handling.
  - `WatchTests/` – session flow and state machine tests (where feasible).
  - `UI Tests/` – targeted smoke tests for key flows on each platform.

### 3.2 Reuse of existing patterns

- The `web-demo/script.js` structure (one global `state`, small “setup” functions, centralized session logic) maps to:
  - Swift `ObservableObject` view models with published properties for mode, target interval, and session state.
  - Clearly separated “session engine” objects in `ChronoceptionShared` that encapsulate core logic and can be tested without UI.
- Time formatting helper `formatTime` becomes a shared `TimeFormatting` utility used in both apps so that displays match.
- Error zone logic (green < 5%, yellow 5–15%, red ≥ 15%) becomes part of `TimeMetrics.ErrorZone` and reused in watchOS feedback screens and iOS summaries.

---

## 4. Data model and APIs

### 4.1 Core domain types

- `enum Mode { case challenge, fear, passive }`
- `struct IntervalPreset`
  - `id: UUID`
  - `seconds: Int`
  - `label: String` (derived from formatting rules, e.g., `5m 0s`).
  - `frecencyWeight: Double` (for ranking).
- `struct Attempt`
  - `start: Date`
  - `end: Date`
  - `targetInterval: TimeInterval`
  - `elapsed: TimeInterval`
  - `signedError: TimeInterval`
  - `absError: TimeInterval`
  - `percentError: Double`
  - `isFearPenaltyTriggered: Bool`
- `struct Session`
  - `id: UUID`
  - `mode: Mode`
  - `interval: TimeInterval`
  - `attempts: [Attempt]` (for Challenge/Fear).
  - `repetitionCountPlanned: Int?` (Passive).
  - `repetitionCountCompleted: Int?` (Passive).
  - `start: Date`
  - `end: Date`
  - `metadata: [String: String]` (aligned with HealthKit spec).
- `struct SessionSummary`
  - `sessionId: UUID`
  - `mode: Mode`
  - `interval: TimeInterval`
  - `attemptCount: Int`
  - `meanAbsError: TimeInterval`
  - `bias: TimeInterval`
  - `timeAcuityScore: Int`
  - `createdAt: Date`

### 4.2 Metrics and progress

- `TimeMetrics` will:
  - Compute mean absolute error, signed bias, and Time Acuity Score from a sequence of `Attempt`s, using the formulae from `docs/ModesAndMetrics.md` and the web demo.
  - Classify each attempt and session into error zones (`.green`, `.yellow`, `.red`) using the 5%/15% thresholds.
  - Provide aggregate helpers used in Progress views:
    - `IntervalPerformanceSummary` (typical error and trend per target interval).
    - `ModeMixSummary` (fraction of sessions by mode).
    - Trend classification (`improving`, `flat`, `worsening`) based on recent windows (e.g., last N sessions or last 30 days).

### 4.3 Persistence

- **On Watch**
  - Lightweight persistence via:
    - `FileManager` writing JSON blobs per session, **or**
    - `CoreData` or `SQLite` if needed (decision made during implementation based on complexity).
  - Requirements:
    - Sessions must be durable for on‑watch Progress even if iPhone is unavailable.
    - Storage size is small; we can reasonably retain several hundred sessions locally.

- **On iOS**
  - Store only summary‑level data needed for aggregates:
    - `SessionSummary` records.
    - Derived aggregates cached for quick display.
  - Persistence backend:
    - `CoreData` or similar local store, to handle modest amounts of analytics data.

- **Settings and defaults**
  - Use `UserDefaults` with App Group for:
    - `defaultMode`.
    - `defaultIntervalSeconds`.
    - `fearModeEnabled` / opt‑in flag.
    - `hasSeenOnboarding` gating.

### 4.4 WatchConnectivity API

Define typed payloads for messages between Watch and iPhone, serialised as JSON dictionaries or `Codable` structs:

- **From Watch → iOS**
  - `SessionSummaryPayload`
    - Mirrors `SessionSummary` data.
    - Sent after each completed session or in batches when connectivity resumes.
  - `HealthStatusPayload` (optional)
    - Indicates Health write status and last error, if any.

- **From iOS → Watch**
  - `PreferencesPayload`
    - `defaultMode`, `defaultIntervalSeconds`, `fearModeEnabled`.
  - `ConfigRequest` (optional future)
    - For example, retrieving supported intervals from Watch if spec evolves.

Connectivity behavior:

- Watch is authoritative for session data; iOS treats incoming `SessionSummaryPayload`s as append‑only events.
- Preferences are **last‑writer‑wins** with iOS usually acting as the main author; Watch updates can also be sent if user changes settings on Watch.

### 4.5 HealthKit integration

- **Types and permissions**
  - Request **write** permission for `HKCategoryTypeIdentifier.mindfulSession` on both Watch and iOS (for consistency).
  - No other Health types in v1; no reads beyond potential app‑owned Mindful Sessions on iOS.

- **Write behavior (Watch)**
  - For each completed session:
    - Create a Mindful Session sample with:
      - Start and end times.
      - Metadata keys defined in `docs/HealthKitSpec.md` (mode, interval, attempts, metrics).
    - Writes are best‑effort; failures are logged but do not block user experience.

- **Read behavior (iOS)**
  - Baseline v1:
    - Use WatchConnectivity summary payloads as the primary data source.
  - Stretch / v1.1:
    - Scan Mindful Session entries tagged as Chronoception to reconstruct missing or historical data.
    - This logic belongs in a separate `HealthHistoryRebuilder` that can be enabled behind a flag.

---

## 5. Key flows and interface behavior

### 5.1 Watch flows (derived from `docs/WatchUX.md`)

- **Home**
  - Displays app name and a primary “Start Last Session” button.
  - Secondary mode list (Challenge, Fear, Passive).
  - Access to Progress and Settings.

- **Mode configuration**
  - Challenge / Fear:
    - Interval row → interval picker screen (minutes/seconds wheels + presets).
    - Attempt count picker/stepper.
  - Passive:
    - Same interval picker.
    - Repetition count picker.
  - Minimum interval validation (10 seconds) mirrors web demo behavior.

- **Session**
  - Challenge/Fear:
    - Single‑tap start.
    - Single‑tap stop for each attempt.
    - Feedback screen after each attempt:
      - “Early”/“Late”, magnitude, color zone, optional target line.
      - Fear Mode plays aversive sound when `abs(percentError) ≥ 10%`, respecting system audio settings.
    - Final session summary screen using metrics from `TimeMetrics`.
  - Passive:
    - Background haptic loop with minimal status screen.
    - Complies with watchOS background execution constraints (may use background tasks or notifications).
    - On completion or manual stop, summary screen with total duration and repetition count.

- **Progress**
  - Read‑only summaries:
    - Per interval: typical error and trend arrow / label.
    - Mode mix: proportion of sessions per mode.

### 5.2 iOS flows

- **Onboarding and first run**
  - On first launch:
    - Show a welcome screen: “Chronoception lives on your Apple Watch…”.
    - Guide through:
      - Installing the Watch app (with status and deep link).
      - Enabling Health write permissions (with explanation and link to Settings if declined).
  - Store completion in `hasSeenOnboarding` to avoid repeated prompts.

- **Home screen**
  - Cards for:
    - Watch status:
      - “Watch app installed” / “Not installed” / “Multiple watches”.
    - Health status:
      - `On` / `Off` / `Limited` with description.
    - Quick entry points to Learn and Progress.
  - If Watch is unavailable, home clearly states that full functionality requires a Watch but Learn is still usable.

- **Learn section**
  - Static content views backed by `LearnContent` in `ChronoceptionShared`.
  - Derived from existing docs; non‑interactive in v1.

- **Progress section**
  - Read‑only aggregates built from local `SessionSummary` records:
    - Interval performance list (interval, typical error, trend).
    - Mode breakdown chart or text.
  - Graceful empty‑state when few or no sessions exist.

- **Settings section**
  - Preferences:
    - Default mode.
    - Default interval preset.
    - Fear Mode opt‑in.
  - Status:
    - Health permission (with instructions to change in Settings).
    - Watch installation & connectivity status.

---

## 6. Delivery phases and milestones

### Phase 1 – Foundation and shared domain

- Create Xcode workspace with iOS + watchOS targets and `ChronoceptionShared` module.
- Implement core domain models (Mode, Interval, Attempt, Session, SessionSummary).
- Implement `TimeFormatting` and `TimeMetrics` with unit tests that mirror web demo behavior.
- Stub `HealthKitService`, `ConnectivityService`, and `SettingsService` interfaces (no full wiring yet).

### Phase 2 – Core watchOS session engine

- Build Watch home, configuration, and session screens using SwiftUI, adhering to `docs/WatchUX.md`.
- Implement session engine for Challenge/Fear:
  - Single‑tap start/stop cycle.
  - Per‑attempt feedback screen with error zones and Fear Mode audio.
  - Session summary screen with metrics.
- Implement Passive session engine:
  - Repetition‑based scheduling.
  - Summary at completion/stop.
- Wire Watch `SessionStore` persistence for session histories and on‑watch Progress.

### Phase 3 – HealthKit integration (Watch)

- Implement write flows for Mindful Sessions, metadata, and permission prompts per `docs/HealthKitSpec.md`.
- Handle permission denied/limited cases gracefully in UI and summaries.
- Add tests around metadata encoding and simple smoke tests through HealthKit mocks.

### Phase 4 – iOS app scaffolding and onboarding

- Implement iOS app shell:
  - Home, Learn, Progress, and Settings navigation structure.
- Implement Learn content screens backed by `LearnContent`.
- Implement onboarding sequence for first run, including Watch and Health permission education.
- Implement Watch status detection using WatchConnectivity / system APIs.

### Phase 5 – Connectivity and progress sync

- Implement `ConnectivityService` on both sides to:
  - Send `SessionSummaryPayload` from Watch to iOS.
  - Send `PreferencesPayload` from iOS to Watch.
- Implement iOS `SessionSummary` store and Progress view using synced data.
- Handle offline / delayed delivery cases with queueing and deduplication.

### Phase 6 – Preferences, settings, and polish

- Implement preference controls on iOS and mirror them on Watch.
- Implement Settings & Info view on Watch (Health status, Fear Mode info).
- Add optional iOS local reminders (if kept in v1 scope).
- Visual/interaction polish across both platforms (animations, haptics tuning, accessibility checks).

---

## 7. Verification and tooling

### 7.1 Testing strategy

- **Unit tests**
  - `TimeFormatting` and `TimeMetrics` against fixtures derived from web demo behavior.
  - Session engine logic for Challenge/Fear/Passive (successful runs, edge cases such as minimum interval).
  - HealthKit metadata encoding/decoding.
  - Connectivity payload encoding and decoding.

- **UI tests (selective)**
  - iOS:
    - Onboarding path including Health permission handling (simulated).
    - Navigation to Learn and Progress and basic rendering checks.
  - watchOS:
    - Happy‑path Challenge session (start → attempts → summary).

- **Integration / smoke tests**
  - Run app schemes on iOS Simulator and Watch Simulator for basic launch and navigation smoke tests.

### 7.2 Commands and automation

- **Build & test**
  - `xcodebuild -workspace Chronoception.xcworkspace -scheme Chronoception -destination 'platform=iOS Simulator,name=iPhone 16' test`
  - `xcodebuild -workspace Chronoception.xcworkspace -scheme ChronoceptionWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (45mm)' test`

- **Static analysis (optional but recommended)**
  - Integrate `swiftlint` with a project configuration.
  - Add CI steps:
    - `swiftlint` (lint only; no auto‑format in CI).
    - The `xcodebuild test` commands above.

### 7.3 Success checks per phase

- Phase 1: All foundation tests passing; metrics and formatting match spec.
- Phase 2–3: Watch app can run sessions and write appropriate HealthKit entries in a test environment.
- Phase 4: iOS app clearly communicates Watch‑first behavior and can complete onboarding.
- Phase 5: Sessions completed on Watch are reflected in iOS Progress with reasonable lag.
- Phase 6: Preferences sync correctly, and both apps behave sensibly in all described permission and connectivity states.

This technical specification is designed to fully realize the revised PRD for a Watch‑first experience with a supporting iOS app, while keeping scope constrained, testable, and aligned with the existing product documentation and web prototype.

