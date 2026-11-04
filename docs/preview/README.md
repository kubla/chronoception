# Interactive browser preview

GitHub Pages publishes `main:/docs`. `docs/index.html` presents the current native phone and Watch designs; the earlier prototype is retained at `docs/earlier-prototype.html`.

This is a browser prototype, not native app delivery. Its real-time practice uses a monotonic browser clock. Leaving the tab interrupts unfinished sessions; reload recovers them as interrupted. Phone and Watch previews have separate localStorage histories. Nothing is sent to an application backend. Haptics and locked-device behavior are not simulated.

`core.mts` holds the deterministic model; `app.mts` holds rendering and browser effects. The browser serves the generated `.mjs` modules. Generate them with `node verification/build_browser.mjs` using Node 22.22.3. This uses Node's built-in type erasure; it installs no dependencies locally. CI pins the same Node release, checks the generated files, installs TypeScript 5.9.3 in its ephemeral worker for strict type checking, then runs `node --test verification/browser.test.mjs`.

The native and browser engines are separate implementations. Their shared numeric fixtures and lifecycle tests check important agreements; they do not prove full equivalence. Inspect both device layouts and exercise the actual published page before calling a candidate complete.

The build hashes the CSS and both browser modules into their request URLs. Updating the preview therefore requests the matching assets instead of combining a fresh page with cached code. CI checks these references with the generated modules.
