# Central Platform VM Governance (400 VMs)

This folder contains the **demo/architecture pack** for rolling out a **centralized IaaS (Infrastructure as a Service)** operating model to manage ~**400 Azure VMs** across multiple product teams.

It is intentionally written so you can:
- present it to the broader domain (slides)
- use it as an implementation blueprint (architecture + pipelines)
- onboard teams with clear guardrails (RBAC + policy)

## Contents
- `01-exec-summary.md` – what we’re building and why (talk track)
- `02-architecture-design.md` – full design + rationale + diagrams
- `03-pipeline-design.md` – pipeline structure, templates, and agent pools
- `04-keyvault-cmk-design.md` – Key Vault strategy + CMK/DES model + rotation
- `05-glossary.md` – terminology explained for beginners
- `slides.md` – slide-ready markdown deck (copy/paste into PowerPoint or use Marp)
- `source/` – original conversation export sources (MD + JSON)

## How to use
- Present `slides.md` for the domain demo.
- Use `02-architecture-design.md` + `03-pipeline-design.md` as the implementation blueprint.

## Conventions used in this pack
- Diagrams are provided as **Mermaid** blocks (render in GitHub markdown).
- The term **Central Team** refers to the centralized platform/IaaS team.
- The term **Team** refers to a product/application team consuming the platform.
