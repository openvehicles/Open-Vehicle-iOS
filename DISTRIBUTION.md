# iPhone and TestFlight distribution

The `iOS device distribution` workflow creates a signed IPA on a GitHub-hosted Mac and can optionally upload it to TestFlight. Signing material is only installed in the temporary runner keychain.

## Apple setup

Create an explicit App ID and App Store provisioning profile with Push Notifications enabled. The workflow's `bundle_identifier` input must match that App ID and the App Store Connect application.

Configure the repository `testflight` environment with these secrets:

- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`: base64-encoded Apple Distribution `.p12` file.
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`: password protecting that `.p12` file.
- `APPLE_PROVISIONING_PROFILE_BASE64`: base64-encoded App Store `.mobileprovision` file.
- `APPLE_TEAM_ID`: the ten-character Apple Developer team identifier.
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key identifier, required only for upload.
- `APP_STORE_CONNECT_API_ISSUER_ID`: App Store Connect issuer identifier, required only for upload.
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`: base64-encoded `AuthKey_*.p8`, required only for upload.

Restrict the environment secrets to trusted maintainers and optionally require environment approval. Never add certificates, profiles, passwords, or API keys to the repository.

## Running the workflow

Open **Actions → iOS device distribution → Run workflow**, enter the registered bundle ID, and initially leave TestFlight upload disabled. Download and validate the seven-day `ovms-device-ipa-*` artifact. Once archive/export succeeds, rerun with upload enabled. App Store Connect processing can then make the build available to an internal tester's iPhone.

The workflow uses the GitHub run number as `CFBundleVersion`, so every uploaded build has a unique monotonically increasing build number.
