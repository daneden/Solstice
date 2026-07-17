# Localized App Store Screenshots

A repeatable pipeline that turns one UI-navigation test into finished, localized App
Store screenshots across every shipping language. Three independently-runnable stages:

1. **Capture** — one XCUITest (`SolsticeUITests/AppStoreScreenshots.swift`) drives the app;
   the `Screenshots` test plan runs it once per locale.
2. **Extract** — `Scripts/capture-screenshots.sh` pulls the PNGs out of the `.xcresult`
   into `Screenshots/output/<locale>/<screen>.png` (via `xcrun xcresulttool`).
3. **Compose** — drop the raw shots into a Figma marketing template (device frame,
   background, localized caption). See `Screenshots/figma/compose-runbook.md`.

Stages 1–2 use only native Xcode tooling (`xcodebuild` + `xcresulttool`). No third-party
screenshot framework, no Ruby/gems, no `xcparse` (it can't read the Xcode 26+ xcresult
format — `xcresulttool export attachments` is used instead).

## Run it

```bash
# All 10 locales:
Scripts/capture-screenshots.sh

# A subset (fast iteration — base + CJK + RTL):
Scripts/capture-screenshots.sh en ja ar
```

Output lands in `Screenshots/output/<locale>/`:

```
Screenshots/output/en/01-location-list.png
Screenshots/output/en/02-detail-daily.png
Screenshots/output/en/03-detail-annual.png
Screenshots/output/en/04-time-travel.png
Screenshots/output/en/05-notifications.png
Screenshots/output/de/...
```

Then follow `Screenshots/figma/compose-runbook.md` for Stage 3.

## Screens captured

| id | Screen |
|----|--------|
| `01-location-list` | Saved-locations list |
| `02-detail-daily` | Location detail — daily overview (hero) |
| `03-detail-annual` | Location detail — annual overview / chart |
| `04-time-travel` | Detail view time-travelled ~3 months ahead |
| `05-notifications` | Notification settings |

## How it works

- **Deterministic state.** The test launches the app with `-UITestScreenshots`, which
  makes it use an in-memory Core Data store seeded from `Data Model/defaultData.json`
  (no CloudKit, no location-permission prompt). See `Solstice/Helpers/ScreenshotSupport.swift`.
- **No onboarding sheet.** Capture mode marks onboarding complete so the app opens straight
  into content (see `ScreenshotSupport.prepareForCaptureIfNeeded()`).
- **Locale-independent navigation.** Every element is located by accessibility identifier
  (never localized text), so the same flow runs unchanged in all languages. Identifiers
  live in `ScreenshotSupport.swift` (canonical, app target) and are mirrored in
  `SolsticeUITests/ScreenshotSupport.swift` (the UI-test target can't import the app).
- **Time travel.** The time-travel shot relaunches the app with
  `UITEST_SELECTED_LOCATION` + `UITEST_TIME_OFFSET_DAYS` so it opens straight into a
  detail view offset ~3 months ahead.
- **Locales live in the test plan.** `Screenshots.xctestplan` has one configuration per
  locale; the test code never mentions a locale.

## Add a locale

1. Add a configuration to `Screenshots.xctestplan` (set `language`/`region`).
2. Add the same locale code to `ALL_LOCALES` in `Scripts/capture-screenshots.sh`.
3. Add caption copy for it in `Screenshots/figma/captions.json`.

## Add a screen

1. Add an `.accessibilityIdentifier(...)` to the target element in the app, and the
   matching constant in **both** `ScreenshotSupport.swift` files.
2. Add the navigation + `capture(app, named: "NN-screen")` step in
   `AppStoreScreenshots.swift`.
3. Add the screen id to `captions.json` (`screens` + each locale) and the table above.

## Devices

Defaults to the 6.3" iPhone (`iPhone 17 Pro`) to match the device bezel in the Figma
marketing template. Swap `DEVICE_NAME` to `iPhone 17 Pro Max` for the 6.9" App Store size,
or uncomment the 13" iPad line to shoot iPad (run per device).

## Not included / caveats

- **Lock Screen widgets** are not captured — XCUITest cannot screenshot the real Lock
  Screen. If you want widget marketing shots, render the accessory widget views in a
  dedicated harness (SwiftUI previews or a gated in-app gallery) and frame them in Stage 3.
- **Stage 3 (Figma)** requires the Figma MCP server + a Full seat; it is delivered as a
  runbook, not yet executed. See `figma/compose-runbook.md`.
- Captions in `captions.json` are AI-drafted — review before publishing.
