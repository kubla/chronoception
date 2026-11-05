# Chronoception: unattended Watch training

November 4, 2026. Research and proposed feasibility experiment; no all-day hardware test or new implementation is claimed.

## Binding product requirement

Michael clarified: Watch training must act like a timer that automatically repeats throughout waking hours, with sustained use over months. People must retain the normal watch face and other Watch apps. Cues must not require dismissal/restart each interval or hourly app reopening. Individual practice remains account-free and phone-independent. [Product parent](https://github.com/kubla/chronoception/issues/11), [implementation/acceptance work](https://github.com/kubla/chronoception/issues/13).

The existing mindfulness runtime is a bounded foreground/frontmost adapter. It does not meet this outcome. This is missing product implementation in addition to missing physical acceptance. Existing foreground training, estimation and calibration remain accepted slices.

## Original recommendation, superseded in priority by the workout authorization

Michael subsequently accepted a workout-backed runtime if needed for timely cues. The [decision record](2026-11-04-chronoception-workout-runtime-decision.md) now prioritizes that experiment; notification scheduling remains a comparison candidate. The findings below remain evidence, not a standing prohibition on workout use.

## Notification candidate

Investigate a **persistent Watch-local cue schedule** owned by the operating system. Keep bounded practice sessions and persistent schedules conceptually distinct. The app installs, inspects, edits and cancels the schedule; it need not execute continuously between cues. Schedule on the Watch itself to retain phone independence and a Watch-specific destination. Apple's routing table identifies Watch-origin local notifications as Watch-only. [Routing contract](https://developer.apple.com/documentation/watchos-apps/taking-advantage-of-notification-forwarding).

For ordinary multi-minute practice, start with one `UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: true)`. The system repeats this kind of request until removal; its interval must be at least 60 seconds. This establishes a supported recurrence mechanism, not precise or uninterrupted physical alerting on current devices. [Trigger contract](https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger/init(timeinterval:repeats:)).

A repeating request is a materially different design from keeping a finite window of one-shot requests filled through background refresh. The latter needs replenishment and can run out while the app stays closed. For sub-minute cues, phased repeating calendar requests are a candidate for suitable cadences, such as separate :00/:30 requests. That is an untested engineering inference, not a validated workaround. Preserve foreground short-interval practice while investigating ambient feasibility separately.

## Evidence from other engineers

| Case | What it contributes | What it does not establish |
|---|---|---|
| **Haptic Interval Timer, FatCouple OÜ** | A currently published app describes Watch-local notification windows, background replenishment and a visible scheduling horizon. Its changelog reports fixing cues that silently entered Notification Center after a glance at the app, and later improving restart behavior. | Developer claims, not inspected source or our test. A finite horizon does not prove indefinite unattended operation. [Listing and release notes](https://apps.apple.com/ca/app/haptic-interval-timer/id6804729626?platform=watch). |
| **Silent Bell, Jakub Lipiński** | Open source and unusually candid physical-device notes. Physical-therapy runtime permits background taps. | Requires hourly resume; reports early system suppression. The author has not established multi-hour battery behavior. [Pinned lifecycle/testing record](https://github.com/jakublipinski/Silent-Bell/blob/f5555cf0b0751304ec98a68249711507e9119f42/README.md). |
| **HapTick, iebb** | Direct haptic scheduler with a self-care runtime. | Explicitly stops when frontmost status is lost; phone independence is not background independence. [Pinned controller](https://github.com/iebb/haptick/blob/331b2b0cfafe752f863ae02397cd53abc9123fd3/HapTick%20Watch%20App/TimerController.swift#L334). |
| **Chimer, Hwasung Kim** | Advertises indefinite recurring background chimes. | Developer says it cannot coexist with Workout/Activity. Its history names workout-session and Activity-ring repairs. This is a concrete compromise, not a transparent timer capability. [Developer listing/history](https://apps.apple.com/ca/app/chimer/id6480462949). |
| **Hekes Pekes, repeating-notification reproduction** | Posted the actual repeating trigger and reported successful real-device repetition. | A 2020 report. Simulator stopped after two untouched notifications, illustrating why simulated success/failure is insufficient. [Primary reproduction](https://stackoverflow.com/questions/61637111/repeating-notifications-not-repeating-in-watchos-simulator). |

[The companion source-inspection note](2026-11-04-watch-ambient-engineer-cases.md) pins additional workout implementations and separates source behavior, author observations and unverified claims. No third-party application or setup script was executed.

## Nuance that changes the tests

**Delivery coordination can add substantial delay.** In 2024, Apple DTS described a 13-second Watch wait for companion notification coordination and recommended matching identifiers/times on both devices. A 2025 developer supplied reproductions across iOS/watchOS versions where coordination still raced; Apple staff acknowledged evolving timing issues. We must measure this rather than subtracting a constant or assuming a Watch-native schedule eliminates it. [DTS explanation](https://developer.apple.com/forums/thread/765669), [reproduction and follow-up](https://developer.apple.com/forums/thread/801596).

**A refreshed Notification Center entry and a felt cue are different observations.** The experiment must leave earlier alerts untouched, include app glances, and check every later physical cue. The Haptic Interval Timer repair and historical Simulator report make this a concrete regression scenario.

**Nightly silence and months of recurrence need their own design.** The interval trigger has no end date. We must compare OS-encoded daily schedules with user-controlled Focus/silencing behavior; a promised stop time cannot depend on a suspended app waking precisely then. Reboot recovery, time-zone changes and schedule edits need explicit tests. The current watchOS pending-request limit must be measured or established from current platform evidence; the frequently cited 64 limit comes from deprecated iOS documentation.

**A workout is a consequential compromise.** Inspected workout timers use genuine workout machinery, and only one Watch workout can run at a time. An all-day workaround would compete with the ordinary Watch utility Michael explicitly requires. Discarding a workout record would not fix that conflict. This is not the default architecture recommendation. [Workout conflict contract](https://developer.apple.com/documentation/healthkit/hkerror/code/erroranotherworkoutsessionstarted).

## Next engineering milestone

Prepare a minimal Watch-native notification probe before expanding the product UI:

1. Register a one-minute and representative five-minute recurring schedule, with explicit Stop, actual pending-request readback and configuration identity. Handle foreground notification delivery so opening the app neither suppresses future cues nor doubles a cue.
2. Exercise untouched notifications, repeated app glances, the normal watch face, other apps and a genuine workout. Compare phone nearby/unlocked, nearby/locked and absent; measure notification coordination, sound/haptic settings and Focus behavior.
3. Run for a full waking day without reopening or restarting the app to replenish requests. Measure requested versus observed cue times, missing/duplicate cues, phase drift and energy against a matched idle baseline. A pending request count cannot pass this physical test.
4. Test termination, relaunch, reboot, charging/removal, edits, explicit Stop and daily quiet/resumption. Continue a multi-day soak before asserting ordinary daily reliability. Months of use remains a field-reliability objective, not a claim established by a one-day run.
5. Extend cue configuration and shorter cadences only after the mechanism works on the actual supported Watch/OS. If it fails, preserve the unmet requirement and bring measured alternatives; do not substitute wrist-down frontmost practice for ambient training.

A debugger may alter execution conditions. The decisive run must occur on actual signed hardware without an attached debugger. Personal signing and device access remain prerequisites, and Fulcra's developer team remains excluded. No new backend, vendor or runtime dependency is proposed.
