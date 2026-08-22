#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_psql_connection
load_identity_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"
verify_deployment_admin_contract

bootstrap_one_candidate_reader "$EVENT_CANDIDATE_READER_ROLE"
bootstrap_one_candidate_reader "$WORKFLOW_CANDIDATE_READER_ROLE"

verify_deployment_admin_baseline_edge "$EVENT_CANDIDATE_READER_ROLE"
verify_deployment_admin_baseline_edge "$WORKFLOW_CANDIDATE_READER_ROLE"

info "candidate-reader bootstrap complete"
