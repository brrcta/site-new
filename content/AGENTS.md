# Content — Agent Knowledge Base

This file provides compressed, declarative knowledge for any agent working on content in this
directory. Read this file instead of loading multiple lvl2 context files individually.

---

## Brand: movinslooow

**Niche:** conscious/attachment parenting + sustainable family life, EU English-speaking market.
**ICP:** parent 25–40, urban, mid-high income, research-oriented, values-driven, Montessori/eco/attachment philosophy.
Reader reads ingredient labels. Do not dumb down. Do not preach.

**E-E-A-T edge:** real parenting experience (father of two under 30, wife became mother at 21),
personal product testing, professional photography. Frame experience as "our family tested this."

---

## Voice — Non-Negotiable Rules

**One-line voice:** Experienced parent friend who tested it with their own kids and tells the truth.

**Active patterns:**
- Active voice: "This carrier supports newborns from day one" not "Newborns are supported by..."
- Direct lead sentence: state the point immediately, no wind-up
- Paragraphs: 2–4 sentences max
- "You" naturally: direct advice, not Wikipedia tone
- Trade-offs acknowledged: "best eco diaper we've tried, but costs twice as much"
- Personal framing: "tested with our kids", "works for our family"
- EU lens: EU availability, EU certifications, EU-relevant regulations

**Forbidden words (hard no):** must-have, essential, every parent needs, game-changer, life-changing,
journey, clean (vague), natural (without specifying), chemical-free, toxic, 100% safe

**Forbidden patterns:** momfluencer tone ("obsessed!"), guilt-tripping ("if you really cared..."),
fear tactics ("toxins in your baby's diaper"), fake urgency ("limited stock"), preachy ("the only
right way to parent"), condescending (over-explaining basics)

---

## HWG / EU Claims — Hard Constraints

**Absolute violations (never publish):**
- "Heals", "cures", "heilt", "beseitigt garantiert"
- "Guaranteed" efficacy of any kind
- "100% safe", "completely safe"
- "Chemical-free", "toxin-free" (unspecified)
- "Prevents allergies/rash/eczema" (without clinical citation)
- "Makes your child smarter", "boosts brain development"
- "Clinically proven" without citation
- "Doctor-recommended" without substantiation

**Claims requiring verification before publishing:**
- OEKO-TEX, GOTS, CE marking, EN 71, BPA-free, "hypoallergenic", "dermatologically tested"
- "Organic" / "bio" without specifying certification standard
- "Eco-friendly", "sustainable", "biodegradable" without certification reference

**Safe language patterns:**
- "Tested for harmful substances per OEKO-TEX Standard 100"
- "GOTS-certified organic cotton"
- "CE marked — complies with EN 71 toy safety standard"
- "We've used this for 6 months — here's what we found"

---

## Article Structure

**Standard outline format:**
- H1: target keyword (natural phrasing, not stuffed)
- Intro (150–200 words): state the point immediately; include keyword; establish personal experience
- H2 sections (4–6): cover the full topic; each can contain H3s
- Each section: prose in final article, bullets in outlines
- Citations: flag claims needing sources as `[CITE: description]`
- Word count: 1,200–2,000 (informational); 2,000–3,000 (guide/comparison)
- Internal links: 2–4 per article; descriptive anchor text
- Affiliate disclosure: required at top of any article with product recommendations

**SEO rules:**
- Keyword in: H1, first paragraph, ≥2 H2s, meta description
- Density: 1–2 per 300 words; no exact repetition >3x in close proximity
- Heading hierarchy: H1 → H2 → H3; no skipped levels; no duplicate H1

---

## Content Pillars (4)

| Pillar | Hub theme | Phase |
|--------|-----------|-------|
| P1 Attachment Parenting | "Attachment Parenting: The Whole Picture" | active |
| P2 Eco Care & Home | "Ecological Approach to (Self-)Care and Home" | active |
| P3 Learning Material | "Self-Governed and Open Learning for Children" | active |
| P4 Organic Lifestyle | "Why We Chose an Ethical Lifestyle" | active |

Keyword priorities: GO status → lowest KD first → highest volume as tiebreaker.
Top 5 outlines (already drafted, KD 18–24): see `content/draft/`.

---

## File Conventions

- Outlines: `content/draft/{keyword-slug}-outline.md`
- Full articles: `content/draft/{keyword-slug}.md`
- All content goes through `/editorial-check` before publishing
- Publish via `ghost/scripts/publish-post.py` (never direct Ghost UI for scripted content)
