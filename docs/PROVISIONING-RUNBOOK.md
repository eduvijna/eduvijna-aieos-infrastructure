# Provisioning Runbook (STATUS-AWARE GATED SEQUENCE)

Stages below are gated. Presence here does **not** authorize execution.
Billable workload progression still requires explicit Chief Architect and
commercial authorization. Stage 1 / Stage 2 / Stage 3A / Stage 3B control-plane
state progression was separately authorized and did **not** release billable
production workload compute.

| Gate | Status |
| --- | --- |
| 1. Commercial release/recheck (full estate vs ≤240 / hard 250; GST tracked separately) | **OPEN / REQUIRED** before billable workload progression |
| 2. State bucket/key creation — `eduvijna-aieos-tofu-state-prod-sfo3` (SFO3 Spaces Standard), Versioning ON, dedicated Spaces key | **COMPLETE** (Stage 1) |
| 3. Remote S3 backend initialization — partial backend + `use_lockfile=true` | **COMPLETE** (Stage 2) |
| 4. Remote tfstate materialization — authoritative state serial **1** / zero managed resources | **COMPLETE** (Stage 3B) |
| 5. Live lock acquisition/release validation — Stage 3A + Stage 3B native lock lifecycle | **COMPLETE** (current persistent lock **ABSENT**) |
| 6. OpenTofu planning — bounded refresh-only state validation | **COMPLETE / CLOSED** (Stage 3A); normal production workload plan **NOT AUTHORIZED** |
| 7. OpenTofu apply — bounded Stage-3B refresh-only saved-plan apply | **COMPLETE / CLOSED** (0 added / 0 changed / 0 destroyed); further production apply **NOT AUTHORIZED** |
| 8. Production project/VPC — use existing AIEOS project; create `aieos-prod-blr1` after CIDR collision proof (not `default-blr1`) | **GATED / NOT AUTHORIZED** |
| 9. AIStor compute + Volumes — `aieos-prod-aistor-01` + six NEW 190 GiB XFS volumes; never reuse DOKS | **GATED / NOT AUTHORIZED** |
| 10. Device/mount proof — UUID mounts at `/srv/aistor/data0{1-6}`; fail closed if incomplete | **GATED** |
| 11. TLS — issue certs from AIEOS CA; keys outside Git/state; trust bundle prepared for App Platform | **GATED** |
| 12. AIStor install — Free Tier license; private-only listener; EC:3 geometry | **GATED** |
| 13. Bucket/IAM — `aieos-assets-prod`; runtime / admin / break-glass identities separated | **GATED** |
| 14. Provider conformance — live PutObject SHA-256 + GetBucketLocation absence discrimination against production node | **GATED** |
| 15. App Platform — region `blr`, VPC attach required, no dedicated egress in Bootstrap baseline | **GATED / NOT AUTHORIZED** |
| 16. Runtime composition — only after provider conformance and commercial clearance | **GATED / NOT AUTHORIZED** |
| 17. PostgreSQL candidate-reader bootstrap — ADR-AIEOS-045 deployment-admin role creation + `scripts/postgresql/*` | **SOURCE-DEFINED / NOT RELEASED** |

Full production compute remains **COMMERCIALLY BLOCKED** (ADR-AIEOS-044 complete-estate planning evidence ≈ USD 294.05/month pre-tax — RED).

## ADR-AIEOS-045 PostgreSQL candidate-reader sequence (NOT RELEASED)

Production execution of this sequence requires separate Chief Architect authorization. Dispatcher daemon remains disabled.

1. Establish / verify narrower deployment administration role (`aieos_db_deployment_admin` conceptually) from break-glass provider admin if not already present.
2. Run `scripts/postgresql/bootstrap-candidate-readers.sh` as deployment admin.
3. Run `scripts/postgresql/verify-candidate-readers.sh` (`AIEOS_VERIFY_MODE=baseline`).
4. Run `scripts/postgresql/grant-candidate-migration-access.sh` immediately before authorized Backend Alembic migration window.
5. Execute future Backend Alembic migration (RLS / grants / indexes / candidate functions — **not** this Infrastructure phase).
6. Run `scripts/postgresql/revoke-candidate-migration-access.sh` (or `cleanup-candidate-migration-access.sh` after interruption).
7. Run final `verify-candidate-readers.sh` (`baseline`).
8. Dispatcher daemon remains **disabled** until separately authorized.

See [POSTGRESQL-IDENTITY-BOOTSTRAP.md](POSTGRESQL-IDENTITY-BOOTSTRAP.md).

## Mount fail-closed requirements

- all six devices present
- all six expected mountpoints mounted
- correct filesystem (XFS)
- correct filesystem/device identity (UUID)
- no root-disk directory fallback
- no empty-directory fallback
- no `nofail` that lets AIStor start incomplete
