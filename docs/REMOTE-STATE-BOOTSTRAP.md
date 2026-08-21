# Remote State — Bootstrap

## Production remote-state authority (current)

| Setting | Value |
| --- | --- |
| Backend | OpenTofu `s3` |
| Object store | DigitalOcean Spaces **Standard** |
| Bucket | `eduvijna-aieos-tofu-state-prod-sfo3` |
| Bucket posture | **EXISTS / PRIVATE** |
| Region | **SFO3** |
| Endpoint | `https://sfo3.digitaloceanspaces.com` |
| Locking | native `use_lockfile = true` |
| Versioning | **ENABLED** |
| CDN | OFF / unused |
| Public access | **FORBIDDEN** |
| Permanent credential | **ESTABLISHED** / bucket-scoped `readwrite` / outside Git |
| Stage 1 | **PASS / FORMALLY CLOSED** |
| Stage 2 | **PASS / FORMALLY CLOSED** |
| Production backend | **INITIALIZED** |
| Remote tfstate object | **ABSENT / NOT MATERIALIZED** |
| Persistent lock object | **ABSENT** |
| `tofu plan` | **NOT AUTHORIZED** |
| `tofu apply` | **NOT AUTHORIZED** |

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

`environments/production/backend.tf` is intentionally **PARTIAL / NON-SECRET**.
CI runs `tofu init -backend=false`.

Stage 2 initialized an authorized operator working directory using external
non-secret backend configuration plus process-local credential loading.
Credentials and executable backend parameters are **not** embedded in source.

A clean or future production operator workspace does **not** inherit Stage 2
authorization automatically; fresh production backend initialization still
requires an explicit Chief Architect execution gate.

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

## Stage 1 / Stage 2 status

- **Stage 1** production-state bucket bootstrap: **PASS / FORMALLY CLOSED**
- **Stage 2** production remote-backend initialization: **PASS / FORMALLY CLOSED**

Remote tfstate remains **NOT MATERIALIZED**. Persistent lock object remains
**ABSENT**. `tofu plan` / `tofu apply` remain **NOT AUTHORIZED**.

## Legacy bucket

`eduvijna-terraform-state` is:

**LEGACY / UNVERIFIED / NOT AUTHORITATIVE FOR NEW AIEOS PRODUCTION STATE**

Do not adopt it merely because the name exists. Do not conflate it with the
NYC3 collision hold or the superseded BLR1 planned target above. A later
read-only inspection may determine retirement vs historical preservation. Do
not inspect object contents in this foundation slice.
