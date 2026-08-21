# Partial / non-secret production remote-state configuration.
#
# AUTHORITY (when later initialized — NOT in this foundation slice):
#   DigitalOcean Spaces Standard bucket: eduvijna-aieos-tofu-state-prod-blr1
#   Region: BLR1 (validate at creation gate)
#   OpenTofu backend "s3" against Spaces
#   use_lockfile = true (native lockfile; no DynamoDB)
#   Bucket Versioning: ON
#   CDN: OFF / unused
#   Public access: FORBIDDEN
#
# COLLISION HOLD (ADR-AIEOS-044R1) — NOT AUTHORITATIVE:
#   eduvijna-aieos-tofu-state-prod (NYC3 / first-project)
#   = UNATTRIBUTED / PRE-EXISTING / NON-AUTHORITATIVE / HOLD
#   Do not adopt, delete, reassign, or use for AIEOS production state.
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
    #   bucket         = "eduvijna-aieos-tofu-state-prod-blr1"
    #   key            = "environments/production/opentofu.tfstate"
    #   region         = "blr1"
    #   use_lockfile   = true
    #   endpoints / skip_* flags as required for DigitalOcean Spaces
    #
    # Credentials MUST come from a dedicated Spaces key restricted to the
    # state bucket — never from application or AIStor runtime credentials.
  }
}
