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

### Status

`.github/workflows/release-android.yml` builds a signed App Bundle and APK on
`workflow_dispatch`. It does not upload to a store — see **Publishing** below.

The release build takes its upload key from `android/key.properties`
(git-ignored) if that exists, otherwise from `ANDROID_KEYSTORE_*` in the
environment, otherwise from the debug keystore. That last fallback is there so
that `ci.yml` can build a release APK on every push to scan its dex, and so
anyone can run `flutter build apk --release` locally, without either needing
the upload key.

The fallback is also the trap. **A debug-signed release build installs, runs,
and passes every check in `ci.yml`** — the first thing to notice would be
Play's rejection notice. So a build meant to ship *demands* the key, which
turns the fallback into a configuration-time error. Either form does it:

- `REQUIRE_UPLOAD_KEY=1` in the environment, which is what the release
  workflow sets, because `flutter build` does not promise to forward an
  arbitrary `-P` to the Gradle it spawns.
- `-PrequireUploadKey=true` for a direct `./gradlew` invocation.

`ci.yml` asserts that the guard genuinely fails without a key, so it cannot
rot unnoticed.

### What you have to do by hand, once

Generate an upload keystore. Keep it somewhere that is not this repository and
back it up: **if you lose it you cannot update the app**, only publish a new
listing, unless the app is enrolled in Play App Signing with a recoverable key.

```sh
keytool -genkeypair -v \
  -keystore upload.jks \
  -alias upload \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storetype PKCS12
```

4096 bits and ~27 years because this key has to outlive every version of the
app. Play requires at least 2048-bit RSA and a validity ending after 22 October
2033.

Note the SHA-256 fingerprint it prints — the workflow can pin it (below).

```sh
keytool -list -v -keystore upload.jks -alias upload | grep SHA256
```

### The four secrets

Repository → Settings → Secrets and variables → Actions:

| Secret | Where it comes from |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | the `-storepass` you chose |
| `ANDROID_KEY_ALIAS` | `upload`, unless you chose otherwise |
| `ANDROID_KEY_PASSWORD` | the key password; same as the store password for a PKCS12 keystore |

And one optional fifth, worth setting:

| Secret | Effect |
| --- | --- |
| `ANDROID_KEY_SHA256` | The fingerprint from above. The workflow then asserts the artifact was signed with *that* key, rather than merely not the debug one. |

Without it the run prints the fingerprint it actually used and says it is not
pinned. Not-the-debug-key rules out one wrong key; the fingerprint rules out
all of them.

### Building by hand

Create `android/key.properties` — git-ignored, as is `*.jks`:

```properties
storeFile=../upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

A relative `storeFile` is resolved against `android/`, not `android/app/`.

```sh
REQUIRE_UPLOAD_KEY=1 flutter build appbundle --release --build-number=<n>
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

That last line is the check worth running: it reads the signer out of the
artifact rather than trusting what the build said it did.

### Running the workflow

Actions → **Release Android** → Run workflow. `build_number` becomes the
`versionCode`, and defaults to the run number, which only ever goes up — Play
refuses a `versionCode` it has already seen.

It asserts, in order: the four secrets exist; the application id is still
`my.getgroup.get_teksi`; the base64 decodes to a keystore that password opens;
the alias is in it; the bundle's signer is not `CN=Android Debug` and matches
the pinned fingerprint if one is set; the APK's signer likewise, read with
`apksigner` rather than `keytool` because an APK can be v2-signed only; and the
signed APK's dex is still free of GMS, Firebase and HMS classes. Artifacts —
`.aab`, `.apk` and the ProGuard `mapping.txt` — are kept for 14 days. The
keystore is removed from the runner whatever happens.

Keep `mapping.txt`. Without it a stack trace from a release crash is
unreadable, and it is regenerable only from the exact same build.

### Publishing

Not automated, deliberately. Play wants a Google Play Developer API service
account and AppGallery its own Connect API credentials, and each is a separate
set of secrets with permission to publish to the public under your developer
identity. Uploading the `.aab` by hand the first few times is also how you find
out what the console asks for that no workflow can answer — the data safety
form, the content rating questionnaire, the privacy policy URL.

When it is worth automating, the pieces are `r0adkll/upload-google-play` for
Play and AppGallery's publish API for Huawei, both gated on their secrets the
way the iOS workflow gates on Apple's.

---

## What CI already guarantees

Every push runs the checks in [PLATFORMS.md](PLATFORMS.md): format, analyze,
the test suite, the database policy suite, a GMS-free scan of the release APK's
dex, and — for this file's purposes — two assertions about shipping.

`PrivacyInfo.xcprivacy` is inside the built `.app`. That one exists because a
resource can be in the repository and absent from the target's resources
phase, which builds cleanly and ships nothing.

A release build that demands an upload key fails when none is configured.
That one exists because the release build's fall back to the debug key is what keeps CI
and `flutter build apk --release` working, and a fallback nobody notices is how
a debug-signed artifact gets as far as a store. The check greps for the
guard's own error message, so a Gradle failure for any other reason fails the
check rather than satisfying it.

Both are the same shape of problem: a thing that is wrong in a way that still
builds.
