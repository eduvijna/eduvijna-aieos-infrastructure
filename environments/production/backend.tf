# Partial / non-secret production remote-state configuration.
#
# AUTHORITY (when later initialized — NOT in this foundation slice):
#   DigitalOcean Spaces Standard bucket: eduvijna-aieos-tofu-state-prod-sfo3
#   Region: SFO3 (validate at creation gate)
#   Endpoint: https://sfo3.digitaloceanspaces.com
#   OpenTofu backend "s3" against Spaces
#   use_lockfile = true (native lockfile; no DynamoDB)
#   Bucket Versioning: ON
#   CDN: OFF / unused
#   Public access: FORBIDDEN
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
#
# This file intentionally omits bucket/key/endpoints/credentials.
# Operators supply them at a later authorized `tofu init` only.
# CI uses: tofu init -backend=false

terraform {
  backend "s3" {
    # Partial configuration. Remaining settings are provided only during an
    # explicitly authorized production remote-state initialization gate.
    #
    # Intended (documented, not embedded as secrets):
    #   bucket         = "eduvijna-aieos-tofu-state-prod-sfo3"
    #   key            = "environments/production/opentofu.tfstate"
    #   region         = "sfo3"
    #   use_lockfile   = true
    #   endpoints / skip_* flags as required for DigitalOcean Spaces
    #   (endpoint https://sfo3.digitaloceanspaces.com)
    #
    # Credentials MUST come from a dedicated Spaces key restricted to the
    # state bucket — never from application or AIStor runtime credentials.
  }
}
