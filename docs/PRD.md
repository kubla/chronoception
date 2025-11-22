# Chronoception v1 PRD

## 1. Overview

Chronoception is an Apple Watch app that measures and trains chronoception, which is the brain's sense of elapsed time. It lets users run short challenge sessions where they estimate intervals without looking at a clock, as well as passive haptic drills that mark intervals in the background. The app logs sessions to Apple Health as Mindful Session entries, with metadata that supports deeper analysis off the watch.

v1 targets:

- **Platform**: Apple Watch only  
- **Logging**: Mindfulness minutes in Apple Health, with Chronoception specific metadata  
- **On watch experience**: Lightweight but informative feedback about time sense accuracy and improvement

Chronoception explicitly supports two initial ideal customer profiles:

1. **Quantified self enthusiasts**  
2. **Meditation practitioners ("meditation nerds")**

## 2. Goals and non goals

### 2.1 Product goals for v1

1. **Measure time sense**  
   Allow users to run Challenge Mode sessions where they choose an interval, tap when they believe that interval has elapsed, and see immediate feedback on their error.

2. **Train time sense**  
   Provide a Passive Training Mode that delivers distinct haptic patterns at chosen intervals while the watch face remains visible, so users can internalize what those intervals feel like.

3. **High arousal experiment (Fear Mode)**  
   Provide a Fear Mode variant of Challenge Mode that plays an aversive sound when estimates are off by more than a threshold percentage. This allows users to explore whether higher arousal and stronger error signals increase learning speed.

4. **On watch progress feedback**  
   Show simple, readable progress on the watch. For example, per interval summaries of typical error and whether the user is improving over time.

5. **HealthKit logging for analysis**  
   Write each completed session to Apple Health as a Mindful Session with structured metadata, so quantified self users and external tools can reconstruct and analyze sessions beyond what the watch UI can show.

### 2.2 Non goals for v1

These are explicitly out of scope for v1:

- No iPhone companion UI beyond standard Watch app management  
  - No iOS graphs, dashboards, or settings screens  
- No backend or cloud sync  
  - All state is local to the watch and Apple Health  
- No social features  
  - No leaderboards, competition, or sharing  
- No generalized productivity timer  
  - The app is not a Pomodoro timer or generic habit timer  
- No training for other sense gates  
  - v1 focuses only on chronoception, not interoception or other senses  
- No medical or therapeutic claims  
  - The app is positioned as cognitive and attentional training, not as a diagnostic or treatment tool

## 3. Constraints and assumptions

### 3.1 Platform constraints

- Target: latest stable watchOS  
- App must be usable when the phone is not present, except for initial install and Health configuration  
- Challenge and Fear modes use full screen watch UI and take over the crystal for interaction  
- Passive Mode runs in the background so that the ordinary watch face remains visible

### 3.2 HealthKit constraints

- The app writes **Mindful Session** entries using `HKCategoryTypeIdentifier.mindfulSession`  
- v1 requests **write access only** for Mindfulness  
- If permission is denied:
  - The app still works and stores session data locally for on watch summaries
  - No entries are written to Health

### 3.3 Haptics, audio, and battery

- Haptics:
  - Passive Mode uses distinct, learnable haptic patterns per interval
  - Challenge and Fear modes may use simple taps for start or summary when appropriate
- Audio:
  - Fear Mode uses an aversive sound as feedback when error exceeds a threshold  
  - If sound is effectively disabled by system settings, Fear Mode cannot deliver distinct aversive feedback
- Battery:
  - There is no hard product level cap on session duration in v1  
  - Implementation should be as battery friendly as possible given watchOS constraints

### 3.4 Time formatting

All user visible durations must follow this rule:

- If duration is less than 60 seconds, display as `Ns`  
  - Example: `45s`  
- If duration is at least 60 seconds, display as `Nm Ns`  
  - Examples: `1m 5s`, `3m 0s`, `10m 30s`  

Durations longer than 60 seconds are never displayed in pure seconds.

## 4. Ideal customer profiles (ICPs)

### 4.1 Quantified self enthusiast

**Who they are**

- Heavy wearable users who already log metrics such as sleep, heart rate, and HRV  
- Comfortable with the Apple Health app and external tools for analysis  
- Motivated by curiosity about human limits and by careful self instrumentation

**Jobs to be done**

1. Establish a baseline for time sense at specific intervals  
2. Track improvement in absolute error and variance across days and weeks  
3. Compare training strategies, for example Challenge vs Fear Mode  
4. Correlate chronoception metrics with other data streams such as sleep or HRV

**Preferences**

