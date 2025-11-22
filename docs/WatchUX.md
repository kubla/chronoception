# Chronoception – Watch UX & Interaction Design (v1)

This document defines the Apple Watch UX for Chronoception v1:

- Information architecture (screens and navigation)
- Shared components (interval picker, feedback, summaries)
- Mode flows (Challenge, Fear, Passive)
- Progress view
- Key edge-case behaviors

## 1. UX principles

1. **One glance, one decision**  
   At any point, a quick wrist raise should be enough to know what state you are in and what your next action is.

2. **Minimal cognitive load**  
   Especially for meditation use, UI should be simple and quiet. Numbers and labels are clear but not noisy.

3. **Hands-free / eyes-free friendly**  
   Challenge/Fear: one tap starts, one tap ends an attempt.  
   Passive: no taps after start; haptics only.

4. **Immediate feedback for learning**  
   Challenge/Fear must show clear feedback (early/late by how much) after every attempt.

5. **Respect the watch’s job**  
   Passive Mode runs in the background; the normal watch face stays visible.  
   Challenge/Fear temporarily take over the screen, but return you gracefully.

---

## 2. Information architecture

### 2.1 Top-level structure

Chronoception has four top-level “places”:

1. **Home** – quick start and mode selection  
2. **Session** – full-screen for Challenge/Fear; background for Passive  
3. **Progress** – lightweight summaries of performance by interval  
4. **Settings / Info** – minimal: Health logging status, Fear Mode sound info

For watchOS, this maps to a **stack of screens** starting from Home.

High-level navigation:

- From **Home**:
  - Start last-used session (big primary button)
  - Choose mode + interval + attempts
  - Open Progress
  - Open Settings/Info

- From **Session**:
  - Challenge/Fear: in-session full screen, then summary, then back to Home  
  - Passive: background, optionally a minimal status screen

### 2.2 Home screen layout

**Home screen elements (conceptual)**

- Top: app name
  - `Chronoception`
- Primary action:
  - Button: `Start Last Session`
  - Subtitle showing mode + interval, e.g. `Challenge · 5m 0s · 3 attempts`
- Secondary section: `Modes`
  - Row: `Challenge`
  - Row: `Fear`
  - Row: `Passive`
- Tertiary section:
  - Row: `Progress`
  - Row: `Settings & Info`

Interaction:

- Tapping `Start Last Session` takes you straight into the mode screen with previous configuration.
- Tapping a mode row (`Challenge`, `Fear`, `Passive`) takes you to that mode’s configuration screen.

---

## 3. Shared components

### 3.1 Interval picker UI

Used by all modes.

**Screen layout:**

- Title: `Interval`
- Picker:
  - Two wheels / pickers:
    - Minutes: `0–120`
    - Seconds: `0–59`
- Below the picker: list of **presets**, sorted by frecency:
  - `5m 0s (default)`
  - `3m 0s`
  - `10m 0s`
  - etc.
- Each preset is a single tap target that sets the picker.

**Behavior:**

- On screen load:
  - The picker shows the last-used interval for that mode (or 5m 0s by default).
  - Preset list shows all stored intervals sorted by frecency.
- Choosing a preset:
  - Updates the picker wheels.
- Adjusting the picker directly:
  - Immediately reflects the chosen minutes/seconds.
- On continue:
  - The chosen interval (from picker, not just the preset label) becomes `target_interval_seconds`.
  - If that interval is new, it is added to presets and incorporated into frecency.

### 3.2 Attempt feedback screen

Used by Challenge and Fear after each attempt.

**Trigger:** Immediately after the user taps to end an attempt.

**Layout:**

- Top line: outcome word
  - `Early` or `Late`
- Large center line: magnitude
  - Example: `5s` or `1m 12s`
- Optional small line:
  - `Target: 5m 0s`
- Background or accent color:
  - Indicates zone:
    - Green: abs_percent_error < 5%
    - Yellow: 5–15%
    - Red: ≥ 15%

**Behavior:**

- Shown for ~1–2 seconds or until the user taps.
- After dismissal:
  - If more attempts remain:
    - Move to “Ready for next attempt” state.
  - If last attempt:
    - Move to Session Summary.

