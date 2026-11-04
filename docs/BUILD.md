# Current Chronoception build

Native SwiftUI iPhone and independent Watch apps share a deterministic Swift core. Individual practice works without an account, backend or the other device. Local history preserves observations. This architecture was confirmed on November 3, 2026.

The estimation journey is interval → begin → estimate without a visible clock → literal early/late feedback → local history. Repeated attempts are explicit; duplicate taps cannot resolve an attempt twice. Cancelling preserves completed attempts. Relaunching interrupts unfinished work instead of resuming a clock from another process.

The old specifications and browser prototypes are historical design input. Their modes, score formula, HealthKit contract and companion-only restrictions are not inherited requirements. Training and interval-specific calibration are required parts of the product. Only community design remains optional. A successful Simulator run does not prove a cue can be felt on locked hardware.

## Training and calibration

Choose **Train yourself** for repeated interval cues or **Test yourself** for unaided estimates. Training uses a start marker followed by one marker per chosen interval. Native apps request haptic feedback; the browser preview shows visual cues. Training history records cued intervals separately and never adds them to estimate accuracy.

The default training adapter runs in the foreground. Leaving the app or hiding the tab interrupts that mode. The visual-only browser also interrupts when you open another screen or switch preview devices. A boundary more than 500 ms late interrupts rather than inventing missed cues or delivering a burst of catch-up cues. Deadlines stay anchored to the session start, so small scheduling delays do not accumulate. The 500 ms threshold is an operating choice, not a perceptual accuracy claim. Actual haptic latency and perceptibility need device measurement.

History groups estimates by interval. Each group compares the latest five available estimates with the preceding five when available; sample counts stay visible. Training is excluded. These observations do not claim a measured training effect.

**Product status remains incomplete:** Watch quiet practice now requests a screen-off mindfulness runtime, and iPhone offers a separate notification-based pocket cue experiment. Their physical cue delivery and signed personal distribution still need acceptance. See [screen-free experiments](experiments/screen-free-cues.md). Follow [the product parent](https://github.com/kubla/chronoception/issues/11). A passing change does not close it.

## Architecture and verification

`Shared` contains the domain and persistence packages. `Application` contains shared SwiftUI surfaces and OS adapters. Phone and Watch have distinct native targets. See `GLOSSARY.md` and `docs/model/Session.md` for the inspectable model.

Local first-party Apple compilation/Simulator work is acceptable when practical; there is no third-party runtime dependency. Clean GitHub macOS VMs independently exercise the candidate. Keep build outputs out of cloud-synced document directories when signing metadata interferes; verification scripts use temporary scratch directories.

Verification runs compiler/core tests, generated event traces, meaningful seeded defects, native app/UI journeys and evidence capture. Release must identify the actual tested artifact and destination. Development builds or simulator screenshots are not an App Store/TestFlight delivery.

## Delivery

Shipping is autonomous under configured project authority. Signing/team access, actual device evidence and store distribution are commissioning facts to prove, not reasons to substitute a document for an app. Consult on changes that create consequential long-term architectural obligations.

The distribution checklist and current commissioning status are in `docs/RELEASE.md`; prepared store copy is in `docs/STORE.md`. Repository `main` now requires the core, unsigned release archive, iPhone UI and Watch UI jobs from GitHub Actions, including for admins. No standing human review is required by that rule.

Native acceptance retains XCTest’s app recordings on passing and failing runs. A receipt requires the nine shared journeys plus one platform-specific experiment journey, with their named screenshots and a recording plus launch observation for each journey. Raw Watch display video was observed showing the watch face rather than the tested app; it is not used as app evidence.

Acceptance checks the rendered navigation title in its native accessibility bounds against a 4.5:1 contrast threshold. The check rejected a captured dim Watch title (2.68:1) and accepted the captured phone title (19.22:1). It uses pixel luminance percentiles within that rectangle, so it is a focused visual regression check rather than a full WCAG conformance claim.

## Completion reporting

`Product status` runs after `Native acceptance`. Its privileged publisher uses code from the default branch and reads only small JSON receipt artifacts from the completed run. Candidate code runs with read-only repository access. Receipt revision, source tree, run identity, result and required training/estimation journeys must agree. The publisher never executes candidate artifacts. See GitHub's [workflow security guidance](https://docs.github.com/en/actions/reference/security/secure-use).

The report distinguishes change acceptance from product completion and refreshes issue #11 after current `main` runs. It leaves the parent open while physical cues and signed delivery lack commissioned acceptance. Reports from PRs are retained as artifacts and summaries, not promoted to delivered status. This is evidence coverage for known requirements; an independent purpose review still has to discover omissions the map does not name. It queues next work but does not itself launch an AI worker or enforce a provider's session termination.
