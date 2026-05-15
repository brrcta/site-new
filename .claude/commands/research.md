---
name: research
description: Research a topic and save findings to context
argument-hint: [topic]
---

# Research

**Topic:** $ARGUMENTS

## Pre-fetched results

!`python3 tools/scrape.py search "$ARGUMENTS" --limit 8 2>/dev/null || echo "SCRAPE_UNAVAILABLE"`

> If output above is SCRAPE_UNAVAILABLE, fall back to WebSearch. Otherwise synthesize from the results above.

## Steps

1. Summarize key findings in 3–5 bullet points
2. Identify the most actionable insight for this project
3. Flag any open questions or contradictions worth investigating further
4. Append findings to `context/lvl3-dump.md` under a date heading using `**raw:**` + `**signal:**` format
