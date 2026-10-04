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

## graphify

There is a knowledge graph of this codebase. The skill lives in
`.claude/skills/graphify`, and the hook installs the `graphify` tool it drives
— last, and best-effort, because nothing in the gates above needs it and a
repository whose test suite will not run because an optional download failed is
worse than one without the tool.

Two `PreToolUse` guards in `.claude/settings.json` nudge toward the graph before
raw searching and reading. Both are written `command -v graphify && … || true`,
so they are silent no-ops until the asynchronous hook has finished installing —
otherwise every tool call in a cold container's first seconds would run a
command that is not there yet.

**The graph is committed**, at `graphify-out/graph.json`, alongside the
human-readable `GRAPH_REPORT.md`. It is ~3 MB, which is the price of `query`,
`path`, `explain` and `affected` working in the first minute of a cold
container instead of answering out of an empty file — and an empty answer that
looks like a real one is the worse of the two failures. Everything derived from
it — the interactive `graph.html`, the extractor cache, the input manifest, the
label sidecar, the dated backups — stays ignored.

Rebuild it with `graphify update .`, which works from the AST alone and costs
no API calls. It rewrites `graph.json` **only when the topology actually
changes** — an unchanged tree prints "no code-graph topology changes detected"
and leaves the file alone — so the artifact does not churn on every commit.
A full `/graphify .` additionally runs a semantic pass over prose, which does
cost LLM calls; the committed graph was not built that way and does not need
to be.

The `sql` extra is load-bearing. Without `tree_sitter_sql` the extractor drops
every file under `supabase/migrations/` without failing — the warning is one
line among many — and that is where the row-level security policies and the
wallet ledger live. It is the difference between 3612 nodes and 3665, 45 of
which are sourced straight out of the migrations: `private.settle_completed_ride()`,
`private.apply_wallet_delta()`, `wallet_transactions_append_only` and the rest
of the part worth asking questions about. The hook installs `graphifyy[sql]` for that reason, and does
it unconditionally, since that is the only way to add the extra to a `graphify`
an earlier session installed without it.

If `graph.json` is ever missing, the guards stay quiet rather than erroring —
`hook-guard` prints nothing when there is no graph, which is why wiring them up
is safe either way.
