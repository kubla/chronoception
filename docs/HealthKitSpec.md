# HealthKit Integration Specification

Chronoception uses HealthKit to write Mindful Session entries for completed sessions. This document describes when entries are written, which metadata keys are used, and how permissions and failures are handled.

## 1. HealthKit types

- Chronoception writes `HKCategoryTypeIdentifier.mindfulSession` entries  
- v1 requests **write access only** for this type  
- No other HealthKit types are read or written in v1

Future versions may expand HealthKit usage, but v1 keeps the surface simple.

## 2. When entries are written

Chronoception writes **one** Mindful Session entry per completed session in these cases:

- Completed Challenge Mode session  
- Completed Fear Mode session  
- Completed Passive Mode session that meets a minimum duration requirement

Entries are **not** written when:

- The user cancels or aborts the session before completing any meaningful activity  
  - Challenge and Fear: no attempts completed  
  - Passive: no interval boundaries reached  
- A session fails in a way that makes the data clearly unreliable

The app should prefer to skip writing rather than log misleading data.

## 3. Session start and end times

For all modes:

- **Start time**:
  - For Challenge and Fear:
    - When the first attempt starts  
  - For Passive:
    - When the Passive session starts  
- **End time**:
  - When the session ends normally, which is:
    - After the summary screen appears for Challenge and Fear  
    - After the last interval boundary has fired or the user ends the session in Passive Mode

Start and end times in Health use wall clock time. Interval calculations inside the app should use a monotonic clock.

## 4. Metadata schema

Each Mindful Session entry has a set of metadata keys that describe the Chronoception session in a structured way.

### 4.1 Common keys

For all modes:

- `chronoception_version`: integer  
  - Example: `1`  
- `chronoception_mode`: string  
  - `"challenge"`, `"fear"`, or `"passive"`  

### 4.2 Challenge Mode metadata

For `chronoception_mode = "challenge"`:

- `target_interval_seconds`: integer  
- `attempt_count`: integer  
- `mean_abs_error_seconds`: float  
- `mean_signed_error_seconds`: float  
- `std_dev_error_seconds`: float  
- `mean_abs_percent_error`: float  
- `time_acuity_score`: integer 0 through 100  

The metrics are computed as defined in `ModesAndMetrics.md`.

### 4.3 Fear Mode metadata

For `chronoception_mode = "fear"` the metadata is the same as Challenge Mode, plus:

- `fear_threshold_percent`: float  
  - Default `0.10`  
- `fear_sound_effective`: boolean  
  - `true` if the app believes the aversive sound was actually played when triggered  
  - `false` if system audio settings prevented sound, and Fear Mode effectively behaved like Challenge Mode

### 4.4 Passive Mode metadata

For `chronoception_mode = "passive"`:

- `target_interval_seconds`: integer  
- `repetition_count`: integer  
- `total_duration_seconds`: integer  

There are no error metrics for Passive Mode because it does not involve user taps.

## 5. Permission handling

### 5.1 Requesting permission

On first run and whenever appropriate:

- The app requests **write access** to `HKCategoryTypeIdentifier.mindfulSession`  
- The app explains in clear language:
  - That it writes Mindful Session entries for completed sessions  
  - That it uses metadata to describe chronoception training  
  - That it does not read other health information in v1

Suggested user facing explanation:

> Chronoception logs your sessions to the Mindfulness section of Apple Health. This lets you see time sense training alongside your other mindfulness practice, and it makes it possible to analyze your time sense over days and weeks.

### 5.2 Permission denied

If the user denies write access:

- The app still functions normally:
  - Challenge, Fear, and Passive sessions still run  
  - On watch summaries still work  
- When a session completes:
  - The app does not write any Health entries  
- The app may show a subtle status indicator that Health logging is disabled, but should not nag the user

### 5.3 Permission revoked later

If write permission is revoked after initial grant:

- The next attempted write will fail  
- The app should:
  - Catch the error  
  - Stop trying to write until permission is explicitly re granted  
  - Optionally show a brief, unobtrusive message such as:
    - "Cannot write Mindfulness entries to Health. Check permissions if you want logging."

## 6. Error handling when writing

When writing to HealthKit:

- If the write succeeds:
  - Nothing special is needed  
- If the write fails:
  - The app must not crash  
  - The app should consider logging the failure internally for debugging  
  - The app may display a discreet message only if it can do so without disrupting the user

In all cases:

- A failed write should not prevent a session summary from displaying on the watch  
- On watch metrics should rely on local storage, not on HealthKit round trips

## 7. Local storage versus Health data

Chronoception tracks sessions in two places:

- Local storage on the watch  
  - Used for on watch progress summaries and convenience features such as frecency ordering of intervals  
- Apple Health Mindful Session entries  
  - Used for correlation with other health data and for external analysis

Design principles:

- Local storage is the primary source of truth for:
  - On watch progress views  
  - Interval frecency calculations  
- HealthKit entries are a secondary export channel:
  - They should be sufficient for a third party to reconstruct session level data  
  - They are not required for the app to function

If local and Health data ever diverge, local data controls on watch displays.

## 8. Future extensibility

The metadata schema includes `chronoception_version` so that future versions can evolve the schema without ambiguity.

Examples of future additions:

- Context tags such as `state: "meditating" | "walking" | "working"`  
- Per attempt summaries (for example a compressed representation)  
- Additional scores or derived metrics

Future versions should:

- Increment `chronoception_version` when adding or changing keys  
- Keep existing keys stable when possible  
- Add, rather than reuse, keys if semantics change