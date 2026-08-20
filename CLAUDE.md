# GET.teksi — working agreements

## CI

**After every push, wait 5 minutes, then check CI. Repeat until the run is
green.** Do not report a push as done while its run is unfinished or red.

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

Flutter lives at `/opt/flutter/bin` in this environment.
