# GET.teksi — working agreements

## CI

**After every push, wait 5 minutes, then check CI. Repeat until the run is
green.** Do not report a push as done while its run is unfinished or red.

**One run at a time.** Never push while a run is still going. Finish the
current one first — green or red — and batch further work into the next push.
A push that lands mid-run cancels the run in flight (`cancel-in-progress`),
which throws away minutes already spent and leaves the superseded commit with
no verdict of its own.

Each round:

1. Wait ~5 minutes (`sleep 300` in the background), then read the run's status.
2. Still in progress → wait another 5 minutes and check again.
3. Failed → fetch the failing job's log, fix the cause, push, and start the
   loop over from step 1.
4. Green → say so, naming the jobs that passed.

Two failures are **not** mine to fix by pushing code, and looping on them just
burns minutes:

- **No runner was assigned** — the job shows `runner_id: 0`, no steps, and
  completes within a few seconds, with no logs to fetch. This is an
  Actions capacity or billing problem, not a build problem. Re-run once; if it
  repeats, stop and tell the user what to check.
- **A failure that reproduces on the default branch**, i.e. one this branch did
  not cause. Say so once and stop pushing at it.

Anything else, keep going until it is green.

## Verification

Claims about the build are worth what the evidence behind them is worth. Before
saying something passes, read the actual output — a job that never ran is not a
job that passed, and a check that greps for the wrong string can be green and
meaningless at the same time. Where a check asserts an invariant, make it
self-checking so a silent no-op cannot look like a clean result.

## Local gates

These are what CI runs; run them before pushing.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test
supabase/tests/run.sh          # needs a local PostgreSQL
supabase/tests/concurrency.sh
```

`.claude/hooks/session-start.sh` provisions all of that on a remote container:
Flutter at the version `.github/workflows/ci.yml` pins, the packages resolved,
and a local PostgreSQL listening on a socket.

**It runs asynchronously**, so the session starts before it has finished. Put
the waiter in front of the first command that needs any of it:

```sh
eval "$(.claude/hooks/wait-for-tools.sh)"
```

That blocks until the toolchain is genuinely there — it checks the tools
themselves, not a marker file, so a stale one from an earlier session in a
cached container cannot hand back a shell that connects to nothing — and then
prints the PATH and `PG*` exports, so the commands above run exactly as
written. It returns in milliseconds once provisioning is done, so there is no
cost to running it before every batch of gates, and it says so on stderr when
provisioning has failed rather than letting the failure arrive as a confusing
error from Flutter.

The hook itself is idempotent and does nothing at all outside a remote
container, where your own toolchain is already in charge. The first run on a
new container image spends a few minutes fetching the Flutter SDK; after that
the image is cached and later sessions are ready in seconds.