- Precise numerical feedback: seconds, percentages, and clearly defined scores  
- Strong preference for clean, consistent metadata in HealthKit  
- Dislikes opaque algorithms and vague descriptions

### 4.2 Meditation practitioner ("meditation nerd")

**Who they are**

- Regular meditators who are comfortable working with a chosen sense gate  
  - Breath, body sensations, sounds, thought streams, and similar  
- Often familiar with interoception practice  
  - Meditation on heartbeat, breath, or visceral sensations  
- Curious about chronoception as an additional sense gate

**Jobs to be done**

1. Meditate on chronoception as a sense gate  
   - Hold attention on the felt sense of time passing, similar to breath or body scan practice  
2. Occasionally calibrate that practice  
   - After or during a sit, see how close their felt 10 minutes is to objective 10 minutes  
3. Integrate chronoception practice into existing sits  
   - Use Passive Mode haptic markers or occasional Challenge Mode trials  
4. Use the Apple Watch as a subtle teacher, not a harsh judge  
   - Feedback is present but does not dominate attention

**Preferences**

- Simple, low friction flows that do not pull attention away from practice  
- Framing that emphasizes exploration of experience and training of a sense  
- Minimal gamification by default, with optional intensity such as Fear Mode for those who want it

## 5. Product hypotheses

- **Training hypothesis**  
  Deliberate practice with feedback in Challenge Mode and repeated interval exposure in Passive Mode will reduce average absolute error for trained intervals over time.

- **State dependence hypothesis**  
  The same user will show systematic differences in time bias across states such as meditation, work, walking, and fatigue. Users will find these differences interesting and potentially action guiding.

- **Motivation hypothesis**  
  Simple on watch progress views, such as comparison of this week's typical error against previous weeks, will be enough motivation for both ICPs to perform at least a few sessions per week.

- **HealthKit as lab hypothesis**  
  Mindful Session entries with Chronoception metadata will be sufficient for quantified self users and external tools to reconstruct sessions and run richer analyses than the watch UI can support.

- **Passive Mode hypothesis**  
  Passive haptic markers at chosen intervals will sharpen users' internal sense of those intervals, even without explicit error feedback, by pairing lived experience with labeled time boundaries.

- **Fear Mode hypothesis**  
  For a subset of users who opt in, a high arousal Fear Mode where errors larger than a threshold trigger an aversive sound will accelerate learning for those intervals.

- **Meditation on chronoception hypothesis**  
  Meditation practitioners who use chronoception as a sense gate and calibrate occasionally with Challenge Mode will report subjective improvements in their ability to track time during sits.

## 6. High level v1 feature list

- **Shared interval picker**
  - A single interval picker used by all modes  
  - One built in preset at 5m 0s  
  - Users can create custom intervals with minute and second granularity  
  - Custom intervals are stored as presets and listed in frecency order

- **Challenge Mode**
  - Full screen watch UI that takes over the crystal for interaction  
  - User chooses an interval and an attempt count (default 1)  
  - For each attempt the user taps when they believe the interval has elapsed  
  - Immediate feedback after each attempt indicates early or late and by how many seconds  
  - Session summary shown at the end  
  - Sessions logged to Health as Mindful Sessions with metrics

- **Fear Mode**
  - Same as Challenge Mode but with aversive audio feedback when error exceeds a threshold  
  - If system sound is effectively disabled, the app warns that Fear Mode will behave like Challenge Mode  
  - Sessions logged to Health with mode and audio effectiveness flagged

- **Passive Training Mode**
  - Runs in the background so the normal watch face remains visible  
  - User chooses an interval and a repetition count  
  - The watch emits a distinct haptic pattern for that interval at each boundary  
  - Sessions logged to Health as Mindful Sessions with minimal metadata

- **Progress view**
  - On watch view that shows simple per interval progress  
  - At minimum, a sense of typical error for an interval over recent sessions and whether it is improving

## 7. Primary v1 use cases

1. **Baseline test for one interval**  
   User opens the app, selects or accepts the default interval, runs a single Challenge attempt, sees the error immediately, and gains a baseline sense of accuracy.

2. **Focused drill at a chosen interval**  
   User configures a Challenge or Fear session with several attempts at one interval, runs them, and reviews per attempt feedback and the summary.

3. **Meditative chronoception sit**  
   User configures a Passive session with a longer interval and several repetitions, then meditates while haptics mark each interval boundary.

4. **On watch progress check**  
   User opens the Progress view to see whether their typical error at a favorite interval such as 5m 0s is trending downward.

5. **HealthKit inspection and analysis**  
   User opens Apple Health, navigates to Mindfulness, selects Chronoception entries, and sees enough metadata to reconstruct sessions and export them for external analysis.