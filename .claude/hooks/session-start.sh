#!/usr/bin/env bash
#
# Makes a fresh remote container able to run the gates in CLAUDE.md.
#
# Those gates are the whole point: format, analyze, the Flutter test suite, and
# the two SQL suites against a real PostgreSQL. A container that cannot run
# them turns "I verified this" into "I read it and it looked right", which is
# how a session ends up pushing at CI to find out what it could have known in
# thirty seconds.
#
# What is missing varies. Flutter has been absent from some images and present
# in others; PostgreSQL ships as binaries but with no cluster and nothing
# running. So every step here checks before it acts and is safe to run again.
#
# This runs asynchronously: the session starts straight away and provisioning
# happens behind it. Anything that needs the toolchain goes through
# wait-for-tools.sh first, which blocks until it is genuinely there.
set -euo pipefail

# Must be the first thing on stdout, before any other output.
echo '{"async": true, "asyncTimeout": 900000}'

# Local machines have their own toolchains and their own opinions about where
# things live. This only provisions the disposable remote container.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

repo="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$repo"

FLUTTER_ROOT=/opt/flutter
PGDATA=/var/lib/teksi-pg
PGPORT=5433
PGSOCKET=/tmp
PGUSER=postgres
# PostgreSQL refuses to run as root, and this container is root.
PGRUNAS=pgtest

STATE=/tmp/teksi-tools
mkdir -p "$STATE"
ENVOUT="$STATE/env"
LOG="$STATE/log"
OUTCOME="$STATE/outcome"

# Nothing below this line belongs in the session's context — it scrolls past
# while the session is already doing something else. It goes to a log the wait
# script can show if any of it went wrong.
: > "$LOG"
rm -f "$OUTCOME"
exec >>"$LOG" 2>&1

# Whatever happens, record it, so a waiter is never left guessing.
finish() {
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo ready > "$OUTCOME"
  else
    echo "failed rc=$rc" > "$OUTCOME"
  fi
}
trap finish EXIT

note() { printf '  %s\n' "$*"; }

# ---------------------------------------------------------------- Flutter ---
# The version comes from the CI workflow rather than being written twice. A
# session that provisions a different SDK from the one the build is checked
# with is a session that finds out on push.
wanted="$(
  sed -n "s/^[[:space:]]*FLUTTER_VERSION:[[:space:]]*['\"]\{0,1\}\([0-9.]*\).*/\1/p" \
    .github/workflows/ci.yml | head -1
)"
if [ -z "$wanted" ]; then
  echo "could not read FLUTTER_VERSION from .github/workflows/ci.yml"
  exit 1
fi

# Read the installed version without running Flutter, which costs ten seconds
# and needs a populated cache. The SDK is a git checkout at the release tag,
# and newer versions also drop a json file once the cache is warm — neither is
# present in every state, so try both.
git config --global --add safe.directory "$FLUTTER_ROOT" 2>/dev/null || true
have=""
if [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
  have="$(git -C "$FLUTTER_ROOT" tag --points-at HEAD 2>/dev/null | head -1)"
  if [ -z "$have" ] && [ -f "$FLUTTER_ROOT/bin/cache/flutter.version.json" ]; then
    have="$(
      sed -n 's/.*"frameworkVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        "$FLUTTER_ROOT/bin/cache/flutter.version.json" | head -1
    )"
  fi
fi

if [ "$have" != "$wanted" ]; then
  note "Installing Flutter $wanted (had '${have:-nothing}')."
  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${wanted}-stable.tar.xz"
  tmp="$(mktemp -d)"
  if ! curl -fsSL --max-time 900 -o "$tmp/flutter.tar.xz" "$url"; then
    echo "could not download Flutter $wanted from $url"
    rm -rf "$tmp"
    exit 1
  fi
  # Guarded: only ever replaces something that is already a Flutter SDK.
  if [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
    rm -rf "$FLUTTER_ROOT"
  fi
  tar xf "$tmp/flutter.tar.xz" -C /opt
  rm -rf "$tmp"
fi

export PATH="$PATH:$FLUTTER_ROOT/bin"
# Flutter and the repo are both git checkouts this container does not own.
git config --global --add safe.directory "$FLUTTER_ROOT" 2>/dev/null || true
git config --global --add safe.directory "$repo" 2>/dev/null || true

# Resolves packages and, on a new SDK, unpacks the Dart artifacts the analyzer
# and the test runner need. Doing it here rather than on first use keeps the
# cost where it is expected instead of in the middle of a task.
flutter pub get
note "Flutter $wanted ready, packages resolved."

# ------------------------------------------------------------- PostgreSQL ---
# supabase/tests/run.sh and concurrency.sh need a live server. They are the
# only check on the row-level security policies, which are the only thing
# standing between a client and somebody else's wallet — so they are worth a
# working database rather than a skip.
pgbin="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$pgbin" ]; then
  note "No PostgreSQL server in this image — the SQL suites cannot run here."
else
  export PATH="$PATH:$pgbin"
  id "$PGRUNAS" >/dev/null 2>&1 || useradd -m "$PGRUNAS"

  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    rm -rf "$PGDATA"
    mkdir -p "$PGDATA"
    chown "$PGRUNAS" "$PGDATA"
    su "$PGRUNAS" -c "$pgbin/initdb -D $PGDATA -U $PGUSER"
  fi

  if ! "$pgbin/pg_isready" -h "$PGSOCKET" -p "$PGPORT" >/dev/null 2>&1; then
    # The server runs as an unprivileged user, so its log has to be a file
    # that user can write. The state directory belongs to root: create the
    # file here and hand it over, rather than leaving pg_ctl to fail on a
    # permission error that reads like a database problem.
    : > "$STATE/pg.log"
    chown "$PGRUNAS" "$STATE/pg.log"
    # listen_addresses empty: a unix socket only. Nothing outside this
    # container has any business reaching a throwaway test database.
    su "$PGRUNAS" -c \
      "$pgbin/pg_ctl -D $PGDATA -o '-k $PGSOCKET -p $PGPORT -c listen_addresses=' -l $STATE/pg.log start" \
      || true
    for _ in $(seq 1 30); do
      "$pgbin/pg_isready" -h "$PGSOCKET" -p "$PGPORT" >/dev/null 2>&1 && break
      sleep 1
    done
  fi

  if "$pgbin/pg_isready" -h "$PGSOCKET" -p "$PGPORT" >/dev/null 2>&1; then
    note "PostgreSQL listening on $PGSOCKET:$PGPORT as $PGUSER."
  else
    echo "PostgreSQL did not come up; see $STATE/pg.log"
    exit 1
  fi
fi

# ----------------------------------------------------------- the session ----
# The exports the gates need, written where wait-for-tools.sh can hand them to
# a shell. Also appended to CLAUDE_ENV_FILE when there is one: harmless if the
# session has already read it, and free if it has not.
{
  echo "# written by .claude/hooks/session-start.sh"
  echo "export PATH=\"\$PATH:$FLUTTER_ROOT/bin${pgbin:+:$pgbin}\""
  if [ -n "$pgbin" ]; then
    echo "export PGHOST=$PGSOCKET"
    echo "export PGPORT=$PGPORT"
    echo "export PGUSER=$PGUSER"
  fi
} > "$ENVOUT"

if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -q 'session-start.sh' "$CLAUDE_ENV_FILE" 2>/dev/null; then
  cat "$ENVOUT" >> "$CLAUDE_ENV_FILE"
fi
