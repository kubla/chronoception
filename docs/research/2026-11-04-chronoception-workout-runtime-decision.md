# Workout-backed Watch runtime: authorized candidate

November 4, 2026. Michael accepts a workout-backed runtime if needed for dependable, timely all-day cues. This supersedes treating workout interference as a reason to exclude that route. It does not establish a delivery guarantee or approve arbitrary Health data access.

The product outcome remains sustained passive training with the normal Watch face and other apps usable, without interval-by-interval restart or hourly reopening. The current app still uses the bounded mindfulness adapter; no workout implementation or hardware test has been completed by this decision record.

## Candidate to build and measure

Use a HealthKit workout session as a runtime lease and deliver direct, monotonic-clock-scheduled Watch haptics. Compare minimal prepared/stopped states with running, admitting the least costly state that actually meets the cue contract. Apple's state descriptions retain background runtime in prepared/stopped; direct haptic eligibility in those states and indefinite retention remain unverified. [Prepared](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/prepared), [stopped](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/stopped).

Workout haptics require the documented Workout processing and Audio background modes. This does not require implementing a silent audio loop. [Running workout sessions](https://developer.apple.com/documentation/healthkit/running-workout-sessions).

Record requested versus observed haptic timing, missed/late/duplicate cues, runtime termination and recovery, CPU and energy. Exercise the normal face, other apps, actual workouts, daily quiet/stop behavior and relaunch without an attached debugger. A full waking day and multi-day soak are required; no numeric lateness or battery guarantee is established by choosing this API.

## Side effects and limits to establish

- Only one Watch workout session can run at a time. Another workout can displace Chronoception. Do not automatically fight the user's real workout for control. [Session contract](https://developer.apple.com/documentation/healthkit/hkworkoutsession).
- A running workout automatically affects sensor collection; omitting/discarding the live builder does not prove Health samples or Activity rings remain clean. Measure the actual state-specific behavior and keep permissions minimal. [Workout behavior](https://developer.apple.com/documentation/healthkit/running-workout-sessions).
- Watch face access and the Watch's return-to-app-on-wrist-raise behavior are separate observations. Verify both on the intended Watch/OS and expose any required one-time setting honestly.
- Background runtime is not a hard real-time scheduler. Record interruptions and late cues; never manufacture completed training from elapsed time alone.

[Focused source research](2026-11-04-watch-workout-runtime-nuance.md) documents the API nuances and inspected engineer examples. [Work item #13](https://github.com/kubla/chronoception/issues/13) and [product parent #11](https://github.com/kubla/chronoception/issues/11) retain the approved candidate and unfinished acceptance.
