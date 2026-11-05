# Apple Watch workout runtime: prepared and stopped states

Researched 2026-11-04. Primary documentation and developer-owned examples only; no app code changed or run, and no Watch behavior measured.

**Finding:** workout-backed background haptics are documented and compatible with using another app or the watch face. `.prepared` and `.stopped` explicitly retain background runtime without generating workout data in those states. What remains unproven is whether either state preserves the direct-haptic exception for hours. They are useful experimental candidates, not established all-day timing guarantees.

## What Apple documents

| State | Documented behavior | Limit of the evidence |
| --- | --- | --- |
| `.prepared` | Background execution continues after wrist lowering; workout data is not yet generated. | No numeric duration or state-specific haptic promise. [Apple state documentation](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/prepared) |
| `.running` | Workout sensors and automatic sample collection operate; background audio/haptics are supported during an active session. | Sample writes and fitness effects cannot be assumed absent. [Running workout sessions](https://developer.apple.com/documentation/healthkit/running-workout-sessions) |
| `.paused` | The workout is paused. | Its state page does not promise normal sensors or no Health-store writes. Do not treat it as equivalent to stopped. [Apple state documentation](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/paused) |
| `.stopped` | Sensors return to normal, no new workout data is generated, and background execution continues. The session cannot restart. | Does not undo data generated before stopping; no numeric duration or state-specific haptic promise. [Apple state documentation](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/stopped) |
| `.ended` | Session-backed background runtime ends; sensors return to normal. | This releases the runtime being sought. [Apple state documentation](https://developer.apple.com/documentation/healthkit/hkworkoutsessionstate/ended) |

Apple's WWDC18 explanation makes the distinction concrete: prepared enters Session Mode with sensors ready and background runtime; stopped stays in Session Mode to permit workout saving; ended leaves it. The examples concern countdown and saving windows, not deliberately holding those states all day. [Apple, New Ways to Work with Workouts](https://developer.apple.com/videos/play/wwdc2018/707/)

`WKInterfaceDevice.play(_:)` normally has no effect in background/inactive states, with an exception for apps with an active workout session. Apple does not explicitly define whether prepared/stopped qualify for that exception. It also warns that haptics consume power, interrupt heart-rate gathering while playing, and replace in-progress feedback when called too closely. [Apple play documentation](https://developer.apple.com/documentation/watchkit/wkinterfacedevice/play(_:))

Active workouts allow execution while another app is used and background haptic alerts. Returning to the watch face displays a workout indicator. Excess CPU can cause suspension. Apple requires Workout processing plus the Audio background mode when providing workout haptics. [Running workout sessions](https://developer.apple.com/documentation/healthkit/running-workout-sessions) Session startup must occur in the foreground; the Crown can return to the face while the session continues. [Enabling Background Sessions](https://developer.apple.com/documentation/watchkit/enabling-background-sessions)

Apple documents one workout session at a time: a second workout ends the first with `errorAnotherWorkoutSessionStarted`. The precise prepared/stopped conflict transitions are not specified here; assume this route competes with real workouts until tested. [Apple HKWorkoutSession](https://developer.apple.com/documentation/healthkit/hkworkoutsession)

While running, Apple Watch automatically collects and saves samples, including active energy; calorimetry depends on workout configuration. Omitting a builder or discarding its final workout does **not** establish that no sensor samples or ring effects occurred. [Running workout sessions](https://developer.apple.com/documentation/healthkit/running-workout-sessions) Move credit depends on active energy; watchOS Exercise credit is sensor-derived. [Apple HKWorkout](https://developer.apple.com/documentation/healthkit/hkworkout)

## Actual examples and unresolved points

Chimer's developer-owned listing advertises indefinitely repeating background chimes using a workout session, discloses incompatibility with another workout, and describes a per-app Return to Clock setting to keep the face visible on wrist raise. Its April 2024 notes report fixing workout-hours pollution of Activity rings. It does not disclose whether prepared, paused, or stopped is used, nor provide battery or latency measurements. This is shipping-product evidence for the general workaround, not validation of a particular state. [Chimer App Store listing](https://apps.apple.com/us/app/chimer/id6480462949)

A developer-owned open-source metronome advertises lowered-wrist haptics through HKWorkoutSession. Its README supplies testing instructions, not measured all-day results or a prepared/stopped implementation claim. [Haptic repository](https://github.com/thegridbase-ai/Haptic)

The bounded search found no primary account demonstrating a nonfitness timer that deliberately remains prepared or stopped for hours with direct haptics. No consulted Apple source promises hard real-time delivery or a maximum cue delay. No measured battery comparison establishes that prepared is inexpensive simply because it generates no workout data; Apple's session explanation says sensors are ready.

**Next decisive experiment:** compare prepared-only, running, and running→stopped on a physical Watch, without a debugger, checking cue delivery with the face and another app visible, multi-hour survival, second-workout takeover, battery use, new Health samples, and ring changes. Prefer prepared-only as the first candidate because it avoids a running interval, while treating its haptics, power, and concurrency as unknown until measured. This is a proposed experiment; it has not been performed.
