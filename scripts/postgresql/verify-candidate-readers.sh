#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_psql_connection
load_identity_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"

VERIFY_MODE="${AIEOS_VERIFY_MODE:-baseline}"
if [[ "$VERIFY_MODE" != "baseline" && "$VERIFY_MODE" != "jit" ]]; then
  fail "AIEOS_VERIFY_MODE must be 'baseline' or 'jit'"
fi

verify_deployment_admin_contract
verify_candidate_reader_attributes "$EVENT_CANDIDATE_READER_ROLE"
verify_candidate_reader_attributes "$WORKFLOW_CANDIDATE_READER_ROLE"

verify_deployment_admin_baseline_edge "$EVENT_CANDIDATE_READER_ROLE"
verify_deployment_admin_baseline_edge "$WORKFLOW_CANDIDATE_READER_ROLE"
assert_set_role_denied "$EVENT_CANDIDATE_READER_ROLE"
assert_set_role_denied "$WORKFLOW_CANDIDATE_READER_ROLE"

verify_no_outbound_role_memberships "$EVENT_CANDIDATE_READER_ROLE"
verify_no_outbound_role_memberships "$WORKFLOW_CANDIDATE_READER_ROLE"

verify_no_schema_ownership "$EVENT_CANDIDATE_READER_ROLE"
verify_no_schema_ownership "$WORKFLOW_CANDIDATE_READER_ROLE"
verify_no_table_ownership "$EVENT_CANDIDATE_READER_ROLE"
verify_no_table_ownership "$WORKFLOW_CANDIDATE_READER_ROLE"
verify_no_unexpected_schema_create "$EVENT_CANDIDATE_READER_ROLE"
verify_no_unexpected_schema_create "$WORKFLOW_CANDIDATE_READER_ROLE"

if [[ "$EVENT_CANDIDATE_READER_ROLE" == "$WORKFLOW_CANDIDATE_READER_ROLE" ]]; then
  fail "event and workflow candidate-reader roles must be distinct"
fi

MIGRATOR_ROLE="${AIEOS_MIGRATOR_ROLE:-}"
RUNTIME_ROLE="${AIEOS_RUNTIME_ROLE:-}"
EVENT_DISPATCHER_ROLE="${AIEOS_EVENT_DISPATCHER_ROLE:-}"
WORKFLOW_DISPATCHER_ROLE="${AIEOS_WORKFLOW_DISPATCHER_ROLE:-}"
MIGRATION_RUNTIME_ROLE="${AIEOS_CONTENT_MIGRATION_RUNTIME_ROLE:-}"

for role_var in MIGRATOR_ROLE RUNTIME_ROLE EVENT_DISPATCHER_ROLE WORKFLOW_DISPATCHER_ROLE MIGRATION_RUNTIME_ROLE; do
  value="${!role_var:-}"
  if [[ -n "$value" ]]; then
    validate_role_name "$value" "${role_var}"
  fi
done

if [[ -n "$MIGRATOR_ROLE" ]]; then
  if [[ "$VERIFY_MODE" == "jit" ]]; then
    verify_membership_options "$EVENT_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
    verify_membership_options "$WORKFLOW_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "false" "false" "true"
  else
    verify_membership_absent "$EVENT_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "migrator baseline"
    verify_membership_absent "$WORKFLOW_CANDIDATE_READER_ROLE" "$MIGRATOR_ROLE" "migrator baseline"
  fi
fi

for forbidden_member in "$RUNTIME_ROLE" "$EVENT_DISPATCHER_ROLE" "$WORKFLOW_DISPATCHER_ROLE" "$MIGRATION_RUNTIME_ROLE"; do
  if [[ -n "$forbidden_member" ]]; then
    verify_membership_absent "$EVENT_CANDIDATE_READER_ROLE" "$forbidden_member" "runtime/dispatcher"
    verify_membership_absent "$WORKFLOW_CANDIDATE_READER_ROLE" "$forbidden_member" "runtime/dispatcher"
  fi
done

info "candidate-reader verification passed (mode=${VERIFY_MODE})"
