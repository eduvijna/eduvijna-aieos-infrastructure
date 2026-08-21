# Bootstrap Infrastructure Baseline

**NON_PRODUCTION FOUNDATION**

Governed architecture SHAs at foundation creation:

- Architecture `origin/main`: `5aa0bdfdba4f237f603b4c8456dfddceb6da24d2`
- Backend `origin/main`: `0040e1121f19f0b6177e87a736d32f8ccc926440` (PED-I10B8 corrective merge)

## Distinction table

| Layer | Status |
| --- | --- |
| Architecture frozen | Yes |
| Implementation modeled (OpenTofu) | Yes |
| Production remote state initialized | **No** |
| Cloud resources created | **No** |
| Credentials created | **No** |
| Production deployed | **No** |
| PED-I03 activated | **No** |

## Frozen Bootstrap target (modeled)

- Cloud: DigitalOcean
- Region: BLR1
- AIStor: MinIO AIStor Free
- Topology: single dedicated node
- Compute: `s-2vcpu-4gb` named `aieos-prod-aistor-01`
- OS: Ubuntu 24.04 LTS
- Storage: six NEW ~190 GiB Volumes (XFS)
- Erasure geometry (install gate): N=6 / K=3 / M=3 / EC:3
- Network: PRIVATE-SERVICE-ONLY; no Bootstrap load balancer; no public S3
- Primary bucket (literal intended): `aieos-assets-prod`
- Versioning OFF; Object Lock OFF; lifecycle expiry NONE
- Existing DOKS worker reuse: **FORBIDDEN**
- Existing `default-blr1` reuse: **FORBIDDEN** (new VPC `aieos-prod-blr1`)
- Production project: existing DigitalOcean project **AIEOS** (do not create a second)

## App Platform network rule (binding)

- App Platform region: `blr`
- VPC datacenter: `blr1`
- VPC networking: **REQUIRED**
- Dedicated egress IP: **NOT** part of Bootstrap baseline

Reason: DigitalOcean does not permit App Platform VPC attachment and dedicated
egress IPs simultaneously; private AIStor connectivity is mandatory.

## Commercial guards

Discovered estimates (list USD, pre-tax, 2026-08-21):

- Retained DO estate ≈ USD 79.90/mo
- AIStor node = USD 24/mo
- Six × 190 GiB = USD 114/mo
- AIStor-slice projected total ≈ USD 217.90/mo

**This is not the final full AIEOS production commercial total.** Architecture
also requires production App Platform and Managed PostgreSQL (neither currently
exists in the account inventory used for preflight).

- Target ≤ USD 240/month
- Hard ceiling USD 250/month
- GST/tax accounting basis: **PENDING FOUNDER CLARIFICATION**

No OpenTofu apply may be authorized until an exact pre-apply commercial
calculation includes every resource in that apply plus retained estate.

## Hard OpenTofu guard

`enable_cloud_resources` defaults to `false`. Modules are not instantiated
until an authorized apply gate flips that flag under Chief Architect review.
