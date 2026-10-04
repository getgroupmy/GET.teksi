#!/usr/bin/env bash
# Applies the migration to a throwaway database and runs the policy suite.
# Needs nothing but a local PostgreSQL 14+; no Supabase project is involved.
#
#   supabase/tests/run.sh                 # uses a local socket as $USER
#   PGHOST=localhost PGUSER=postgres supabase/tests/run.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
db="${TEKSI_TEST_DB:-teksi_policy_test}"
psql_opts=(-v ON_ERROR_STOP=1 -q --no-psqlrc)

psql "${psql_opts[@]}" -d postgres -tAc "drop database if exists ${db}"
psql "${psql_opts[@]}" -d postgres -tAc "create database ${db}"

psql "${psql_opts[@]}" -d "${db}" -f "${here}/harness.sql" 2>&1 \
  | grep -v 'wal_level\|HINT:' || true
for migration in "${here}"/../migrations/*.sql; do
  psql "${psql_opts[@]}" -d "${db}" -f "${migration}"
done
psql "${psql_opts[@]}" -d "${db}" -f "${here}/policies.sql"
