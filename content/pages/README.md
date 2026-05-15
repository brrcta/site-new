# content/pages/

Stack-agnostic HTML stubs for static sub-pages. These are written in
plain semantic HTML5 with `{{PLACEHOLDER}}` tokens so they can be
absorbed into whichever framework Claude Design hands off
(Next.js, Astro, Ghost templates, plain static, …) without rewriting.

---

## Current stubs

| File | Purpose | Placeholders to fill |
|------|---------|----------------------|
| `affiliate-disclaimer.html` | DE-compliant affiliate / Werbung notice | `{{SITE_NAME}}`, `{{OPERATOR_NAME}}`, `{{IMPRESSUM_URL}}`, `{{DATENSCHUTZ_URL}}`, `{{KONTAKT_EMAIL}}`, `{{LAST_UPDATED}}`, `{{PROGRAMM_1..3}}` |
| `projects.html` | Projects sub-page with native HTML5 `<video>` blocks | `{{LANG}}`, `{{SITE_NAME}}`, plus per-project: `{{slug}}`, `{{title}}`, `{{summary}}`, `{{duration}}` |
| `videos/README.md` | Higgsfield → web encoding pipeline (ffmpeg recipes) | — |

---

## Routing on handoff

When Claude Design lands the website:

1. Decide where static pages live in the chosen stack
   (`pages/`, `src/pages/`, Ghost custom pages, …).
2. Convert these HTML stubs into the stack's page format
   (e.g. `.astro`, `.tsx`, `.hbs`) — keep the semantic markup, swap
   `{{PLACEHOLDER}}` for stack-native variables.
3. Replace every placeholder with real values; the affiliate page in
   particular must match `Impressum` exactly (legal requirement).
4. The Amazon block in `affiliate-disclaimer.html` is mandatory **only**
   if Amazon Partnerprogramm is used — otherwise remove that `<aside>`.
5. Verify final URLs: `/affiliate-hinweis` (or `/affiliate-disclaimer`)
   and `/projekte` (or `/projects`) — link from footer.

---

## Why HTML and not Markdown

The affiliate page has legal-formatting requirements (Amazon's pflicht-
wording is verbatim, structured headings, mailto + footer attribution).
Markdown obscures that structure when transformed across frameworks.
Plain HTML round-trips cleanly into any templating system.
