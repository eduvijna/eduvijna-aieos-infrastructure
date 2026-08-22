#!/usr/bin/env bash
# Disposable PostgreSQL 18 CI proof for ADR-AIEOS-045 identity bootstrap scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_cmd psql

PGVERSION="$(psql_query -c "SELECT version()")"
if [[ ! "$PGVERSION" =~ PostgreSQL\ 18\. ]]; then
  fail "expected PostgreSQL 18.x, got: ${PGVERSION}"
fi
info "connected to ${PGVERSION}"

export AIEOS_DB_DEPLOYMENT_ADMIN_ROLE="${AIEOS_DB_DEPLOYMENT_ADMIN_ROLE:-aieos_db_deployment_admin}"
export AIEOS_EVENT_CANDIDATE_READER_ROLE="${AIEOS_EVENT_CANDIDATE_READER_ROLE:-aieos_event_candidate_reader}"
export AIEOS_WORKFLOW_CANDIDATE_READER_ROLE="${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE:-aieos_workflow_candidate_reader}"
export AIEOS_MIGRATOR_ROLE="${AIEOS_MIGRATOR_ROLE:-aieos_migrator}"
export AIEOS_RUNTIME_ROLE="${AIEOS_RUNTIME_ROLE:-aieos_runtime}"
export AIEOS_EVENT_DISPATCHER_ROLE="${AIEOS_EVENT_DISPATCHER_ROLE:-aieos_event_dispatcher}"
export AIEOS_WORKFLOW_DISPATCHER_ROLE="${AIEOS_WORKFLOW_DISPATCHER_ROLE:-aieos_workflow_dispatcher}"
export AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE="${AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE:-aieos_content_migration_runtime}"

for var in \
  AIEOS_DB_DEPLOYMENT_ADMIN_ROLE \
  AIEOS_EVENT_CANDIDATE_READER_ROLE \
  AIEOS_WORKFLOW_CANDIDATE_READER_ROLE \
  AIEOS_MIGRATOR_ROLE \
  AIEOS_RUNTIME_ROLE \
  AIEOS_EVENT_DISPATCHER_ROLE \
  AIEOS_WORKFLOW_DISPATCHER_ROLE \
  AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE
do
  validate_role_name "${!var}" "$var"
done

if [[ "$AIEOS_EVENT_CANDIDATE_READER_ROLE" == "$AIEOS_WORKFLOW_CANDIDATE_READER_ROLE" ]]; then
  fail "event and workflow candidate roles must differ in CI"
fi

psql_exec <<SQL
DROP ROLE IF EXISTS ${AIEOS_EVENT_DISPATCHER_ROLE};
DROP ROLE IF EXISTS ${AIEOS_WORKFLOW_DISPATCHER_ROLE};
DROP ROLE IF EXISTS ${AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE};
DROP ROLE IF EXISTS ${AIEOS_RUNTIME_ROLE};
DROP ROLE IF EXISTS ${AIEOS_MIGRATOR_ROLE};
DROP ROLE IF EXISTS ${AIEOS_EVENT_CANDIDATE_READER_ROLE};
DROP ROLE IF EXISTS ${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE};
DROP ROLE IF EXISTS ${AIEOS_DB_DEPLOYMENT_ADMIN_ROLE};
DROP ROLE IF EXISTS ${AIEOS_EVENT_CANDIDATE_READER_ROLE}_bad;
DROP ROLE IF EXISTS ${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE}_bad;
SQL

