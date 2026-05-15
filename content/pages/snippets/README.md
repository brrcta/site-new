# content/pages/snippets/

Reusable disclaimer / warning blocks. Stack-agnostic HTML; the design
layer transforms each into a component (Astro `<NicotineWarning />`,
React component, Ghost partial, Handlebars include, …).

---

## Snippet map

| File | Where it goes | When to use |
|------|---------------|-------------|
| `footer-disclaimers.html` | Site footer, **every page** | Always. Carries the affiliate notice + the site-wide 18+/nicotine warning + the Impressum/Datenschutz/Affiliate links. |
| `nicotine-warning-block.html` | Top (or bottom) of any page that **describes, reviews, compares, or links** a nicotine product | Mandatory for product reviews, buying guides, comparison posts. The §&nbsp;6 TabakerzV addiction sentence is verbatim — do not paraphrase. |
| `nicotine-inline-tag.html` | Inline next to a product mention or inside a product bio/description card | Mandatory next to **every** affiliate link to a nicotine product. Two variants: a `<span>` tag for compact use, a `<p>` paragraph for product-bio cards. Pair with the full block on the same page — inline alone is not sufficient. |

---

## Layering rule

For any page that promotes a nicotine product via affiliate:

```
1. Footer disclaimer block         ← already site-wide
2. Full nicotine warning block     ← above-the-fold or directly above the product
3. Inline tag                      ← next to every <a> affiliate link
```

All three must be present. The footer alone is not enough (a reader may
land deep on the page and never see the footer); the full block alone is
not enough (links inline still need the per-link disclosure).

---

## Why these specific disclaimers

| Disclaimer | Legal basis | What it prevents |
|-----------|-------------|------------------|
| 18+ age restriction | § 10 JuSchG | Youth-protection violation |
| "Nikotin macht sehr stark abhängig" (verbatim) | § 6 TabakerzV | Missing/altered mandatory health warning |
| No therapeutic / cessation claim | HWG (Heilmittelwerbegesetz) | Triggering HWG advertising restrictions on a non-medicinal product |
| Sale-vs-use distinction (Art. 17 TPD) | TPD 2014/40/EU Art. 17 | Misleading reader about EU legality. The ban is on **commercial sale** outside Sweden — **purchase from SE-based dealers and personal consumption by adults in DE are not illegal**. State this accurately; do not over-warn the reader away from a lawful purchase. |
| "Werbung" + affiliate disclosure | § 5a Abs. 4 UWG, § 6 TMG | Hidden-advertising / Schleichwerbung claim |

---

## Editing rules

- **Never paraphrase** the bold sentence in `nicotine-warning-block.html`
  ("Dieses Produkt enthält Nikotin. Nikotin ist ein Stoff, der sehr stark
  abhängig macht.") — that wording is from § 6 TabakerzV.
- **Never claim** harm reduction, tobacco cessation, "healthier than
  cigarettes", or any therapeutic effect anywhere in editorial copy. Even
  in passing. Even hedged. That triggers HWG and TabakerzG §§ 19–22.
- **Never** drop the inline tag on a nicotine product link — even if the
  full block is on the same page. Per-link disclosure is the safest
  reading of § 5a Abs. 4 UWG.
- If the site stops promoting nicotine products entirely, the
  `footer-disclaimer--nicotine` paragraph in `footer-disclaimers.html`
  can be removed. The affiliate paragraph stays.
- **Do not** state or imply that buying snus from a Swedish dealer or
  consuming it in DE is illegal. It is not. The TPD Art. 17 ban targets
  commercial sale within the EU outside Sweden; the affiliate-linked
  vendors are SE-based and operating lawfully under the Swedish
  exemption. The reader, as an adult end consumer, is not committing an
  offence. Frame the legal note around **who** is bound by the ban
  (sellers in non-SE EU states), not as a warning to the buyer.

---

## Pairing with non-nicotine affiliate content

These snippets are nicotine-specific. For non-nicotine affiliate links
(books, gear, software, etc.) the inline tag is **not** appropriate —
use only the standard `*` / „Werbung" marker described in
`affiliate-disclaimer.html`.
