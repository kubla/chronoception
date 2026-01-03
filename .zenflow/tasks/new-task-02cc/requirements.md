# Chronoception iOS + watchOS v1 PRD (Revised)

## 1. Product overview

Chronoception is a time‑perception training app centered on Apple Watch, with an iPhone companion app that improves discovery, onboarding, configuration, and reflection. The core value is unchanged: measure and train chronoception (sense of elapsed time) through short challenge sessions, high‑arousal experiments, and passive haptic drills, and log training to Apple Health as Mindful Sessions with rich metadata.

This revision expands the original watchOS‑only v1 vision into a **paired iOS + watchOS experience** while keeping the **on‑wrist experience primary**:

- The **Watch app** is where all active training happens (Challenge, Fear, Passive, on‑watch Progress).
- The **iOS app** exists to:
  - Improve **App Store discoverability** and explain the concept of chronoception.
  - Make **onboarding and permissions** (especially HealthKit) clearer.
  - Provide **optional richer summaries** and configuration for power users without undermining the lightweight on‑watch UX.

## 2. Goals and non‑goals for the combined iOS + watchOS v1

### 2.1 Product goals

1. **Keep Watch as the primary training surface**
   - Maintain all existing v1 goals for watchOS:
     - Challenge Mode, Fear Mode, Passive Mode.
     - On‑watch progress feedback and quick session flows.
     - HealthKit logging for analysis.

2. **Improve discovery and understanding via iOS**
   - Present a clear, friendly explanation of chronoception, modes, and ideal use cases in the iOS app.
   - Make it obvious from the App Store listing and first‑run iOS experience that this is a **Watch‑first app**.
   - Provide clear instructions to install and enable the Watch app.

3. **Smooth onboarding and permissions management**
   - Offer an iOS onboarding flow that:
     - Introduces the concept and value of chronoception.
     - Guides users through enabling Health write permissions (Mindful Session), explaining data usage.
     - Surfaces Watch installation status and, where possible, deep‑links to Watch app install/management.

4. **Optional deeper insight and configuration on iOS**
   - Provide a **lightweight iOS “lab notebook”**:
     - Higher‑level summaries of Watch‑recorded sessions (aggregated over days/weeks).
     - Read‑only views of progress per interval and mode (based on local sync or Health data).
   - Allow users to review definitions of modes, metrics, and microcopy so they understand what they see on Watch.
   - Allow basic preference configuration that syncs to Watch (for example default interval and mode, Fear Mode opt‑in).

5. **Maintain privacy and simplicity**
   - Still no cloud backend or accounts in v1.
   - All data stored locally and/or in Apple Health.

### 2.2 Non‑goals (revised)

The following remain out of scope for v1, even with the new iOS app:

- No cross‑device accounts or cloud backup/sync.
- No social features, leaderboards, or remote sharing.
- No heavy iOS analytics dashboards with arbitrary filtering; iOS surfaces curated, opinionated summaries only.
- No additional HealthKit reads beyond what is already contemplated (Mindful Session write only in v1).
- No use of iOS as a general productivity timer app (the focus remains chronoception training).
- No medical or clinical positioning; still a training and self‑experiment tool, not a diagnostic.

## 3. Platforms and form factors

### 3.1 watchOS app (primary)

The Watch app remains the operational core of Chronoception:

- **Modes**:
  - Challenge Mode.
  - Fear Mode (optional high‑arousal variant).
  - Passive Training Mode.
- **Core flows**:
  - Interval picker shared by all modes.
  - Session configuration and execution.
  - On‑watch progress view by interval.
  - Settings & Info for Health logging and Fear Mode behavior.
- **Data**:
  - Local watch storage for on‑device summaries and frecency.
  - HealthKit Mindful Session writes with detailed metadata.

Existing documents `docs/PRD.md`, `docs/ModesAndMetrics.md`, `docs/HealthKitSpec.md`, and `docs/WatchUX.md` continue to fully specify the watchOS v1 behavior and remain the source of truth for Watch UX and logic.

### 3.2 iOS companion app (new)