psql_exec <<SQL
CREATE ROLE ${AIEOS_DB_DEPLOYMENT_ADMIN_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' CREATEROLE NOCREATEDB NOBYPASSRLS NOSUPERUSER NOREPLICATION;
CREATE ROLE ${AIEOS_MIGRATOR_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' NOCREATEDB NOCREATEROLE NOBYPASSRLS NOSUPERUSER;
CREATE ROLE ${AIEOS_RUNTIME_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' NOBYPASSRLS NOSUPERUSER;
CREATE ROLE ${AIEOS_EVENT_DISPATCHER_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' NOBYPASSRLS NOSUPERUSER;
CREATE ROLE ${AIEOS_WORKFLOW_DISPATCHER_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' NOBYPASSRLS NOSUPERUSER;
CREATE ROLE ${AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE} LOGIN PASSWORD 'ci_bootstrap_only' NOBYPASSRLS NOSUPERUSER;
SQL

run_as_deployment_admin() {
  PGUSER="$AIEOS_DB_DEPLOYMENT_ADMIN_ROLE" PGPASSWORD='ci_bootstrap_only' "$@"
}

run_as_migrator() {
  PGUSER="$AIEOS_MIGRATOR_ROLE" PGPASSWORD='ci_bootstrap_only' "$@"
}

assert_no_migrator_jit_membership() {
  local event_edge workflow_edge
  event_edge="$(psql_query -c "
    SELECT COUNT(*)
    FROM pg_auth_members am
    JOIN pg_roles granted ON granted.oid = am.roleid
    JOIN pg_roles member ON member.oid = am.member
    WHERE granted.rolname = '${AIEOS_EVENT_CANDIDATE_READER_ROLE}'
      AND member.rolname = '${AIEOS_MIGRATOR_ROLE}'
  ")"
  workflow_edge="$(psql_query -c "
    SELECT COUNT(*)
    FROM pg_auth_members am
    JOIN pg_roles granted ON granted.oid = am.roleid
    JOIN pg_roles member ON member.oid = am.member
    WHERE granted.rolname = '${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE}'
      AND member.rolname = '${AIEOS_MIGRATOR_ROLE}'
  ")"
  [[ "$event_edge" == "0" ]] || fail "expected no migrator JIT edge for event candidate-reader"
  [[ "$workflow_edge" == "0" ]] || fail "expected no migrator JIT edge for workflow candidate-reader"
}

assert_script_fails() {
  local label="$1"
  shift
  if "$@"; then
    fail "expected failure did not occur: ${label}"
  fi
}

run_as_deployment_admin "${ROOT}/scripts/postgresql/bootstrap-candidate-readers.sh"
AIEOS_VERIFY_MODE=baseline run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"
run_as_deployment_admin "${ROOT}/scripts/postgresql/bootstrap-candidate-readers.sh"

# Adversarial: existing LOGIN candidate role must fail closed.
psql_exec -c "CREATE ROLE ${AIEOS_EVENT_CANDIDATE_READER_ROLE}_bad LOGIN NOBYPASSRLS NOSUPERUSER"
assert_script_fails "LOGIN candidate role" run_as_deployment_admin env \
  AIEOS_EVENT_CANDIDATE_READER_ROLE="${AIEOS_EVENT_CANDIDATE_READER_ROLE}_bad" \
  "${ROOT}/scripts/postgresql/bootstrap-candidate-readers.sh"
psql_exec -c "DROP ROLE ${AIEOS_EVENT_CANDIDATE_READER_ROLE}_bad"

psql_exec -c "CREATE ROLE ${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE}_bad NOLOGIN BYPASSRLS NOSUPERUSER"
assert_script_fails "BYPASSRLS candidate role" run_as_deployment_admin env \
  AIEOS_WORKFLOW_CANDIDATE_READER_ROLE="${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE}_bad" \
  "${ROOT}/scripts/postgresql/bootstrap-candidate-readers.sh"
psql_exec -c "DROP ROLE ${AIEOS_WORKFLOW_CANDIDATE_READER_ROLE}_bad"

assert_script_fails "missing libpq connection contract" \
  env -u PGSERVICE -u PGHOST -u PGDATABASE \
  PGUSER="$AIEOS_DB_DEPLOYMENT_ADMIN_ROLE" PGPASSWORD='ci_bootstrap_only' \
  AIEOS_DB_DEPLOYMENT_ADMIN_ROLE="$AIEOS_DB_DEPLOYMENT_ADMIN_ROLE" \
  AIEOS_EVENT_CANDIDATE_READER_ROLE="$AIEOS_EVENT_CANDIDATE_READER_ROLE" \
  AIEOS_WORKFLOW_CANDIDATE_READER_ROLE="$AIEOS_WORKFLOW_CANDIDATE_READER_ROLE" \
  "${ROOT}/scripts/postgresql/bootstrap-candidate-readers.sh"

DEMO_ROLE="aieos_candidate_privilege_demo"
psql_exec -c "CREATE ROLE ${DEMO_ROLE} NOLOGIN NOBYPASSRLS NOSUPERUSER"
psql_exec -c "GRANT ${DEMO_ROLE} TO ${AIEOS_EVENT_CANDIDATE_READER_ROLE} WITH INHERIT TRUE"
assert_script_fails "candidate-reader outbound membership" \
  run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"
psql_exec -c "REVOKE ${DEMO_ROLE} FROM ${AIEOS_EVENT_CANDIDATE_READER_ROLE}"
psql_exec -c "DROP ROLE ${DEMO_ROLE}"
AIEOS_VERIFY_MODE=baseline run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"

run_as_deployment_admin "${ROOT}/scripts/postgresql/grant-candidate-migration-access.sh"
AIEOS_VERIFY_MODE=jit run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"
run_as_migrator psql_exec <<SQL
SET ROLE ${AIEOS_EVENT_CANDIDATE_READER_ROLE};
SELECT current_user;
RESET ROLE;
SQL

run_as_deployment_admin "${ROOT}/scripts/postgresql/revoke-candidate-migration-access.sh"
assert_no_migrator_jit_membership
assert_script_fails "jit second-grant transaction rollback" \
  run_as_deployment_admin env AIEOS_CI_INJECT_JIT_SECOND_GRANT_FAILURE=1 \
  "${ROOT}/scripts/postgresql/grant-candidate-migration-access.sh"
assert_no_migrator_jit_membership

# Simulate interrupted deployment: grant again then cleanup.
run_as_deployment_admin "${ROOT}/scripts/postgresql/grant-candidate-migration-access.sh"
run_as_deployment_admin "${ROOT}/scripts/postgresql/cleanup-candidate-migration-access.sh"
AIEOS_VERIFY_MODE=baseline run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"

run_as_deployment_admin "${ROOT}/scripts/postgresql/grant-candidate-migration-access.sh"
run_as_deployment_admin "${ROOT}/scripts/postgresql/revoke-candidate-migration-access.sh"
AIEOS_VERIFY_MODE=baseline run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"

# Forbidden dispatcher membership must fail verification if present.
psql_exec -c "GRANT ${AIEOS_EVENT_CANDIDATE_READER_ROLE} TO ${AIEOS_EVENT_DISPATCHER_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET FALSE"
assert_script_fails "dispatcher membership" run_as_deployment_admin "${ROOT}/scripts/postgresql/verify-candidate-readers.sh"
psql_exec -c "REVOKE ${AIEOS_EVENT_CANDIDATE_READER_ROLE} FROM ${AIEOS_EVENT_DISPATCHER_ROLE}"

# Prove scripts did not create application schemas/functions.
schema_count="$(psql_query -c "SELECT COUNT(*) FROM pg_namespace WHERE nspname IN ('integration', 'workflow')")"
[[ "$schema_count" == "0" ]] || fail "application schemas must not be created by infrastructure bootstrap CI"

function_count="$(psql_query -c "
  SELECT COUNT(*)
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE proname IN (
    'list_outbox_dispatch_candidates',
    'list_start_intent_candidates',
    'list_command_intent_candidates'
  )
")"
[[ "$function_count" == "0" ]] || fail "application candidate functions must not be created in infrastructure phase"

info "postgresql identity bootstrap CI proof complete"
