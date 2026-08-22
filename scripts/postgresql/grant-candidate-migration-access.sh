#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

best_effort_jit_cleanup() {
  "${ROOT}/scripts/postgresql/revoke-candidate-migration-access.sh" >/dev/null 2>&1 || true
}

require_psql_connection
load_migration_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"
verify_deployment_admin_contract

verify_candidate_reader_attributes "$EVENT_CANDIDATE_READER_ROLE"
verify_candidate_reader_attributes "$WORKFLOW_CANDIDATE_READER_ROLE"
verify_deployment_admin_baseline_edge "$EVENT_CANDIDATE_READER_ROLE"
verify_deployment_admin_baseline_edge "$WORKFLOW_CANDIDATE_READER_ROLE"
role_exists "$MIGRATOR_ROLE" || fail "migrator role does not exist: ${MIGRATOR_ROLE}"

verify_jit_migrator_membership_absent_or_exact "$EVENT_CANDIDATE_READER_ROLE"
verify_jit_migrator_membership_absent_or_exact "$WORKFLOW_CANDIDATE_READER_ROLE"

if jit_membership_already_exact; then
  verify_jit_migrator_memberships_exact
  info "temporary migrator candidate-reader SET membership already exact"
  exit 0
fi

if [[ "${AIEOS_CI_INJECT_JIT_SECOND_GRANT_FAILURE:-}" == "1" ]]; then
  psql_exec <<SQL
BEGIN;
GRANT ${EVENT_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE;
DO \$do\$ BEGIN RAISE EXCEPTION 'ci second grant failure simulation'; END \$do\$;
GRANT ${WORKFLOW_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE;
COMMIT;
SQL
  fail "CI second grant failure simulation did not abort the transaction"
fi

if ! psql_exec <<SQL
BEGIN;
GRANT ${EVENT_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE;
GRANT ${WORKFLOW_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE;
COMMIT;
SQL
then
  best_effort_jit_cleanup
  fail "JIT grant transaction failed; rolled back with best-effort cleanup attempted"
fi

if ! verify_jit_migrator_memberships_exact; then
  best_effort_jit_cleanup
  fail "post-commit JIT membership verification failed; best-effort cleanup attempted"
fi

info "temporary migrator candidate-reader SET membership granted"
