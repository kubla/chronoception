# Modes and Metrics Specification

This document defines the behavior of the three primary modes in Chronoception v1, as well as metric definitions, interval selection, and key edge cases.

- Challenge Mode  
- Fear Mode  
- Passive Training Mode  
- Interval picker  
- Metrics and scores

## 1. Shared interval picker

Chronoception uses a single canonical interval picker across all modes.

### 1.1 Behavior

- There is exactly one built in preset: **5m 0s**  
- Users can create **custom intervals** with minute and second resolution  
  - UI concept: two wheels, one for minutes (for example 0 through 120) and one for seconds (0 through 59)  
- Each custom interval that is used becomes a **preset** shown in the picker  
- Presets are displayed in **frecency** order  
  - A function of both frequency and recency of use  
  - Most used and most recent intervals rise toward the top

### 1.2 Constraints

- Minimum interval: product level minimum can be 10s  
- Maximum interval: no explicit product level cap, but engineering can set an upper bound if required by watchOS  
- All modes select their interval from this picker and the chosen interval is stored as `target_interval_seconds`

### 1.3 Time formatting rule

Anywhere the app displays a duration:

- If duration < 60 seconds: display `Ns`  
- If duration ≥ 60 seconds: display `Nm Ns`  

Examples:

- `45s`  
- `1m 5s`  
- `3m 0s`  
- `10m 30s`

Durations longer than 60 seconds are never shown as pure seconds.

## 2. Challenge Mode

### 2.1 Purpose

Challenge Mode measures and trains time sense by asking the user to tap when a chosen interval has elapsed, and by providing clear per attempt feedback and a session summary.

### 2.2 Configuration

Per session:

- `mode_type = "challenge"`  
- `target_interval_seconds` from shared picker  
- `attempt_count`  
  - Integer, default `1`  
  - Users may choose higher counts for drill like sessions

### 2.3 UI and interaction

- Challenge Mode uses **full screen UI** and takes over the watch crystal  
  - When a session is running the user interacts by tapping the screen  
- Basic flow:
  1. User selects mode and interval, and optionally adjusts attempt count  
  2. Screen shows target interval (for example `Target: 5m 0s`) and a start control  
  3. On start the first attempt begins and the app records the start time  
  4. During the attempt:
     - No elapsed timer is shown  
     - The screen may show the interval and attempt number (for example `Attempt 2 / 5`)  
  5. The user taps the crystal when they believe the interval has elapsed  

### 2.4 Per attempt feedback

Per attempt feedback is mandatory:

- Immediately after a tap, the app computes the error and shows a **feedback flash screen**  
- The feedback shows:
  - Whether the user was **early** or **late**  
  - The magnitude of the error, formatted per the time rule  
- Examples:
  - `Early by 5s`  
  - `Late by 1m 12s`

This feedback screen is:

- Visible for a short time (for example about 1 or 2 seconds), or  
- Dismissed by a tap

After feedback:

- If more attempts remain, the app prepares the next attempt and then starts it  
- If this was the last attempt, the app transitions to the session summary

### 2.5 Attempt and session lifecycle

Conceptual states:

- `Idle`  
- `ConfiguringSession`  
- `WaitingForStart`  
- `AttemptRunning`  
- `FeedbackFlash`  
- `SessionSummary`  
- `Aborted`  
- `Completed`

Aborted sessions:

- If the user cancels during configuration or during an attempt, the session is marked as aborted  
- Aborted sessions are not written to Health  
- v1 can choose to ignore aborted sessions for on watch statistics

### 2.6 Metrics

For each attempt `i`:

- T: `target_interval_seconds`  
- `start_i`: monotonic timestamp when attempt starts  
- `tap_i`: monotonic timestamp when user taps  

Derived:

- `elapsed_i = tap_i - start_i` (seconds)  
- `signed_error_i = elapsed_i - T` (seconds)  
  - Positive: user is late  
  - Negative: user is early  
- `abs_error_i = |signed_error_i|` (seconds)  
- `percent_error_i = signed_error_i / T`  
- `abs_percent_error_i = |percent_error_i|`

For a session with N attempts:

- `mean_abs_error_seconds = mean(abs_error_i)`  
- `mean_signed_error_seconds = mean(signed_error_i)`  
- `std_dev_error_seconds = standardDeviation(signed_error_i)`  
- `mean_abs_percent_error = mean(abs_percent_error_i)`

### 2.7 Time Acuity Score

Time Acuity Score is a simple, interpretable score between 0 and 100 driven by mean absolute percent error.

Let:

- `E = mean_abs_percent_error`  
- `E_full_scale = 0.50` (50 percent absolute error maps to score 0)

Compute:

- `acuity_raw = 1 - (E / E_full_scale)`  
- `acuity_clamped = max(0, min(1, acuity_raw))`  
- `TimeAcuityScore = round(100 * acuity_clamped)`

Examples:

- Mean absolute percent error 5 percent → score about 90  
- 10 percent → score about 80  
- 25 percent → score about 50  
- 50 percent or more → score 0

### 2.8 Error zones

Defined in terms of `abs_percent_error_i`:

- **Green zone**: `< 0.05` (less than 5 percent error)  
- **Yellow zone**: `0.05` to `< 0.15`  
- **Red zone**: `≥ 0.15`

