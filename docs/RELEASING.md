# Releasing

What a machine can do, and what only the account holder can.

The build is automated. Everything upstream of it — the Apple Developer
membership, the certificate, the App Store Connect record, the review — is not
automatable and is not meant to be. This file separates the two so nobody
spends an afternoon looking for a script that cannot exist.

---

## iOS

### Status

| | |
|---|---|
| Builds unsigned in CI | ✅ every push, `build-ios` |
| Builds a signed `.ipa` | ✅ `Release iOS` workflow, once the secrets exist |
| Uploads to TestFlight | ✅ same workflow, `destination: testflight` |
| Has ever actually run | ❌ **no**. It has never been run against a real Apple account. |
| Ready for App Review | ❌ see [Before submitting](#before-submitting) |

The signing and upload path has never executed. It is written from Apple's
documented behaviour, not from a green run, and the first attempt should be
`destination: validate` for exactly that reason.

### What you have to do by hand, once

None of this can be done from a repository.

1. **Apple Developer Program membership** — $99/year. A company membership also
   needs a D-U-N-S number, which can take a week or two to obtain.
2. **Register the bundle identifier** `my.getgroup.getTeksi` under Certificates,
   Identifiers & Profiles. It must match `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj`; the workflow asserts this and stops
   if the two ever disagree.
3. **Create the app record** in App Store Connect against that identifier.
4. **Create an Apple Distribution certificate** and export it as `.p12` *with
   its private key*. A `.cer` downloaded from the portal is only half of one and
   cannot sign anything.
5. **Create an App Store provisioning profile** for the identifier, using that
   certificate.
6. **Create an App Store Connect API key** with the App Manager role. The `.p8`
   downloads exactly once — Apple will not show it again.

### The seven secrets

Repository Settings → Secrets and variables → Actions. Values marked *base64*
must be encoded, because a secret is a string and these are binary:

| Secret | What it is |
|---|---|
| `APPLE_CERTIFICATE_P12` | *base64* of the distribution `.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | the password set when exporting it |
| `APPLE_PROVISIONING_PROFILE` | *base64* of the `.mobileprovision` |
| `APPLE_TEAM_ID` | the 10-character team id from the developer portal |
| `APP_STORE_CONNECT_KEY_ID` | the API key's id |
| `APP_STORE_CONNECT_ISSUER_ID` | the issuer UUID, shown above the key list |
| `APP_STORE_CONNECT_PRIVATE_KEY` | *base64* of the `AuthKey_XXXXX.p8` |

```sh
base64 -i Certificates.p12 | pbcopy          # macOS
base64 -w0 Certificates.p12                  # Linux
```

The workflow checks all seven before doing anything else, so a missing one
fails in a second with its own name in the error rather than eight minutes into
a build.

### Running it

Actions → **Release iOS** → Run workflow.

- `destination: validate` (the default) builds, signs, and runs Apple's own
  checks on the result. **It uploads nothing.** Run this first, always.
- `destination: testflight` does the same and then uploads.

The default is `validate` on purpose: an upload is visible to other people, and
a workflow that ships on a branch push eventually ships a branch nobody meant
to. There is no push or tag trigger for the same reason.

The build number defaults to the workflow run number, which only ever goes up —
App Store Connect refuses a build number it has already seen, and the `+1` in
`pubspec.yaml` has never changed.

### Before submitting

Passing validation is not the same as passing review. Three things about *this*
app, in rough order of how likely they are to come back:

- **The simulated marketplace.** The app ships with bot drivers and bot
  passengers, switched on by default in Settings. A reviewer seeing fabricated
  drivers presented as a live service is a 2.3 "accurate metadata" problem, and
  a build whose real backend has no counterparty is a 4.2 "minimum
  functionality" problem. Decide which one the reviewer sees before you submit,
  not after.
- **A demo account.** App Review needs working credentials in the review notes.
  Sign-in is phone plus an OTP, so this means either a number a reviewer can
  actually receive a code on, or a test number configured in Supabase Auth with
  a fixed code.
- **Location.** The app asks for location while in use and, on Android, keeps
  reporting a driver's position from a foreground service. Expect to justify
  both. `NSLocationWhenInUseUsageDescription` is set;
  `ios/Runner/PrivacyInfo.xcprivacy` declares precise location as collected and
  linked, and the privacy labels on the listing have to say the same thing.

### Background delivery

The app has no push transport, so notifications stop when the process does.
That is a documented limitation rather than a bug — see
[PLATFORMS.md](PLATFORMS.md) — but it is worth knowing before someone promises
a driver they will hear about an order with the app closed.

---

## Android

There is no release workflow, and one would be premature: **the release build
still signs with the debug key**, as `android/app/build.gradle.kts` says in its
own comment. An APK signed that way installs and runs, and neither Play nor
AppGallery will accept it.

Before there is anything to automate:

1. Generate an upload keystore and store it somewhere that is not this
   repository.
2. Replace `signingConfig = signingConfigs.getByName("debug")` in the release
   block with a real one, reading its credentials from
   `android/key.properties` (git-ignored) or from environment variables.

Once that exists, the release job is the easy half — `flutter build appbundle`
plus the same GMS-free dex scan CI already runs.

---

## What CI already guarantees

Every push runs the checks in [PLATFORMS.md](PLATFORMS.md): format, analyze,
the test suite, the database policy suite, a GMS-free scan of the release APK's
dex, and — for this file's purposes — an assertion that
`PrivacyInfo.xcprivacy` is inside the built `.app`. That last one exists
because a resource can be in the repository and absent from the target's
resources phase, which builds cleanly and ships nothing.
