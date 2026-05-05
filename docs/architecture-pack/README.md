# Central Platform VM Governance (400 VMs)

This folder contains the **demo/architecture pack** generated from the Copilot Chat conversation export (Part 7: Security) and extended for **400 VMs** centralized management using **Bicep + Azure DevOps pipelines**, including **Key Vault + CMK** governance.

## Contents
- `01-exec-summary.md` – what we’re building and why (talk track)
- `02-architecture-design.md` – full design + rationale + diagrams
- `03-pipeline-design.md` – pipeline structure, templates, and agent pools
- `04-keyvault-cmk-design.md` – Key Vault strategy + CMK/DES model + rotation
- `05-glossary.md` – terminology explained for beginners
- `slides.md` – slide-ready markdown deck
- `source/` – original conversation export sources (MD + JSON)

## How to use
- Present `slides.md` for the domain demo.
- Use `02-architecture-design.md` + `03-pipeline-design.md` as the implementation blueprint.
