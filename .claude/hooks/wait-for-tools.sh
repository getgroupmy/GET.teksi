#!/usr/bin/env bash
#
# Blocks until the toolchain the gates need is actually there, then prints the
# exports for it. Use it before anything that runs Flutter or touches the test
# database:
#
#   eval "$(.claude/hooks/wait-for-tools.sh)" && flutter test
#
# Status goes to stderr and the exports to stdout, so that one line both waits
# and configures the shell, and shows what happened either way.
#
# It exists because session-start.sh is asynchronous. The session begins while
# provisioning is still running behind it, which is the right trade for the
# common case — almost everything a session does needs neither Flutter nor
# PostgreSQL — but it means the first command that does need them can otherwise
# arrive too early and fail in a way that looks like a broken repository.
#
# The check is on the tools themselves rather than on the hook's marker file.
# A marker is a claim about the past: in a cached container one can survive
# from a previous session whose PostgreSQL is long gone, and a waiter that
# trusts it returns immediately and hands back a shell that cannot connect to
# anything. Looking is cheap; the marker is only read to fail fast when
# provisioning has given up.
set -uo pipefail

TIMEOUT="${TEKSI_TOOLS_TIMEOUT:-900}"
STATE=/tmp/teksi-tools
FLUTTER_ROOT=/opt/flutter

say() { printf '%s\n' "$*" >&2; }

# Off the remote container the hook never ran, and whatever is on PATH is the
# developer's own. Waiting for something that is not coming would hang.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

ready() {
  [ -x "$FLUTTER_ROOT/bin/flutter" ] || return 1
  [ -f "$STATE/env" ] || return 1
  # Only wait on PostgreSQL where there is a PostgreSQL to wait on. An image
  # without one is a container where the SQL suites cannot run at all, which
  # the hook has already said in its log — hanging here would not add a
  # database, only a delay.
  local pgbin
  pgbin="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)"
  if [ -n "$pgbin" ]; then
    "$pgbin/pg_isready" -h /tmp -p 5433 >/dev/null 2>&1 || return 1
  fi
  return 0
}

waited=0
until ready; do
  if [ -f "$STATE/outcome" ] && grep -q failed "$STATE/outcome"; then
    say "Provisioning failed. The last of $STATE/log:"
    tail -20 "$STATE/log" 2>/dev/null | sed 's/^/  /' >&2
    exit 1
  fi
  if [ "$waited" -ge "$TIMEOUT" ]; then
    say "Gave up after ${TIMEOUT}s waiting for the toolchain."
    say "$STATE/log has whatever session-start.sh managed to do."
    exit 1
  fi
  [ "$waited" -eq 0 ] && say "Waiting for session-start.sh to finish provisioning…"
  sleep 3
  waited=$((waited + 3))
done

[ "$waited" -gt 0 ] && say "Toolchain ready after ${waited}s."
cat "$STATE/env"
