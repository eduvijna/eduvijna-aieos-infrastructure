# Secrets and Authority

No secret values may appear in Git, `.tfvars`, OpenTofu source, CI logs, plans
committed to Git, or documentation.

## Distinct authorities

| Authority | Purpose | Must not be |
| --- | --- | --- |
| DigitalOcean production token | Deployment / OpenTofu apply | Committed; held by foundation CI |
| Spaces state key | Remote state only | Shared with app/AIStor |
| AIStor ordinary runtime | PutObject + GetObject + GetBucketLocation | Admin / break-glass / ListBucket |
| AIStor provisioning/admin | Governed bootstrap/configuration | Injected into App Platform runtime |
| AIStor break-glass delete | Auditable physical delete only | Normal admin convenience |
| TLS root/CA private key | AIEOS-controlled CA | In Git or OpenTofu state |
| AIStor server private key | TLS for AIStor | In Git, `.tfvars`, cloud-init in Git, or state |
| Runtime CA trust bundle | Future encrypted App Platform config | Public plaintext repo content |

## Ordinary runtime IAM (documentation)

Object:

- `s3:PutObject`
- `s3:GetObject`

Bucket:

- `s3:GetBucketLocation`

Forbidden for ordinary runtime:

- `s3:ListBucket`
- `s3:ListAllMyBuckets`
- `s3:DeleteObject`
- administrative authority

## TLS invariants

- AIEOS-controlled private CA
- Server certificate must cover the eventual stable logical AIStor hostname
- No `verify=false`
- No plaintext fallback
- Certificate issuance is a later authorized operational step

## Stable service identity (unresolved EDR)

Requirement frozen: application configuration MUST use a stable hostname, not
an ephemeral Droplet IP.

DNS/product mechanism is **unresolved** and requires one final provider/DNS
authority probe before provisioning. Do not invent a public exposure path.
