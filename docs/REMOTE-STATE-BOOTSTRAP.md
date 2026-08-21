# Remote State — Bootstrap

## Production remote-state authority (intended)

| Setting | Value |
| --- | --- |
| Backend | OpenTofu `s3` |
| Object store | DigitalOcean Spaces **Standard** |
| Bucket | `eduvijna-aieos-tofu-state-prod` |
| Region | BLR1 (validate at creation gate) |
| Locking | native `use_lockfile = true` |
| Versioning | **ON** (required) |
| CDN | OFF / unused |
| Public access | **FORBIDDEN** |
| Credential | dedicated Spaces key restricted to this state bucket |

Do **not** use:

- local state as production authority
- HCP / Terraform Cloud
- AWS DynamoDB
- AWS infrastructure
- self-managed lock database
- application or AIStor credentials for state access

## Partial backend configuration

`environments/production/backend.tf` is intentionally partial and non-secret.
CI runs `tofu init -backend=false`.

Production `tofu init` that configures remote state is a **later authorized
gate** after bucket/key creation — not part of this foundation.

## Legacy bucket

`eduvijna-terraform-state` is:

**LEGACY / UNVERIFIED / NOT AUTHORITATIVE FOR NEW AIEOS PRODUCTION STATE**

Do not adopt it merely because the name exists. A later read-only inspection
may determine retirement vs historical preservation. Do not inspect object
contents in this foundation slice.
