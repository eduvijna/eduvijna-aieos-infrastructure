# EduVijna AIEOS Infrastructure

**Classification: NON_PRODUCTION FOUNDATION**

Declarative OpenTofu definitions for EduVijna AIEOS infrastructure.

This repository is the sole AIEOS-owned infrastructure authority. Infrastructure
definitions do **not** live in `eduvijna-aieos-backend` or
`eduvijna-architecture`.

## Status of this foundation

| Concern | Status |
| --- | --- |
| Architecture frozen | Yes (ADR-AIEOS-037/038R1/039/040R1/041/041R1/042/043/044/044R1/044R2) |
| Implementation modeled | Yes (Bootstrap AIStor + VPC/project/network) |
| Production state bucket bootstrap | **COMPLETE** (`eduvijna-aieos-tofu-state-prod-sfo3` / SFO3) |
| Production remote backend initialized | **Yes** (Stage 2; operator workspace) |
| Production remote state materialized | **No** |
| Production workload cloud resources created | **No** |
| Permanent production state credential established | **Yes** (bucket-scoped `readwrite`; outside Git) |
| Production workload credentials activated | **No** |
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
- Stage 2 production backend initialization completed in the authorized
  operator workspace. Any new/reconfigured production backend initialization
  in a clean or different workspace still requires an explicit Chief Architect
  execution gate.
- No secrets in Git, `.tfvars`, plans, or documentation
- No reuse of DOKS / default VPC / legacy Spaces as AIStor production

## Commercial envelope (guardrails)

Historical foundation-slice planning values (list USD, pre-tax, 2026-08-21;
**not** current complete-estate commercial authority):

- Retained DO estate ≈ USD 79.90/mo
- AIStor node = USD 24/mo
- Six × 190 GiB Volumes = USD 114/mo
- AIStor-slice projected total ≈ USD 217.90/mo

Binding complete-estate planning evidence under ADR-AIEOS-044 is approximately
**USD 294.05/month pre-tax — RED**. Full production compute remains commercially
blocked.

Target ≤ USD 240/month service-charge operating target. Hard ceiling
USD 250/month. GST/statutory taxes (including Indian GST) are tracked separately
and do **not** consume the USD 250 DigitalOcean service-charge ceiling.

No apply may proceed without a pre-apply commercial calculation covering every
resource in that apply plus retained estate.

## Docs

- [BOOTSTRAP-INFRASTRUCTURE-BASELINE.md](docs/BOOTSTRAP-INFRASTRUCTURE-BASELINE.md)
- [REMOTE-STATE-BOOTSTRAP.md](docs/REMOTE-STATE-BOOTSTRAP.md)
- [SECRETS-AND-AUTHORITY.md](docs/SECRETS-AND-AUTHORITY.md)
- [PROVISIONING-RUNBOOK.md](docs/PROVISIONING-RUNBOOK.md)
