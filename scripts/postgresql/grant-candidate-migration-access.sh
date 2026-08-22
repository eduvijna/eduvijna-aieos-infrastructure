#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_psql_connection
load_migration_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"
verify_deployment_admin_contract

verify_candidate_reader_attributes "$EVENT_CANDIDATE_READER_ROLE"
verify_candidate_reader_attributes "$WORKFLOW_CANDIDATE_READER_ROLE"
role_exists "$MIGRATOR_ROLE" || fail "migrator role does not exist: ${MIGRATOR_ROLE}"

if has_membership "$EVENT_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE"; then
  verify_membership_options "$EVENT_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
else
  psql_exec -c "GRANT ${EVENT_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE"
  verify_membership_options "$EVENT_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
fi

if has_membership "$WORKFLOW_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE"; then
  verify_membership_options "$WORKFLOW_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
else
  psql_exec -c "GRANT ${WORKFLOW_CANDIDATE_READER_ROLE} TO ${MIGRATOR_ROLE} WITH ADMIN FALSE, INHERIT FALSE, SET TRUE"
  verify_membership_options "$WORKFLOW_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
fi

info "temporary migrator candidate-reader SET membership granted"
