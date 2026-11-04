# Current Chronoception build

Native SwiftUI iPhone and independent Watch apps share a deterministic Swift core. Individual practice works without an account, backend or the other device. Local history preserves observations. This architecture was confirmed on November 3, 2026.

The first usable journey is interval → begin → estimate without a visible clock → literal early/late feedback → local history. Repeated attempts are explicit; duplicate taps cannot resolve an attempt twice. Cancelling preserves completed attempts. Relaunching interrupts unfinished work instead of resuming a clock from another process.

The old specifications and browser prototypes are historical design input. Their modes, score formula, HealthKit contract and companion-only restrictions are not inherited requirements. Pocket cues and social/community designs remain explicit product experiments. A successful Simulator run does not prove a cue can be felt on locked hardware.

## Architecture and verification

`Shared` contains the domain and persistence packages. `Application` contains shared SwiftUI surfaces and OS adapters. Phone and Watch have distinct native targets. See `GLOSSARY.md` and `docs/model/Session.md` for the inspectable model.

Local first-party Apple compilation/Simulator work is acceptable when practical; there is no third-party runtime dependency. Clean GitHub macOS VMs independently exercise the candidate. Keep build outputs out of cloud-synced document directories when signing metadata interferes; verification scripts use temporary scratch directories.

Verification runs compiler/core tests, generated event traces, meaningful seeded defects, native app/UI journeys and evidence capture. Release must identify the actual tested artifact and destination. Development builds or simulator screenshots are not an App Store/TestFlight delivery.

## Delivery

Shipping is autonomous under configured project authority. Signing/team access, actual device evidence and store distribution are commissioning facts to prove, not reasons to substitute a document for an app. Consult on changes that create consequential long-term architectural obligations.

The distribution checklist and current commissioning status are in `docs/RELEASE.md`; prepared store copy is in `docs/STORE.md`. Repository `main` now requires the core, unsigned release archive, iPhone UI and Watch UI jobs from GitHub Actions, including for admins. No standing human review is required by that rule.

Native acceptance retains XCTest’s app recordings on passing and failing runs. A receipt requires the five named journeys, nine named screenshots and a recording plus launch observation for each journey. Raw Watch display video was observed showing the watch face rather than the tested app; it is not used as app evidence.

Acceptance checks the rendered navigation title in its native accessibility bounds against a 4.5:1 contrast threshold. The check rejected a captured dim Watch title (2.68:1) and accepted the captured phone title (19.22:1). It uses pixel luminance percentiles within that rectangle, so it is a focused visual regression check rather than a full WCAG conformance claim.
