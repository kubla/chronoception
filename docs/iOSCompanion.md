# Chronoception iOS Companion App (v1)

Chronoception is **Watch-first**: the Apple Watch app is where sessions run (Challenge, Fear, Passive), where haptics happen, and where immediate feedback appears.

However, most people discover Chronoception via the iOS App Store. The iOS app exists to:

- Make the product immediately understandable in screenshots and on first launch.
- Help users install/open the Watch app.
- Let users configure defaults more comfortably.
- Provide a larger-screen place to review progress over time.

This document fills in iOS-specific gaps that are not covered in `docs/WatchUX.md`.

## 1. iOS app principles

1. **Never compete with the Watch**
   - The iPhone app does not run training sessions in v1.
   - It should not present a “Start session” flow that implies the user can complete sessions on iPhone.

2. **Teach the mental model quickly**
   - In the first 10 seconds, users should understand:
     - “This is a time sense trainer.”
     - “The training happens on Apple Watch.”
     - “This iPhone app is for setup and review.”

3. **Reduce setup friction**
   - Provide clear instructions for installing/opening the Watch app.
   - Explain Health logging and what is (and isn’t) collected.

4. **Respect privacy and permissions**
   - On iOS v1, HealthKit is informational only unless a future read-based rebuild is added.
   - Make it easy to understand Health logging status and how to change it.

## 2. Navigation structure (recommended)

Use a simple tab bar (or `NavigationSplitView` if you prefer iPad), with four destinations:

1. **Home**
   - Watch status and quick explanation.
   - “Open on Watch” affordance.
   - “How it works” short links.

2. **Learn**
   - Static, readable content derived from existing docs.
   - Includes a concise mode overview and FAQ.

3. **Progress**
   - Summaries synced from Watch via WatchConnectivity.
   - Emphasize trends and typical error by interval.

4. **Settings**
   - Preferences that sync to Watch.
   - Health logging status guidance.

## 3. Onboarding

On first launch (and only on first launch), show a short onboarding flow:

1. **Welcome / Watch-first**
   - Copy suggestion:
     - “Chronoception lives on your Apple Watch.”
     - “Use your Watch to train your sense of time.”
     - “Use your iPhone to learn, configure, and review progress.”

2. **Install / open the Watch app**
   - If Watch is paired and app is installed:
     - Offer an “Open on Watch” button.
   - If Watch is paired but app is not installed:
     - Explain how to install it (typically via Watch app / auto-install).
   - If no Watch is paired:
     - Be explicit: “Chronoception requires Apple Watch.”

3. **Health logging explainer**
   - Explain that completed sessions can be logged as **Mindful Sessions** with Chronoception metadata.
   - Explain this is written from the Watch, and how to enable/disable.

After onboarding, send users to Home.

## 4. Data sources

### 4.1 Primary source: WatchConnectivity summaries

In v1, the iOS app should treat the Watch as authoritative for sessions.

- Watch sends `SessionSummaryPayload` after a completed session.
- iOS persists summaries (CoreData recommended per spec).

### 4.2 Optional future: rebuild from HealthKit

HealthKit reconstruction is a stretch goal:

- It adds permission complexity and query edge cases.
- It can be a v1.1 improvement if users expect history to appear on iPhone even when the Watch was offline.

## 5. Progress views (iOS)

Keep iOS Progress aligned with watchOS Progress, but take advantage of space:

- **Interval performance**
  - For each interval: typical error (e.g., mean abs error) and a simple trend indicator.
- **Mode mix**
  - Share of sessions per mode (Challenge/Fear/Passive).
- **Recent sessions list** (optional)
  - Show last N session summaries with date, interval, score.

Empty states:

- If no sessions have been synced yet, explain how to run a first session on Watch.
- If Watch is not paired, explain requirement.

## 6. Settings (iOS)

At minimum:

- Default mode
- Default interval
- Fear Mode opt-in
- Watch status (paired / reachable / installed)
- Health logging guidance (“written from Watch” + link text to system Settings)

## 7. App Store discovery notes

The App Store listing and iPhone screenshots should make the Watch-first value obvious:

- Show Watch screenshots for the session flow.
- Use iPhone screenshots to explain the concept, onboarding, and progress.
- Avoid imagery that implies sessions run on iPhone.

---

For the canonical mode behavior, metrics definitions, and HealthKit metadata schema, refer to:

- `docs/ModesAndMetrics.md`
- `docs/WatchUX.md`
- `docs/HealthKitSpec.md`

This document intentionally does not redefine watch flows; it defines only the iOS companion experience.

