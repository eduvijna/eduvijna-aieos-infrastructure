#!/usr/bin/env bash
# Shared helpers for ADR-AIEOS-045 PostgreSQL identity bootstrap scripts.
set -euo pipefail

fail() {
  echo "BOOTSTRAP_FAIL: $*" >&2
  exit 1
}

info() {
  echo "BOOTSTRAP_INFO: $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

validate_role_name() {
  local name="$1"
  local label="${2:-role name}"
  if [[ ! "$name" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    fail "invalid ${label}: must match ^[a-z_][a-z0-9_]*$"
  fi
}

sql_role_literal() {
  validate_role_name "$1" "SQL role literal"
  printf "'%s'" "$1"
}

require_env_role() {
  local var="$1"
  local label="$2"
  local value="${!var:-}"
  if [[ -z "$value" ]]; then
    fail "required environment variable ${var} is not set (${label})"
  fi
  validate_role_name "$value" "$label"
  printf '%s' "$value"
}

require_psql_connection() {
  require_cmd psql
  if [[ -z "${PGHOST:-}" && -z "${PGDATABASE:-}" && -z "${PGUSER:-}" && -z "${PGSERVICE:-}" && -z "${DATABASE_URL:-}" ]]; then
    fail "PostgreSQL connection not configured; set PG* variables or DATABASE_URL externally"
  fi
}

psql_exec() {
  # Never print connection strings or passwords.
  psql -v ON_ERROR_STOP=1 -X -q "$@"
}

psql_query() {
  psql_exec -At "$@"
}

load_identity_env() {
  DEPLOYMENT_ADMIN_ROLE="$(require_env_role AIEOS_DB_DEPLOYMENT_ADMIN_ROLE "deployment admin role")"
  EVENT_CANDIDATE_READER_ROLE="$(require_env_role AIEOS_EVENT_CANDIDATE_READER_ROLE "event candidate-reader role")"
  WORKFLOW_CANDIDATE_READER_ROLE="$(require_env_role AIEOS_WORKFLOW_CANDIDATE_READER_ROLE "workflow candidate-reader role")"
}

load_migration_env() {
  load_identity_env
  MIGRATOR_ROLE="$(require_env_role AIEOS_MIGRATOR_ROLE "migrator role")"
}

assert_connected_as() {
  local expected="$1"
  local current
  current="$(psql_query -c "SELECT current_user")"
  if [[ "$current" != "$expected" ]]; then
    fail "connected as '${current}' but expected '${expected}' (set PGUSER to deployment admin identity)"
  fi
}

role_exists() {
  local role="$1"
  local count
  count="$(psql_query -c "SELECT COUNT(*) FROM pg_roles WHERE rolname = $(sql_role_literal "$role")")"
  [[ "$count" == "1" ]]
}

role_attributes_row() {
  local role="$1"
  psql_query -c "SELECT rolcanlogin::text, rolsuper::text, rolcreatedb::text, rolcreaterole::text, rolreplication::text, rolbypassrls::text FROM pg_roles WHERE rolname = $(sql_role_literal "$role")"
}

verify_candidate_reader_attributes() {
  local role="$1"
  role_exists "$role" || fail "candidate-reader role does not exist: ${role}"

  local row
  row="$(role_attributes_row "$role")"
  [[ -n "$row" ]] || fail "unable to read attributes for role: ${role}"

  IFS='|' read -r canlogin super createdb createrole replication bypassrls <<<"$row"

  if [[ "$canlogin" == "true" ]]; then
    fail "candidate-reader ${role} has LOGIN; fail closed"
  fi
  if [[ "$super" == "true" ]]; then
    fail "candidate-reader ${role} has SUPERUSER; fail closed"
  fi
  if [[ "$createdb" == "true" ]]; then
    fail "candidate-reader ${role} has CREATEDB; fail closed"
  fi
  if [[ "$createrole" == "true" ]]; then
    fail "candidate-reader ${role} has CREATEROLE; fail closed"
  fi
  if [[ "$replication" == "true" ]]; then
    fail "candidate-reader ${role} has REPLICATION; fail closed"
  fi
  if [[ "$bypassrls" == "true" ]]; then
    fail "candidate-reader ${role} has BYPASSRLS; fail closed"
  fi
}

membership_options() {
  local granted_role="$1"
  local member_role="$2"
  psql_query -c "
      SELECT COALESCE(am.admin_option::text, ''), COALESCE(am.inherit_option::text, ''), COALESCE(am.set_option::text, '')
      FROM pg_auth_members am
      JOIN pg_roles granted ON granted.oid = am.roleid
      JOIN pg_roles member ON member.oid = am.member
      WHERE granted.rolname = $(sql_role_literal "$granted_role")
        AND member.rolname = $(sql_role_literal "$member_role")
    "
}

has_membership() {
  local row
  row="$(membership_options "$1" "$2")"
  [[ -n "$row" ]]
}

verify_membership_absent() {
  local granted_role="$1"
  local member_role="$2"
  local label="$3"
  if has_membership "$granted_role" "$member_role"; then
    fail "forbidden membership present: ${member_role} -> ${granted_role} (${label})"
  fi
}

verify_membership_options() {
  local granted_role="$1"
  local member_role="$2"
  local expect_admin="$3"
  local expect_inherit="$4"
  local expect_set="$5"
  local row
  row="$(membership_options "$granted_role" "$member_role")"
  [[ -n "$row" ]] || fail "expected membership missing: ${member_role} -> ${granted_role}"

  IFS='|' read -r admin inherit set <<<"$row"
  [[ "$admin" == "$expect_admin" ]] || fail "membership ${member_role}->${granted_role} admin_option=${admin}, expected ${expect_admin}"
  [[ "$inherit" == "$expect_inherit" ]] || fail "membership ${member_role}->${granted_role} inherit_option=${inherit}, expected ${expect_inherit}"
  [[ "$set" == "$expect_set" ]] || fail "membership ${member_role}->${granted_role} set_option=${set}, expected ${expect_set}"
}

verify_deployment_admin_baseline_edge() {
  local candidate_role="$1"
  verify_membership_options "$candidate_role" "$DEPLOYMENT_ADMIN_ROLE" "true" "false" "false"
}

assert_set_role_denied() {
  local target_role="$1"
  if psql_exec -c "SET ROLE ${target_role}" >/dev/null 2>&1; then
    psql_exec -c "RESET ROLE" >/dev/null 2>&1 || true
    fail "SET ROLE ${target_role} succeeded but must be denied for deployment admin baseline edge"
  fi
}

assert_set_role_allowed() {
  local target_role="$1"
  psql_exec -c "SET ROLE ${target_role}"
  psql_exec -c "RESET ROLE"
}

verify_deployment_admin_contract() {
  local row
  row="$(role_attributes_row "$DEPLOYMENT_ADMIN_ROLE")"
  [[ -n "$row" ]] || fail "deployment admin role does not exist: ${DEPLOYMENT_ADMIN_ROLE}"

  IFS='|' read -r canlogin super createdb createrole replication bypassrls <<<"$row"
  [[ "$canlogin" == "true" ]] || fail "deployment admin must be LOGIN"
  [[ "$createrole" == "true" ]] || fail "deployment admin must have CREATEROLE"
  [[ "$super" == "false" ]] || fail "deployment admin must be NOSUPERUSER"
  [[ "$createdb" == "false" ]] || fail "deployment admin must be NOCREATEDB"
  [[ "$replication" == "false" ]] || fail "deployment admin must be NOREPLICATION"
  [[ "$bypassrls" == "false" ]] || fail "deployment admin must be NOBYPASSRLS"
}

bootstrap_one_candidate_reader() {
  local candidate_role="$1"
  if role_exists "$candidate_role"; then
    info "candidate-reader already exists; verifying attributes: ${candidate_role}"
    verify_candidate_reader_attributes "$candidate_role"
    return 0
  fi

  info "creating candidate-reader role: ${candidate_role}"
  psql_exec -c "CREATE ROLE ${candidate_role} NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS"
  verify_candidate_reader_attributes "$candidate_role"
}

verify_no_schema_ownership() {
  local candidate_role="$1"
  local owned_count
  owned_count="$(psql_query -c "
      SELECT COUNT(*)
      FROM pg_namespace n
      JOIN pg_roles r ON r.oid = n.nspowner
      WHERE r.rolname = $(sql_role_literal "$candidate_role")
        AND n.nspname IN ('integration', 'workflow', 'content', 'api', 'security', 'asset')
    ")"
  [[ "$owned_count" == "0" ]] || fail "candidate-reader ${candidate_role} owns application schemas"
}

verify_no_table_ownership() {
  local candidate_role="$1"
  local owned_count
  owned_count="$(psql_query -c "
      SELECT COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_roles r ON r.oid = c.relowner
      WHERE r.rolname = $(sql_role_literal "$candidate_role")
        AND c.relkind IN ('r', 'p', 'v', 'm')
        AND (
          (n.nspname = 'integration' AND c.relname = 'outbox_messages')
          OR (n.nspname = 'workflow' AND c.relname IN ('workflow_start_intents', 'workflow_command_intents'))
        )
    ")"
  [[ "$owned_count" == "0" ]] || fail "candidate-reader ${candidate_role} owns queue tables"
}

verify_no_unexpected_schema_create() {
  local candidate_role="$1"
  local schemas=("integration" "workflow" "content" "api" "security" "asset")
  local schema
  for schema in "${schemas[@]}"; do
    local exists
    exists="$(psql_query -c "SELECT COUNT(*) FROM pg_namespace WHERE nspname = '${schema}'")"
    if [[ "$exists" == "1" ]]; then
      local has_create
      has_create="$(psql_query -c "SELECT has_schema_privilege($(sql_role_literal "$candidate_role"), '${schema}', 'CREATE')::text")"
      [[ "$has_create" == "false" ]] || fail "candidate-reader ${candidate_role} has unexpected CREATE on schema ${schema}"
    fi
  done
}
