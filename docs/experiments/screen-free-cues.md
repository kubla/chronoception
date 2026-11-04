# Screen-free cue experiments

Part of [product parent #11](https://github.com/kubla/chronoception/issues/11) and [screen-free work #13](https://github.com/kubla/chronoception/issues/13). These adapters extend the foreground slice; physical cue acceptance is still unrun.

## Watch: quiet practice

Train yourself offers **Quiet practice**, a deliberate silent mindfulness session. The app declares `WKBackgroundModes = [mindfulness]` and requests `WKExtendedRuntimeSession`. Timing begins only after the platform reports that runtime started. The store owns the timer task independently of the visible view and requests Watch haptics directly. User cancellation, expiration, invalidation and startup failure preserve an interrupted/cancelled record rather than manufacturing successful cues. Stale callbacks and timer tasks are checked against their creating session.

Apple supports screen-off operation for a frontmost mindfulness runtime, with an upper limit of one hour. Switching apps ends that runtime. The app rejects a planned quiet session beyond the limit; an OS refusal, early expiry or delayed boundary can still interrupt a shorter session. No workout, physical-therapy, alarm or silent-audio mode is used to obtain extra privileges. [Apple runtime guidance](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions), [background-mode declaration](https://developer.apple.com/documentation/bundleresources/information-property-list/wkbackgroundmodes).

The release archive check reads the built Watch plist and requires its mindfulness declaration. Compilation/configuration and simulated controls are evidence of those properties, not evidence of wrist-down haptics or battery impact.

## iPhone: pocket cue experiment

From Train yourself, **Try pocket cues** prepares one to five local notification requests at the selected interval. Authorization happens first; offsets are then anchored to a monotonic start so request preparation does not accumulate drift. Returning to the sheet reads the system's pending requests. The app owns the experiment controller across sheet replacement. Ending the experiment reconciles and cancels matching system requests, including after relaunch; cancellation during preparation also removes a request that completes late.

The phone may be locked or the sheet closed after requests are scheduled. Alert, sound, haptic and Focus settings affect delivery. Pending requests are reported as pending requests; they are never added to cued training history or estimate accuracy. This experiment does not claim that a notification was felt. [Apple local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app).

The native phone acceptance journey requests authorization in an isolated Simulator, checks the reported pending queue, cancels it and checks the empty queue. Only physical testing can establish whether this is a useful pocket cue under the intended settings. AlarmKit or a higher minimum OS version remains a possible alternative if the experiment fails; no such compatibility commitment is made here.

## Physical acceptance, still required

Use a personally signed build. Record build/source identity, device and OS, interval/repetitions, alert/haptic/Focus settings and initial battery level. Start with three 30-second intervals, then a normal five-minute session.

For Watch, lower the wrist and let the display sleep; separately switch apps to confirm interruption. For phone, lock it and place it in the intended pocket; separately cancel pending requests and confirm future cues stop. Record requested boundaries and observable delivery times, missed or unexpected cues, perceptibility and the ending battery level. Relaunch each app and inspect retained/interrupted observations.

Keep pass criteria tied to the intended use and measured results. A queued request, successful runtime start, timer count, screenshot or a tester's expectation is insufficient to assert physical delivery. If phone notifications or the Watch category cannot support the intended practice, retain that gap and consult on a working product alternative. Signing and actual-device access remain commissioning prerequisites; Fulcra's developer team must not be used.
