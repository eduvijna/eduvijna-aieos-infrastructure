# EduVijna AIEOS Infrastructure

**Classification: NON_PRODUCTION FOUNDATION**

Declarative OpenTofu definitions for EduVijna AIEOS infrastructure.

This repository is the sole AIEOS-owned infrastructure authority. Infrastructure
definitions do **not** live in `eduvijna-aieos-backend` or
`eduvijna-architecture`.

## Status of this foundation

| Concern | Status |
| --- | --- |
| Architecture frozen | Yes (ADR-AIEOS-037/038R1/039/040R1/041/041R1/042/043) |
| Implementation modeled | Yes (Bootstrap AIStor + VPC/project/network) |
| Production remote state initialized | **No** |
| Cloud resources created | **No** |
| Credentials created | **No** |
| Production deployed | **No** |
| PED-I03 activated | **No** |
| OpenTofu apply authorized | **No** |

## Toolchain

- OpenTofu **1.12.5** (see `.opentofu-version`)
- Provider `digitalocean/digitalocean` **2.99.1** (locked)

Do **not** use Terraform CLI as the implementation authority.

## Layout

```text
environments/production/   # production root module (modeled; not applied)
modules/                   # reusable building blocks
docs/                      # baseline, state, secrets, runbook
```

## Absolute prohibitions (this foundation)

- No DigitalOcean resource mutation from CI or local convenience
- No `tofu apply` against production without Chief Architect authorization
- No production `tofu init` that configures remote state until the state
  bucket/key creation gate
- No secrets in Git, `.tfvars`, plans, or documentation
- No reuse of DOKS / default VPC / legacy Spaces as AIStor production

## Commercial envelope (guardrails)

Discovered preflight estimates (list USD, pre-tax, 2026-08-21):

- Retained DO estate ≈ USD 79.90/mo
- AIStor node = USD 24/mo
- Six × 190 GiB Volumes = USD 114/mo
- AIStor-slice projected total ≈ USD 217.90/mo

**This is not the final full AIEOS production commercial total.** App Platform
and Managed PostgreSQL are required by architecture and are not yet present.

Target ≤ USD 240/month. Hard ceiling USD 250/month. GST/tax basis pending
Founder clarification.

No apply may proceed without a pre-apply commercial calculation covering every
resource in that apply plus retained estate.

## Docs

- [BOOTSTRAP-INFRASTRUCTURE-BASELINE.md](docs/BOOTSTRAP-INFRASTRUCTURE-BASELINE.md)
- [REMOTE-STATE-BOOTSTRAP.md](docs/REMOTE-STATE-BOOTSTRAP.md)
- [SECRETS-AND-AUTHORITY.md](docs/SECRETS-AND-AUTHORITY.md)
- [PROVISIONING-RUNBOOK.md](docs/PROVISIONING-RUNBOOK.md)