This screen is also where Fear Mode may play the aversive sound (if threshold exceeded).

### 3.3 Session summary screen

After the last attempt (Challenge/Fear) or after Passive Mode ends.

**Challenge/Fear summary layout:**

- Heading: e.g., `Session summary`
- Key lines:
  - `Interval: 5m 0s`
  - `Attempts: 5`
- Metric lines:
  - `Avg error: 12s` (always display as absolute seconds, time-formatted)
  - `Bias: Late by 5s` (mean signed error)
  - `Time Acuity: 78/100`
- Small line:
  - `Logged to Health` or `Health logging off` depending on permission state

Actions:

- Primary button: `Done` (returns to Home)
- Secondary button: `Repeat` (restarts this configuration)

**Passive summary layout:**

- Heading: `Passive session ended`
- Key lines:
  - `Interval: 5m 0s`
  - `Repetitions: 6`
  - `Total: 30m 0s`
- Health line:
  - `Logged to Health` or `Health logging off`
- Actions:
  - Button: `Done`
  - Optional: `Repeat`

---

## 4. Challenge Mode UX

### 4.1 Configuration screen

Entry from Home → `Challenge`.

Elements:

- Title: `Challenge`
- Interval row:
  - Shows current interval, e.g. `Interval: 5m 0s`
  - Tapping opens the Interval Picker screen.
- Attempt count row:
  - `Attempts: 1` (default)
  - A simple picker or stepper to increase/decrease (1, 3, 5, 10, etc.).
- Optional info text (small):
  - `Tap when you think the interval has passed. See how early or late you were.`

Bottom:

- Primary button: `Start`

### 4.2 In-session – attempt screen

After `Start`:

- State: `AttemptRunning`
- Full-screen with:
  - Top: `Challenge`
  - Center: `Target: 5m 0s`
  - Bottom small text: `Attempt 1/5`
- No visible timer.

Interaction:

- User taps anywhere on the screen (the crystal) when they believe the interval has elapsed.
- App records `tap_i` and transitions immediately to Attempt Feedback.

### 4.3 Per-attempt feedback

As described in 3.2.

- Early vs Late, magnitude, optional target line.
- Optionally a small label for the error zone (`Great`, `OK`, `Way off`) mapped to the green/yellow/red zones.

### 4.4 Next attempt / end of session

After the feedback screen:

- If more attempts remain:
  - Screen: `Next attempt ready` with:
    - `Target: 5m 0s`
    - `Attempt 2/5`
    - Button: `Start next` or auto-start after a short delay.
- If no more attempts:
  - Transition to Session Summary.

### 4.5 Abort flow

- At any point in Challenge Mode:
  - A long press or an explicit “Cancel” button (for example at top left) opens a confirmation:
    - `Cancel session?`
    - Buttons: `Discard`, `Continue`
- If discarded:
  - Session is not logged to Health.
  - App returns to Home.

---

## 5. Fear Mode UX

Fear Mode largely reuses Challenge Mode UX with these differences:

### 5.1 Configuration screen

Entry from Home → `Fear`.

Same structure as Challenge, with an explanatory line:

- Title: `Fear Mode`
- Interval row: same as Challenge
- Attempts row: same as Challenge
- Extra info text:
  > If your estimate is off by more than 10%, Chronoception plays an unpleasant sound. This respects your system sound settings.

Below:

- If system audio is effectively disabled:
  - Show a warning banner:
    - `Sound is disabled. Fear Mode will behave like normal Challenge Mode.`
  - Optional toggle:
    - `Proceed anyway` / `Use Challenge instead`

### 5.2 In-session behavior

Identical to Challenge structurally:

- Full-screen target display.
- User taps to mark the interval.
- Attempt Feedback screen appears with numeric feedback.

Additional Fear Mode behavior:

- On the Attempt Feedback screen, if error ≥ 10%:
  - Play aversive sound (if `fear_sound_effective = true`).
- If `fear_sound_effective = false`, no sound is played; the numeric feedback is still shown.

---

## 6. Passive Training Mode UX

### 6.1 Configuration screen

Entry from Home → `Passive`.

Elements:

- Title: `Passive`
- Interval row:
  - `Interval: 5m 0s` (tap to open Interval Picker)
