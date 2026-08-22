#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/postgresql/lib/common.sh
source "${ROOT}/scripts/postgresql/lib/common.sh"

require_psql_connection
load_migration_env
assert_connected_as "$DEPLOYMENT_ADMIN_ROLE"

info "cleanup: revoking temporary migrator candidate-reader memberships only"
"${ROOT}/scripts/postgresql/revoke-candidate-migration-access.sh"
info "cleanup complete"
