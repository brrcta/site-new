---
paths: ["**/*"]
---

# Phase Gate Enforcement

Define your project's phases and gate criteria here. Claude uses this to avoid doing work that's out of sequence.

## Phases

Replace this table with phases specific to your project.

| Phase | Gate criteria | ✅ Do | ❌ Don't |
|-------|--------------|-------|---------|
| 0 | Foundation (infra live, auth working, core loop proven) | Setup, research, planning | Build features on unproven foundation |
| 1 | MVP validated (first users / revenue / validation signal) | Build core features, iterate | Scale, paid acquisition, new verticals |
| 2 | Product-market fit signals (retention, growth, revenue) | Optimize, systematize, automate | Rebuild foundation, pivot core |
| 3 | Stable operations | Expand, delegate, automate further | Break what works |

## Examples by project type

- **SaaS**: Infra → Beta → Revenue → Scale
- **Agency**: Scoping → Delivery → Handoff → Retainer
- **Research**: Discovery → Hypothesis → Experiment → Publish
- **Internal tool**: Setup → Pilot → Rollout → Maintain

## Override

User can override with:
> "I understand this is outside my current phase. Proceed anyway."
