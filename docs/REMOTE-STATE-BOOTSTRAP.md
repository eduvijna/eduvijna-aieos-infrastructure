# Remote State — Bootstrap

## Production remote-state authority (intended)

| Setting | Value |
| --- | --- |
| Backend | OpenTofu `s3` |
| Object store | DigitalOcean Spaces **Standard** |
| Bucket | `eduvijna-aieos-tofu-state-prod-sfo3` |
| Region | SFO3 (validate at creation gate) |
| Endpoint | `https://sfo3.digitaloceanspaces.com` |
| Locking | native `use_lockfile = true` |
| Versioning | **ON** (required) |
| CDN | OFF / unused |
| Public access | **FORBIDDEN** |
| Credential | dedicated Spaces key restricted to this state bucket |

### Workload vs control-plane location

| Concern | Region |
| --- | --- |
| Production **workload** (VPC / AIStor / NATS / PostgreSQL / App Platform) | **BLR1** |
| Production **OpenTofu control-plane state** | **SFO3** |

This is a control-plane state location exception under
[ADR-AIEOS-044R2](https://github.com/eduvijna/eduvijna-architecture/blob/main/decisions/ADR-AIEOS-044R2-aieos-production-state-region-availability-resolution.md).
SFO3 state co-location with backup Spaces does **not** imply shared bucket or
shared credentials.

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

## Namespace collision hold

`eduvijna-aieos-tofu-state-prod` is a pre-existing NYC3 Space in `first-project`
discovered during Stage 1.

**Classification:**

**UNATTRIBUTED / PRE-EXISTING / NON-AUTHORITATIVE / HOLD**

It is **not** AIEOS production state authority. Do **not** adopt, delete,
reassign, enable Versioning merely for AIEOS, or create AIEOS state credentials
against it. Any later disposition requires separate Chief Architect authority
([ADR-AIEOS-044R1](https://github.com/eduvijna/eduvijna-architecture/blob/main/decisions/ADR-AIEOS-044R1-aieos-production-state-namespace-collision-resolution.md)).

## Superseded BLR1 planned target

`eduvijna-aieos-tofu-state-prod-blr1` =

**PLANNED / NEVER CREATED / SUPERSEDED BY ADR-AIEOS-044R2**

It was never successfully created. It is **not** current state authority. No
deletion is required.

## Stage 1 status

Stage 1 production-state bootstrap remains **SUSPENDED**.

ADR-AIEOS-044R2 architecture has been merged and verified. Presence of this
document does **not** resume Stage 1 or authorize bucket creation.

Release now requires:

1. this SFO3 infrastructure reconciliation PR merged and post-merge verified;
2. a fresh exact-source Chief Architect Stage 1 **SFO3** execution authorization.

## Legacy bucket

`eduvijna-terraform-state` is:

**LEGACY / UNVERIFIED / NOT AUTHORITATIVE FOR NEW AIEOS PRODUCTION STATE**

Do not adopt it merely because the name exists. Do not conflate it with the
NYC3 collision hold or the superseded BLR1 planned target above. A later
read-only inspection may determine retirement vs historical preservation. Do
not inspect object contents in this foundation slice.
