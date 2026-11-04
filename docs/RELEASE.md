# Release commissioning

The current build is account-free training and estimation practice for iPhone and Apple Watch. Version 0.1.0 runs independently on either device. Histories are local to each installation; they do not sync. There is no HealthKit permission, remote account or paid feature.

## Evidence and delivery

Every candidate runs `verification/core`, three compiling fault injections, the bounded TLA+ session model and native XCTest journeys on both platforms. Native jobs retain result bundles, screenshots, videos and a receipt tied to the tested revision. A failed or missing journey is incomplete acceptance.

The November 3 development build compiled locally with Xcode 27.1, including both UI-test targets and an unsigned Release archive containing the phone app and independent Watch app. This establishes compilation, not distribution. CI is the independent execution record; see the pull request checks for the current revision.

Michael has Fulcra developer access and explicitly wants this app published as his own personal project. At the last commissioning check he reported no personal Apple Developer membership; refresh enrollment status before distribution. TestFlight commissioning therefore starts with personal enrollment, then the owning team, usable signing authority and an App Store Connect app record. The provisional bundle identifiers are `io.mjjt.chronoception` and `io.mjjt.chronoception.watchkitapp`; registration must establish their availability. Signed archives must be validated and uploaded, and processing must complete before a build is called available to testers. Keep project signing credentials separate from personal email and account-recovery access.

Physical device checks must exercise a normal interval, wrist lowering or phone locking, interruption/relaunch and the start/estimate feedback taps. Record device, OS, tested build and observations. Simulator evidence cannot establish tactile quality. These checks can be performed by a tester; they do not require Michael to approve each delivery.

## Remaining required product work

- **Screen-free training (required):** [quiet Watch runtime and phone notification adapters](experiments/screen-free-cues.md) are implemented as experiments. Compare their interval markers on real hardware. Measure requested versus delivered boundaries while the device is locked, perceptibility and battery impact. Establish platform-supported background behavior before promising passive practice.
- **Calibration:** the foreground candidate compares recent and previous estimates per interval. Retain current candidate evidence on both native surfaces and the browser. Do not confuse cued intervals with accuracy observations.

## Optional exploration

- **Community:** prototype a shared practice challenge, a small private circle and a leaderboard before choosing a service. Evaluate whether each improves practice, how comparison handles unlike intervals, and what abuse/support obligations it creates. A small paid community unlock remains an option; basic individual practice stays useful without an account. Consult Michael before committing to a backend, payment arrangement or ongoing vendor obligation.

The historical specifications remain sources of ideas, not a release checklist.

CI pins Xcode 26.2 and chooses a Simulator runtime matching that SDK, rather than combining the runner’s older default Xcode with its newest installed runtime. The [runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md) documents both installed choices.

The archive check rejects multiple top-level apps and requires Xcode’s `ApplicationProperties` distribution metadata. It was demonstrated failing against the original generic archive, then passing after the Watch target was changed to `SKIP_INSTALL=YES`. The Watch app remains embedded and independent at runtime.
