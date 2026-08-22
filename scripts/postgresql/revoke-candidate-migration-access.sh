#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_psql_connection
load_migration_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"

revoke_one() {
  local candidate_role="$1"
  if has_membership "$candidate_role" "$MIGRATOR_ROLE"; then
    psql_exec -c "REVOKE ${candidate_role} FROM ${MIGRATOR_ROLE}"
  fi
  verify_membership_absent "$candidate_role" "$MIGRATOR_ROLE" "migrator post-revoke"
}

revoke_one "$EVENT_CANDIDATE_READER_ROLE"
revoke_one "$WORKFLOW_CANDIDATE_READER_ROLE"

info "temporary migrator candidate-reader membership revoked"