The iOS app is a universal iPhone app paired with the Watch app in an **Apple Watch–centric bundle**:

- **Primary roles**:
  - Improve App Store and in‑app messaging about the Watch experience.
  - Provide a first‑run narrative that is difficult to express on the Watch alone.
  - Offer optional, non‑essential views of Watch‑generated data.
  - Provide centralized Health permission education and status.

- **Key design principles**:
  - iOS must **not** become the default session surface; iOS is for understanding, configuration, and reflection.
  - Any analytical views must be **summary‑level** and avoid overwhelming users with charts.
  - The iOS app must remain useful even if Health permissions are off (e.g., conceptual/educational content).

## 4. Users and jobs‑to‑be‑done (with iOS context)

The two primary ICPs from the existing PRD still apply; iOS adds new jobs around discovery, explanation, and reflection.

### 4.1 Quantified self enthusiast

New/expanded jobs via iOS:

- Discover Chronoception in the iOS App Store, understand immediately that it is a **Watch‑based chronoception trainer**, not a generic timer.
- Read a concise explanation of:
  - Modes (Challenge, Fear, Passive).
  - Metrics (error, bias, Time Acuity).
  - Health logging semantics.
- Review **higher‑level trends** (per interval, per mode) with slightly more detail than what fits on the Watch.
- Confirm Health logging is active and see what types of data are written.

### 4.2 Meditation practitioner

New/expanded jobs via iOS:

- Discover the app as a way to meditate on time as a sense gate.
- Understand the **relationship between meditation practice and chronoception training** through narrative content (e.g., short guided text).
- Learn recommended practices:
  - How to weave Passive sessions into daily or weekly sits.
  - When to run Challenge vs Passive sessions.
- Occasionally review **gentle progress summaries** that reinforce practice without gamifying it.

## 5. Core feature set across platforms

### 5.1 Watch features (unchanged in scope)

Summarized from existing docs:

- Shared interval picker with frecency‑ordered presets.
- Challenge Mode.
- Fear Mode (with threshold and sound behavior).
- Passive Training Mode with background haptics.
- On‑watch progress view with interval‑level summaries.
- HealthKit Mindful Session logging with structured metadata.

### 5.2 New iOS features

1. **App Store–friendly landing and first run**
   - Clear App Store screenshots and text that:
     - Highlight the Watch experience (session screens, haptics, progress).
     - Show a minimal iOS companion UI.
   - First‑run iOS screen:
     - “Chronoception lives on your Apple Watch. This app helps you install it, understand it, and review your practice.”

2. **Onboarding and education**
   - A short, non‑interactive onboarding “tour” within the iOS app:
     - What chronoception is.
     - How Challenge, Fear, and Passive modes work at a high level.
     - Basic guidance for each ICP (QS and meditation practitioner).
   - A persistent “Learn” section with:
     - High‑level summaries derived from `docs/PRD.md`, `docs/ModesAndMetrics.md`, and `docs/WatchUX.md`.
     - FAQ on Health data, privacy, and technical behavior (drawing from `docs/HealthKitSpec.md`).

3. **Watch installation and status**
   - iOS home screen should:
     - Detect whether the Watch app is installed (using standard watchOS companion APIs where available).
     - Show current status: `Watch app installed` / `Not installed` / `Multiple watches`.
     - Provide a one‑tap path to install/manage the Watch app (e.g., via deep‑link to Watch app management).
   - If Watch is unavailable, the app explains that **full functionality requires an Apple Watch** but users can still read content.

4. **Health permission and status surface**
   - A dedicated card or section:
     - Shows whether Health write permission for Mindful Session is granted.
     - Provides clear explanation of what is written and why.
     - Links to the system settings to adjust permission.
   - If permission is denied:
     - Explain that the Watch app still works, but external analysis is limited.

