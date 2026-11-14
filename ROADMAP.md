# OVMS iOS parity roadmap

The goal is functional parity with the OVMS Android application while retaining
the stable OVMS v2 protocol implementation during the transition.

## Delivery principles

- Keep `master` releasable and deliver one focused pull request per feature.
- Preserve compatibility with all OVMS vehicle modules; put vehicle-specific
  behaviour behind capabilities rather than hard-coded screen assumptions.
- Separate protocol parsing, vehicle state, commands, and presentation so each
  layer can be tested independently.
- Prefer native Apple frameworks and accessible, adaptive layouts.
- Treat remote vehicle commands as safety-sensitive: confirm consequential
  actions, show pending state, handle timeouts, and never report success before
  the server acknowledges it.

## Milestones

### 0. Build and release baseline

- Restore clean builds with the current Xcode toolchain.
- Remove compiler errors and deprecated build settings incrementally.
- Add CI for build and unit tests on a supported iOS simulator.
- Document local setup, signing, test-server configuration, and release steps.

### 1. Shared application core

- Define typed vehicle state and capability models.
- Isolate the existing OVMS v2 connection, authentication, paranoid mode,
  message parsing, command queue, timeout, and reconnect behaviour.
- Add fixture-driven tests using captured and synthetic protocol messages.
- Move secrets from general preferences/Core Data into Keychain storage.

### 2. Status and vehicle controls

- Adaptive home/status screen for iPhone and iPad.
- State of charge, range, connection freshness, doors, locks, temperatures,
  tyre pressures, 12 V battery, odometer, and vehicle state.
- Capability-driven quick actions for wake-up, lock/unlock, valet, and Homelink.
- Multiple-vehicle selection and configuration.

### 3. Charging

- Detailed charge state, power, voltage/current, energy, mode, limits, and time
  remaining.
- Start/stop charging and set supported current, state-of-charge, and range
  limits with confirmation and acknowledgement.
- Vehicle-specific charge controls without leaking vehicle rules into the UI.

### 4. Climate

- Cabin and ambient conditions plus live HVAC state.
- Start/stop climate control and expose supported modes.
- Climate schedules, including copy/edit/delete and clear timezone semantics.

### 5. Energy and battery diagnostics

- Trip/energy consumption and power charts.
- Main battery pack health, cell voltage/temperature views, alerts, and
  balancing information.
- Auxiliary battery history and health presentation.

### 6. Location, notifications, and diagnostics

- Current location, history and map settings.
- Notification inbox and actionable alerts.
- Command shell, stored commands, module logs, cellular statistics, features,
  parameters, and firmware information.

### 7. Apple platform integration and polish

- Home-screen widgets and App Intents for safe quick actions.
- Background refresh and push-notification hardening.
- Accessibility, Dynamic Type, localisation, dark/light appearance, privacy
  declarations, telemetry-free diagnostics, and App Store/TestFlight release.

## First release definition

The first modernised beta should include milestones 0-4 for Nissan Leaf while
remaining protocol-compatible with other configured vehicles. Milestones 5-7
then close the broader Android parity gap.
