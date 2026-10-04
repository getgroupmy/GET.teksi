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

for suite in "${here}"/_shared/*.test.ts; do
  echo "── $(basename "${suite}")"
  node --experimental-strip-types "${suite}" || failed=1
done

if [ "${failed}" -ne 0 ]; then
  echo
  echo "EDGE FUNCTION TESTS FAILED"
  exit 1
fi

echo
echo "ALL EDGE FUNCTION TESTS PASSED"