These zones can be used for:

- Visual emphasis in per attempt feedback  
- Visual emphasis in summaries  
- Achievement thresholds

## 3. Fear Mode

### 3.1 Purpose

Fear Mode is a variant of Challenge Mode with aversive audio feedback when error exceeds a threshold. It is meant as an optional high arousal learning experiment.

### 3.2 Configuration

Per session:

- `mode_type = "fear"`  
- `target_interval_seconds` from shared picker  
- `attempt_count` (default 1)  
- `fear_threshold_percent = 0.10` (10 percent)  

### 3.3 UI and interaction

- Same full screen UI pattern as Challenge Mode  
- Per attempt flow is identical:
  - Attempt runs, user taps, feedback flash screen appears

### 3.4 Aversive audio behavior

For each attempt:

- Compute `abs_percent_error_i`  
- If `abs_percent_error_i ≥ fear_threshold_percent`:
  - Attempt is treated as a **failure** for Fear Mode  
  - The app plays a loud, annoying sound as allowed by watchOS  
- If `abs_percent_error_i < fear_threshold_percent`:
  - No sound is played

Visual and text feedback for error still appears as in Challenge Mode.

### 3.5 Sound disabled handling

Before starting a Fear Mode session:

- The app checks effective audio state:
  - Silent mode  
  - System focus modes or other relevant flags  
- If system sound will be suppressed, the app shows a clear warning:
  - Example: "Sound is disabled. Fear Mode will behave like normal Challenge Mode."  
- The user can choose to:
  - Proceed with this knowledge, or  
  - Back out and choose Challenge Mode instead

The app does not provide a special haptic fallback as a fear signal.

### 3.6 Logging and metadata

Fear Mode sessions are logged similarly to Challenge Mode but include extra metadata:

- `chronoception_mode = "fear"`  
- `fear_threshold_percent = 0.10`  
- `fear_sound_effective = true` when the system allowed sound  
- `fear_sound_effective = false` when sound was disabled by system settings  

Metrics such as errors and Time Acuity Score are computed exactly as in Challenge Mode.

## 4. Passive Training Mode

### 4.1 Purpose

Passive Training Mode provides repeated, labeled exposure to chosen intervals by delivering distinct haptic patterns at each interval boundary. It is designed to be compatible with everyday activity and with meditation practice, and it runs while the standard watch face remains visible.

### 4.2 Configuration

Per session:

- `mode_type = "passive"`  
- `target_interval_seconds` from shared picker  
- End condition:
  - v1 primary: `repetition_count` (integer, for example 3, 6, 12)  

Example:

- Interval `5m 0s`, repetition count `6` implies 30 minutes total duration.

### 4.3 Background behavior and watch face

- After the user starts a Passive session, Chronoception runs the session in an appropriate background mode  
- The ordinary watch face remains visible  
- At each interval boundary:
  - The app emits the haptic pattern associated with the selected interval  
- The user can end the session by:
  - Returning to the app and pressing an end control, or  
  - Using a complication entry point if provided by watchOS and the implementation

### 4.4 Haptic patterns

Each `target_interval_seconds` used by the user must map to a haptic pattern `H(I)` with these properties:

- Unique within the set of the user's commonly used intervals  
- Simple enough to be learned and distinguished  
- Not excessively long, especially for short intervals

The product level requirement is uniqueness and learnability, not a specific mapping. An implementation can define a vocabulary of short and long taps and compose patterns from that vocabulary.

If the user creates many custom intervals, some reuse of patterns may be acceptable, as long as the most frequently used intervals retain distinct patterns.

### 4.5 Logging

At the end of a Passive session, the app may write a Mindful Session with:

- `chronoception_mode = "passive"`  
- `target_interval_seconds`  
- `repetition_count`  
- `total_duration_seconds`  

There are no error metrics because Passive Mode does not involve taps.

## 5. Edge cases and special handling

### 5.1 Multiple taps in one attempt (Challenge and Fear)

- Only the first tap after an attempt starts is counted  
- Additional taps before the next attempt begins are ignored

### 5.2 Extremely early or late taps

- Any tap after the attempt start is accepted as the mark for that attempt  
- If the elapsed time is extremely short or extremely long relative to the target, the app still records the attempt and the large error  
- Implementations may optionally clamp outliers when summarizing errors, but raw values should be stored

### 5.3 App in background during attempts

- Challenge and Fear sessions should continue timing even if the screen sleeps or the user lowers their wrist  
- Implementation should use a monotonic clock to avoid issues with system time changes  
- If an attempt or session must time out for technical reasons, the app should fail gracefully and avoid writing partial or misleading data to Health

### 5.4 System time changes

- All attempt timing should use a monotonic time source  
- HealthKit start and end times can use wall clock time

### 5.5 Low battery or system interrupt

- If the watch powers off mid session, that session is effectively aborted  
- On next launch the app should discard incomplete session state and not write that session to Health

### 5.6 Passive sessions that end early

- If the user ends a Passive session before any interval boundary is reached, the session is treated as aborted and not written to Health  
- If at least one boundary has been reached, implementation may choose a minimum duration threshold for logging, such as the lesser of two intervals or 5 minutes