#!/usr/bin/env bash
# The Edge Function tests.
#
# Node rather than Deno, which is what actually runs them in production. The
# code under test is pure Web Crypto and fetch — identical in both — so Node
# exercises the real thing rather than a port of it, and needs no toolchain
# beyond the one already here. Type stripping means no build step.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0

# Every *.test.ts under functions/, not just the ones in _shared/.
#
# This used to glob _shared/*.test.ts, which meant a test written beside the
# function it tests would never run — and would look like it had. The handler
# went untested behind exactly that.
mapfile -t suites < <(find "${here}" -name '*.test.ts' | sort)

# A glob or find that matches nothing otherwise reports success, which is the
# same shape of lie this script exists to avoid.
if [ "${#suites[@]}" -eq 0 ]; then
  echo "NO EDGE FUNCTION TESTS FOUND — this script is not testing anything"
  exit 1
fi

for suite in "${suites[@]}"; do
  echo "── ${suite#"${here}/"}"
  node --experimental-strip-types "${suite}" || failed=1
done

if [ "${failed}" -ne 0 ]; then
  echo
  echo "EDGE FUNCTION TESTS FAILED"
  exit 1
fi

echo
echo "ALL EDGE FUNCTION TESTS PASSED"
