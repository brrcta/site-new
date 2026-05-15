# Site Operator / Owner

> Personal and business details for the site owner. Used to populate
> {{OPERATOR_NAME}}, {{KONTAKT_EMAIL}}, Impressum, footer, bios, etc.
> when the site design lands and pages are routed.

---

## Primary contact

| Field | Value |
|-------|-------|
| **Name** | Florian Vasin |
| **Email** | hi@florianvasin.com |
| **Phone** | +49 152 230 976 80 |
| **Address** | Hildastr. 16, DE-77654, Offenburg, Germany |

---

## Legal / Impressum usage

The German Impressum (Anbieterkennzeichnung per §&nbsp;5 TMG) **must** include:

- **Responsible person:** Florian Vasin
- **Address:** Hildastr. 16, DE-77654, Offenburg
- **Contact:** hi@florianvasin.com · +49 152 230 976 80
- **Business form:** [decide: Freiberufler, Einzelunternehmen, GbR, etc. — add here once decided]
- **Tax ID / Reg ID:** [pending]

---

## Template placeholders (fill on handoff routing)

When Claude Design's website lands, replace:

| Placeholder | Value |
|---|---|
| `{{OPERATOR_NAME}}` | Florian Vasin |
| `{{KONTAKT_EMAIL}}` | hi@florianvasin.com |
| `{{KONTAKT_PHONE}}` | +49 152 230 976 80 |
| `{{OPERATOR_ADDRESS}}` | Hildastr. 16, DE-77654, Offenburg |

Used in:
- `content/pages/affiliate-disclaimer.html` — Kontakt section, footer
- Site footer — contact / about
- Impressum page (legal requirement)
- Email signature / bio blocks

---

## Notes

- Address is in Baden-Württemberg, Germany (Offenburg) — affects sales tax compliance if EU services/goods are offered.
- Phone format: +49 (international) — can be rendered as 0152 23097680 for DE-domestic use.
- For any business registration (HRB, UID, etc.) that's added later, update this file and re-sync all pages.
