# Central Platform IaC — Azure VM Infrastructure

## 400 VMs | Bicep | Azure DevOps | Key Vault | CMK

This repository is owned and managed by the **Central Platform Team**.
It contains all infrastructure-as-code, pipelines, Bicep modules, scripts, and configuration for managing 400 VMs across all teams.

---

## Repository Structure

```
central-platform-iac/
├── bicep/
│   ├── modules/         # Reusable Bicep building blocks
│   ├── orchestrators/   # Top-level Bicep that calls modules
│   └── policies/        # Azure Policy definitions
├── pipelines/
│   ├── central/         # Central Team pipelines
│   ├── team-triggered/  # Pipelines teams can trigger
│   ├── auto-triggered/  # Pipelines that fire on code changes
│   └── templates/       # Reusable pipeline YAML templates
├── parameters/          # Environment/region/tier parameter files
├── agents/              # Agent pool configuration
├── scripts/             # PowerShell scripts
├── config/              # Notification, approval, KV config
└── docs/                # Documentation
```

---

## Confirmed Architecture Decisions

| # | Decision | Implementation |
|---|----------|---------------|
| 1 | Patch Groups | PG1/PG2/PG3 — never patched together |
| 2 | Batch Size | 20 VMs in parallel |
| 3 | all-vms scope | 2 approvers + what-if mandatory |
| 4 | No auto-trigger | trigger:none on all central pipelines |
| 5 | CMK Keys | 1 key per tier (3 keys total) |
| 6 | Team Key Vaults | 1 per team (400 KVs), CT managed |
| 7 | Agent Pools | 3 self-hosted pools, private VNet |

---

## Getting Started

### 1. One-Time Platform Setup
```
Run: pipelines/central/platform-setup.yml
This creates: HSM Key Vault + CMK keys (3 tiers) + Disk Encryption Sets + networking
```

### 2. Onboard a New Team
```
Run: pipelines/central/onboard-team.yml
Provides: RG + KV + VM + RBAC + monitoring + patch enrollment
SLA: < 2 hours
```

### 3. Scheduled Patching
```
PG1 (Light VMs):  Every 2nd Sunday 1AM UTC  — auto
PG2 (Medium VMs): Every 2nd Sunday 3AM UTC  — auto
PG3 (Heavy VMs):  1st Saturday 12AM UTC     — manual approval
```

### 4. CMK Key Rotation
```
Tier 1: Every 90 days  (quarterly)
Tier 2: Every 180 days (semi-annual)
Tier 3: Every 365 days (annual)
Always requires 2 senior CT approvers
```

---

## Access
- **Write access**: Central Platform Team only
- **Read access**: All teams (consume modules and docs)

## Contact
Central Platform Team: central-platform@company.com