5. **Read‑only training summaries on iOS**
   - A simple “Progress” section on iOS that mirrors and slightly extends the Watch’s Progress view:
     - Interval list with typical error and trend (e.g., improving/flat/worse).
     - Mode breakdown: fraction of sessions in Challenge vs Fear vs Passive.
   - Data source:
     - Primary: shared local store via Watch connectivity (assumption; see below).
     - Secondary/fallback (stretch for v1): derived from Health Mindful Session entries where possible.
   - Constraints:
     - No full‑fidelity per‑attempt playback or complex charting in v1.

6. **Preferences and defaults**
   - Simple iOS settings that write preferences into a shared store and sync to Watch:
     - Default mode (Challenge/Fear/Passive) for “quick start” on Watch.
     - Default interval preset (e.g., `5m 0s`).
     - Fear Mode opt‑in / default threshold.
   - Watch app remains the authority for in‑session behavior and immediate configuration; iOS settings are convenience defaults.

## 6. Constraints and assumptions (extended)

### 6.1 Technical constraints

- **Bundle structure**: Chronoception ships as an iOS app that includes a watchOS app target. Users discover the app primarily via the iOS App Store.
- **Connectivity**:
  - Watch connectivity is available for exchanging small amounts of data between iPhone and Watch.
  - Data exchange will be limited to preferences and summary‑level session aggregates in v1.
- **HealthKit**:
  - As in the existing spec, v1 **writes** Mindful Session entries and does not read other health data.
  - iOS may read back the app’s own Mindful Session entries if needed for progress views (implementation detail to be confirmed in the technical spec).

### 6.2 UX constraints

- The Watch app must remain fully usable without ever opening the iOS app after initial installation (once the Watch app is installed and permissions are set).
- iOS must be usable for learning and basic progress review even if:
  - Health permissions are denied, or
  - The user has not yet run many sessions.
- All durations, intervals, and metrics presented on iOS must use the same time‑formatting rules and terminology as the Watch app.

### 6.3 Discovery and messaging assumptions

- Many users will encounter Chronoception via iOS App Store search (e.g., “meditation”, “mindfulness”, “focus”, “timer”, “Apple Watch”).
- Screenshots and iOS UI must make it obvious that:
  - The **core experience** is on Apple Watch.
  - The iOS app is a companion for understanding and reviewing practice.
- The bundle name, subtitle, and description will explicitly mention “Apple Watch” and “time perception” / “chronoception training.”

## 7. v1 success criteria (high level)

- **Adoption**:
  - A meaningful portion of iOS installs lead to Watch app installs (to be quantified later).
  - First‑time users successfully complete at least one Challenge session within a short window after installation.

- **Understanding**:
  - Users report understanding what the app does and what “chronoception” means, based on iOS onboarding and Learn content.

- **Engagement**:
  - A significant subset of users run multiple sessions per week, tracked through local analytics (if implemented) or inferred from session counts.

- **Data quality**:
  - HealthKit Mindful Session entries remain well‑structured and sufficient for off‑device analysis, unaffected by the introduction of iOS.

## 8. Open questions and assumptions

To keep implementation moving, we make the following explicit assumptions to be refined during technical design:

1. **Data sync model**
   - Assumption: v1 uses **Watch connectivity with a simple local session summary store** as the primary source for iOS progress views.
   - Alternative: derive summaries by reading HealthKit Mindful Session entries on iOS; this may be treated as a stretch or v1.1 capability.

2. **Depth of iOS analytics**
   - Assumption: iOS shows **only aggregate metrics** already defined in `docs/ModesAndMetrics.md` (e.g., mean absolute error, Time Acuity Score) aggregated over time windows; no custom multivariate analyses.

3. **Offline / phone‑free behavior**
   - Watch app must work fully without the phone present, as in the existing v1 spec. iOS features that require connectivity (e.g., progress sync) are explicitly secondary and may lag behind.

4. **Localization**
   - Assumption: v1 is English‑only; localization is out of scope.

5. **Notification strategy**
   - Assumption: iOS will not initiate complex push‑based coaching. At most, it may provide optional, low‑frequency local reminders (e.g., “Try a 5m Challenge today”) if included in the technical spec.

These assumptions will be revisited in the technical specification, where feasibility and scope cuts will be finalized.

