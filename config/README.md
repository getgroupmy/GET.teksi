# Build configuration

`--dart-define-from-file` takes one of these instead of a pair of
`--dart-define` flags:

```sh
flutter run   --dart-define-from-file=config/get-teksi.json
flutter build web --release --no-web-resources-cdn \
              --dart-define-from-file=config/get-teksi.json
```

Omit the flag entirely and the app runs on its on-device transport with the
simulated marketplace — every screen still works, nothing is provisioned.

## Why the key is in the repository

`SUPABASE_PUBLISHABLE_KEY` is a public identifier, not a secret. It ships
inside every copy of the app that reaches a phone, so hiding it here would
protect nothing: anyone holding the built app holds the key. What actually
protects the data is row-level security, which is why the policies in
`supabase/` are tested as carefully as the app itself.

The key that must never appear here — or in any build — is the **service
role** key. It bypasses row-level security completely.

For a different project, copy this file to `config/local.json` (gitignored)
and point the flag at that instead.
