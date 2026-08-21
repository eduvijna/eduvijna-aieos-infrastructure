# Provisioning Runbook (GATED — NOT EXECUTABLE BY PRESENCE)

Stages below are future gates only. **No stage is executable** merely because
it appears here. Each requires explicit Chief Architect (and commercial)
authorization.

1. **Commercial recheck** — full estate + apply-set pricing vs ≤240 / hard 250; GST basis clarified.
2. **State bucket/key creation** — `eduvijna-aieos-tofu-state-prod`, Versioning ON, dedicated Spaces key.
3. **Remote-state validation** — authorized `tofu init` with partial backend + `use_lockfile=true`; no apply yet.
4. **Production project/VPC** — use existing AIEOS project; create `aieos-prod-blr1` after CIDR collision proof (not `default-blr1`).
5. **AIStor compute + Volumes** — `aieos-prod-aistor-01` + six NEW 190 GiB XFS volumes; never reuse DOKS.
6. **Device/mount proof** — UUID mounts at `/srv/aistor/data0{1-6}`; fail closed if incomplete.
7. **TLS** — issue certs from AIEOS CA; keys outside Git/state; trust bundle prepared for App Platform.
8. **AIStor install** — Free Tier license; private-only listener; EC:3 geometry.
9. **Bucket/IAM** — `aieos-assets-prod`; runtime / admin / break-glass identities separated.
10. **Provider conformance** — live PutObject SHA-256 + GetBucketLocation absence discrimination against production node.
11. **App Platform** — region `blr`, VPC attach required, no dedicated egress in Bootstrap baseline.
12. **Runtime composition** — only after provider conformance and commercial clearance.

## Mount fail-closed requirements

- all six devices present
- all six expected mountpoints mounted
- correct filesystem (XFS)
- correct filesystem/device identity (UUID)
- no root-disk directory fallback
- no empty-directory fallback
- no `nofail` that lets AIStor start incomplete
