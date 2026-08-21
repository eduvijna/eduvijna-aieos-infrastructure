# Provisioning Runbook (STATUS-AWARE GATED SEQUENCE)

Stages below are gated. Presence here does **not** authorize execution.
Billable workload progression still requires explicit Chief Architect and
commercial authorization. Stage 1/2 control-plane state bootstrap proceeded
under separately authorized gates and did **not** release production workload
compute.

| Gate | Status |
| --- | --- |
| 1. Commercial release/recheck (full estate vs ≤240 / hard 250; GST tracked separately) | **OPEN / REQUIRED** before billable workload progression |
| 2. State bucket/key creation — `eduvijna-aieos-tofu-state-prod-sfo3` (SFO3 Spaces Standard), Versioning ON, dedicated Spaces key | **COMPLETE** (Stage 1) |
| 3. Remote S3 backend initialization — partial backend + `use_lockfile=true` | **COMPLETE** (Stage 2) |
| 4. Remote tfstate materialization | **NOT EXECUTED / NOT AUTHORIZED** |
| 5. Live lock acquisition | **NOT EXECUTED** |
| 6. `tofu plan` | **NOT AUTHORIZED** |
| 7. `tofu apply` | **NOT AUTHORIZED** |
| 8. Production project/VPC — use existing AIEOS project; create `aieos-prod-blr1` after CIDR collision proof (not `default-blr1`) | **GATED / NOT AUTHORIZED** |
| 9. AIStor compute + Volumes — `aieos-prod-aistor-01` + six NEW 190 GiB XFS volumes; never reuse DOKS | **GATED / NOT AUTHORIZED** |
| 10. Device/mount proof — UUID mounts at `/srv/aistor/data0{1-6}`; fail closed if incomplete | **GATED** |
| 11. TLS — issue certs from AIEOS CA; keys outside Git/state; trust bundle prepared for App Platform | **GATED** |
| 12. AIStor install — Free Tier license; private-only listener; EC:3 geometry | **GATED** |
| 13. Bucket/IAM — `aieos-assets-prod`; runtime / admin / break-glass identities separated | **GATED** |
| 14. Provider conformance — live PutObject SHA-256 + GetBucketLocation absence discrimination against production node | **GATED** |
| 15. App Platform — region `blr`, VPC attach required, no dedicated egress in Bootstrap baseline | **GATED / NOT AUTHORIZED** |
| 16. Runtime composition — only after provider conformance and commercial clearance | **GATED / NOT AUTHORIZED** |

Full production compute remains **COMMERCIALLY BLOCKED** (ADR-AIEOS-044 complete-estate planning evidence ≈ USD 294.05/month pre-tax — RED).

## Mount fail-closed requirements

- all six devices present
- all six expected mountpoints mounted
- correct filesystem (XFS)
- correct filesystem/device identity (UUID)
- no root-disk directory fallback
- no empty-directory fallback
- no `nofail` that lets AIStor start incomplete
