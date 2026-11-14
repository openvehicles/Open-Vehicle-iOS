# OVMS iOS modernization: changes and validation

## Purpose and scope

This submission refreshes the legacy OVMS iOS application with adaptive native screens, additional vehicle controls and diagnostics, and a build and distribution foundation. It advances the Android parity roadmap while retaining the existing Objective-C application, vehicle database, and OVMS v2 connection and encryption implementation. It is a substantial foundation release, not a claim that every Android feature or vehicle module has been validated.

The submission builds on 47 commits from the parity development branch, followed by the scene lifecycle and blank-PIN corrections tested on a Nissan Leaf. The official upstream `master` was an ancestor of the submission when prepared on 15 October 2026; no upstream merge conflicts were present at that point.

## User-visible changes

### Home and navigation

- Replace the legacy home presentation with a scrolling dashboard showing vehicle state, charge information, connection freshness, and navigation to charging, climate, energy, controls, location, and messages.
- Allow home quick actions to be reordered, hidden, and reset, with preferences stored per vehicle.
- Reuse the modern status presentation on iPad and provide adaptive layouts for the primary screens.
- Provide dark, light, and system appearance preferences. Individual custom views still require visual review in each appearance.

### Charging

- Add a dedicated live charging screen with charge state, electrical information, range, and charge controls.
- Confirm start and stop commands and expose charging settings and supported limits.
- Show pending and failed command states, disable relevant controls while waiting, and process server acknowledgements and timeouts.
- Keep charging information subscribed while the screen is visible.

### Climate

- Add cabin and ambient temperature displays and confirmed remote climate start/stop actions.
- Add climate schedule controls, including day selection and validation, advanced options, copying schedules, and clearing an individual day or the schedule.
- Use the vehicle's configured target temperature. Climate and schedule support remains dependent on module firmware and supported commands.

### Security and vehicle controls

- Add modern dialogs for lock/unlock, valet, vehicle wake-up, and Homelink.
- Select controls using the vehicle type capability rules, including drive profiles for Twizy and DDT4all actions for Scenic where supported.
- Preserve the existing lock command `20,<PIN>` and unlock command `22,<PIN>`, and use the reported lock state to choose the offered action.
- Restore empty-PIN submission. The modern dialog originally returned without sending anything when the PIN was blank; the legacy form passed the blank value to the module. This prevented operation on the tested Leaf, which does not use a PIN. The dialog now always submits the confirmed value and leaves validation to the module. Cancel still submits nothing. This shared dialog correction also applies to valet commands.
- Display tyre pressure independently of tyre temperature availability, rather than hiding pressure when temperature is unavailable.

### Energy and battery diagnostics

- Add a live energy and battery overview and persist traction power history per vehicle.
- Add pack health, capacity, voltage/current, battery temperature, CAC, and data-age displays where metrics are available.
- Add battery pack, cell, and 12 V history retrieval, loading/error states, charts, and locally retained records.
- Prime battery history before retrieving records. Historical diagnostics depend on server/module support and available records.

### Maps and location

- Modernize map controls and replace the legacy map popover.
- Display a recent vehicle trail and add server GPS history retrieval with locally retained history.
- Keep location and historical records associated with the selected vehicle.

### Messages and module administration

- Add message history actions and command tools, including saved commands per vehicle, command management, and history clearing.
- Make keyboard dismissal available in the Messages container.
- Add a vehicle diagnostics hub and refresh the module control hub, feature and parameter editors, and cellular usage diagnostics.

## Application and protocol changes

- Introduce a single-window scene lifecycle. The scene delegate creates the window using the iPhone or iPad storyboard and forwards activation/background transitions to the existing application lifecycle handlers. Window-dependent appearance and navigation setup runs after the root controller is created.
- Set the minimum supported iOS version to **iOS 15.0** across project and target configurations. This is a compatibility change for devices running older iOS versions and matches the development build used for vehicle testing.
- Extract command response parsing into `OVMSCommandResponse`, retaining comma-containing response payloads and rejecting malformed command/result headers.
- Extract decrypted telemetry envelope validation into `OVMSTelemetryFrame` and add bounded reconnect backoff.
- Add command acknowledgement timeouts and an explicit offline submission message. Charging additionally manages its own pending UI state.
- Move vehicle network and user credentials into Keychain with migration from existing stored credentials. Keychain data uses device-only, after-first-unlock accessibility.
- Add UserNotifications integration and actionable notification routing, plus background refresh support and app settings.
- Include a privacy manifest declaring the UserDefaults API reason. The manifest and App Store privacy disclosures still need the publisher's release review.
- Include a YYText compatibility correction and the required framework/resource project entries.

## Build and distribution

- Add a shared Xcode scheme and GitHub Actions simulator build workflow.
- Run the protocol fixture executables in CI, build without signing, check that the privacy manifest is packaged, and capture iPhone/iPad primary screens and selected dialog/loading/failure scenarios.
- Restrict deterministic screenshot scenario hooks to Debug simulator builds. Screenshot capture verifies launch survival and artifact presence; it is not an assertion-based UI interaction suite.
- Add a manually triggered signed archive/export workflow with optional TestFlight upload and separate distribution documentation. It requires maintainer-provided Apple signing and App Store Connect secrets in the `testflight` environment.
- Preserve the upstream bundle identifier, development team settings, and push entitlement in this submission. Local personal signing settings and the test app's removed push entitlement are excluded. Signing settings can be overridden for a maintainer's release build.
- Add `ROADMAP.md` to document the remaining parity work and delivery principles.

## Validation evidence

### Confirmed

- The tester reported that the app was working except for lock/unlock on a Nissan Leaf, then confirmed all was working after the blank-PIN correction. This is user-reported device/vehicle validation, not an instrumented test report covering every feature.
- The development configuration passed an unsigned Debug iOS Simulator build after the PIN correction.
- Both fixture executables passed again from the upstream submission worktree: five command response fixtures plus five malformed response cases; telemetry envelope fixtures and malformed cases; and bounded reconnect backoff expectations.
- The upstream submission configuration passed an unsigned Debug iOS Simulator build with the official app identity and push entitlement retained.
- Property lists and the privacy manifest passed syntax validation, and the built app contained the privacy manifest.
- The submission passed `git diff --check`.

### Remaining review and release validation

- Test other supported vehicle modules, especially vehicle-specific controls, climate schedules, charging limits, and historical server responses. Capability rules are based on vehicle type and cannot prove firmware-level support.
- Exercise iPhone/iPad layouts, accessibility, appearance choices, foreground/background transitions, connection recovery, notification routing, and credential migration on devices using the official app identity.
- Review command timeout/delegate handling and failure paths across concurrent requests before production release. Existing fixture tests validate parsers and reconnect policy rather than full encrypted transport or end-to-end command delivery.
- Run the new GitHub Actions workflow in the upstream PR context. Its presence is not evidence that the full screenshot workflow has passed for this submission.
- Validate a signed archive, push delivery, TestFlight installation, and App Store processing using the official publisher's account. No official App Store release or upstream merge is performed by preparing this PR.

## Suggested review order

1. Build settings, scene lifecycle, and compatibility requirements.
2. Connection/parser changes, command acknowledgement behaviour, and Keychain migration.
3. Home, charging, climate, and security controls, including blank-PIN regression details.
4. Battery, location, messages, module administration, and capability rules.
5. CI, distribution configuration, privacy declarations, and remaining roadmap items.

The draft PR is intended to let maintainers assess this full refresh and decide whether to merge it as a whole or request smaller submissions. Publishing the official app remains a separate maintainer release step after review and testing.