- Repetition row:
  - `Repetitions: 6` (range e.g. 1–24)
- Info text:
  > Chronoception will tap your wrist every interval. Use this while you walk, work, or meditate.

Bottom:

- Button: `Start`

### 6.2 Session start

On `Start`:

- App starts a background session.
- Brief confirmation screen:
  - `Passive session running`
  - `Interval: 5m 0s`
  - `Repetitions: 6`
  - Button: `End now`
- After a short delay, auto-return to watch face.

### 6.3 During Passive session

- The normal watch face is visible.
- At each interval boundary:
  - The watch emits the haptic pattern for the selected interval.
- If a Chronoception complication exists:
  - It may show a minimal status indicator (for example, a small dot or icon while a passive session is active).

User can:

- Open Chronoception during the session to see a minimal status screen:
  - `Passive session active`
  - `Next tap in ~4m`
  - Button: `End session`

### 6.4 End of session

- When the final repetition completes:
  - Haptic fires as usual.
  - Optionally a short local notification:
    - `Passive session ended. 30m 0s at 5m 0s intervals.`
  - Opening Chronoception after this goes directly to the Passive Session Summary screen.

---

## 7. Progress view UX

### 7.1 Entry

From Home → `Progress`.

### 7.2 Layout

Progress screen prioritizes “favorite intervals” by frecency:

- Title: `Progress`
- List of intervals (top 3–5 by frecency):
  - Row example:
    - `5m 0s`
    - Subtext: `Avg error: 12s (↓ from 18s)`  
  - `1m 0s`
    - Subtext: `Avg error: 4s (flat)`
- Each row is tappable.

### 7.3 Interval detail view

Tapping an interval row opens the interval detail:

- Title: `5m 0s`
- Key stats:
  - `Sessions: 12`
  - `Avg error (last 7 days): 12s`
  - `Avg error (prev 7 days): 18s`
  - `Time Acuity: 78/100`
- Simple trend indicator:
  - Text: `Improving` / `About the same` / `Worse`
- Optional strip chart (very simple):
  - For example, last N sessions as a row of dots in green/yellow/red colors.

Actions:

- Button: `Start Challenge` preconfigured to this interval.
- Button: `Start Passive` preconfigured to this interval.

---

## 8. Settings & Info UX

Entry from Home → `Settings & Info`.

Elements:

- Section: `Health logging`
  - Status line:
    - `Health logging: On` or `Off`
  - If off:
    - Small text: `Chronoception can log sessions as Mindfulness minutes in Apple Health. Enable in Settings > Health.`
- Section: `Fear Mode`
  - Line:
    - `Fear Mode sound: Enabled` or `Disabled by system`
  - If disabled:
    - Small text: `Your watch is in Silent or Focus mode. Fear Mode will behave like normal Challenge Mode.`
- Section: `About`
  - Short text explaining chronoception and links out as needed (e.g., website).

---

## 9. UX edge cases

### 9.1 Health permission not granted

- On first session completion when Health write fails:
  - Show small, non-blocking banner on summary:
    - `Could not log to Health (permission denied).`
- Do not nag the user repeatedly; a subtle indicator in Settings is sufficient.

### 9.2 Fear Mode with sound disabled mid-session

- If system audio becomes disabled after the session starts:
  - Fear Mode falls back to silently showing numeric feedback.
  - The session summary may display:
    - `Fear Mode sound was disabled during this session.`

### 9.3 App relaunched mid Passive session

- If Chronoception is opened while a Passive session is active:
  - Show Passive status screen:
    - `Passive session active`
    - `Interval: X`
    - `Repetitions done: k / N`
    - Button: `End session`

### 9.4 App relaunch after unexpected termination

- On launch, if local state indicates an incomplete session:
  - Show a small banner:
    - `Previous session ended unexpectedly.`  
  - Do not attempt to log that session to Health.

---

## 10. Microcopy guidelines

- Use simple, literal language.
- Always label intervals explicitly with `m` and `s`.
- When describing performance, prefer neutral tone over judgment:
  - `Early by 25s` instead of `Bad` or `You missed by a lot`.
- When describing Fear Mode, be explicit that it is **optional** and **respects system sound settings**.