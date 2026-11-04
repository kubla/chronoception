# Chronoception

Practice noticing elapsed time, on iPhone or Apple Watch.

[Try the interactive browser preview](https://kubla.github.io/chronoception/). It follows the current native interfaces, with real estimates and separate browser-local phone/Watch histories. Haptics and background timing require the native apps. [The earlier prototype](https://kubla.github.io/chronoception/earlier-prototype.html) remains available as historical design material.

The native app lets you learn an interval through repeated cues, test it without a countdown, and compare estimates for the same duration over time. Training history and estimate accuracy stay separate. Normal training runs in the foreground. Quiet Watch practice and phone notification cues are [screen-free experiments](docs/experiments/screen-free-cues.md); physical cue acceptance and signed personal distribution remain open in [the product parent](https://github.com/kubla/chronoception/issues/11). Phone and Watch each work independently. Individual practice needs no account or backend.

## Native app

Open `Chronoception.xcodeproj` in Xcode. `Chronoception` builds the phone app and embeds the independent Watch app; `ChronoceptionWatch` runs the Watch app directly. Select your development team when signing for a physical device.

The app uses SwiftUI and a local Swift package, with no third-party runtime dependencies. `Shared` contains the deterministic session core and local persistence. `Application` contains the views and platform effects. Domain terms live in [GLOSSARY.md](GLOSSARY.md); current scope and decisions live in [docs/BUILD.md](docs/BUILD.md).

## Verification

Run `verification/core` with the intended Xcode selected through `DEVELOPER_DIR`. It checks formatting, parser-based house rules, the generated project and the actual production core. Build products use temporary storage. The entry point also decodes the actual icon assets and rejects blank, transparent or incorrectly sized images.

[Native acceptance](https://github.com/kubla/chronoception/actions) runs on clean GitHub-hosted macOS VMs. It exercises core invariants, meaningful seeded faults, a bounded state model and full phone/Watch UI journeys. Per-run artifacts contain logs, screenshots, video and receipts. Acceptance also checks rendered navigation-title contrast inside bounds reported by the native accessibility tree; this is a focused regression check, not a complete accessibility audit. A failed or missing prerequisite is not a pass.

[The session diagram](docs/model/Session.md) connects the domain transitions, production engine and generated-trace tests. `verification/house-style` uses the SwiftSyntax/SwiftParser libraries shipped with the selected Xcode, with positive and negative rule fixtures.

## Delivery state

This branch is the native implementation and acceptance path. Simulator results establish native UI behavior, not physical haptics, locked-pocket cue delivery or store distribution. Those facts are recorded separately. No public-store release is claimed by a passing build.

Pocket-cue feasibility and social/community concepts are product experiments, not assumed implementations. Local history stays independent of any future service.

## Earlier design material

The files in `docs/PRD.md`, `docs/ModesAndMetrics.md`, `docs/HealthKitSpec.md`, `docs/WatchUX.md`, `docs/iOSCompanion.md`, `.zenflow` and the browser demos preserve earlier ideas. They are informational, not requirements. The current product direction and observed platform behavior govern the implementation.

[Historical browser prototype](https://kubla.github.io/chronoception/earlier-prototype.html) · [Current build direction](docs/BUILD.md)
