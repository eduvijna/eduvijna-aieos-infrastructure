# Partial / non-secret production remote-state configuration.
#
# CURRENT GOVERNED PRODUCTION BACKEND AUTHORITY (ADR-AIEOS-044R2):
#   DigitalOcean Spaces Standard bucket: eduvijna-aieos-tofu-state-prod-sfo3
#   Bucket: EXISTS / PRIVATE / VERSIONING ENABLED (project AIEOS)
#   Region: SFO3
#   Endpoint: https://sfo3.digitaloceanspaces.com
#   OpenTofu backend "s3" against Spaces
#   use_lockfile = true (native lockfile; no DynamoDB)
#   CDN: OFF / unused
#   Public access: FORBIDDEN
#
# STAGE 2 (PASS / FORMALLY CLOSED):
#   Authorized operator workspace completed remote S3 backend initialization
#   using external non-secret backend-config + process-local credential loading.
#   Credentials were never persisted in source, .tfbackend, or Git.
#   Remote tfstate object: NOT YET MATERIALIZED / ABSENT
#   Persistent lock object: ABSENT
#   tofu plan / tofu apply: NOT AUTHORIZED
#
# SOURCE REMAINS INTENTIONALLY PARTIAL / NON-SECRET.
# CI uses: tofu init -backend=false
# A clean or future production operator workspace requires a fresh explicit
# Chief Architect execution gate before production backend initialization.
#
# WORKLOAD vs CONTROL-PLANE (ADR-AIEOS-044R2):
#   Production workload region remains BLR1.
#   OpenTofu production-state location is SFO3 only.
#
# COLLISION HOLD (ADR-AIEOS-044R1) — NOT AUTHORITATIVE:
#   eduvijna-aieos-tofu-state-prod (NYC3 / first-project)
#   = UNATTRIBUTED / PRE-EXISTING / NON-AUTHORITATIVE / HOLD
#   Do not adopt, delete, reassign, or use for AIEOS production state.
#
# SUPERSEDED PLANNED TARGET (ADR-AIEOS-044R2):
#   eduvijna-aieos-tofu-state-prod-blr1
#   = PLANNED / NEVER CREATED / SUPERSEDED BY ADR-AIEOS-044R2
#
# LEGACY / NOT AUTHORITATIVE:
#   eduvijna-terraform-state  — do not adopt as production authority

terraform {
  backend "s3" {
    # Partial configuration. Executable bucket/key/endpoint/credential values
    # are NOT embedded here. Stage 2 operator init used external non-secret
    # backend-config; CI continues with tofu init -backend=false.
    #
    # Documented authority (not embedded secrets):
    #   bucket         = "eduvijna-aieos-tofu-state-prod-sfo3"
    #   key            = "environments/production/opentofu.tfstate"
    #   region         = "sfo3"
    #   use_lockfile   = true
    #   endpoints / skip_* flags as required for DigitalOcean Spaces
    #   (endpoint https://sfo3.digitaloceanspaces.com)
    #
    # Credentials MUST come from the dedicated Spaces key restricted to the
    # state bucket — never from application or AIStor runtime credentials.
  }
}
