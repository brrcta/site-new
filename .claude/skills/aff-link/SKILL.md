---
name: aff-link
description: Add a new affiliate product to the recs slider in index.html. Fetches og:title and og:image from the URL automatically. User provides the URL; skill inserts the entry at the top of RX_ITEMS (newest first).
allowed-tools: WebFetch, Read, Edit
---

# aff-link — Add Affiliate Product

## Goal
Insert a new entry at the **top** of `RX_ITEMS` in `index.html` (newest addition appears first in the slider).

## Inputs
- **URL**: the affiliate link the user provides (may be in the current message or ask once)

## Process

### 1. Get the URL
If the user did not provide a URL in their message, ask: "Which affiliate URL should I add?"

### 2. Fetch metadata from the URL
Use WebFetch on the URL. Extract from the HTML:
- `og:title` → `title` (fall back to `<title>` tag, strip site name suffix after ` | ` or ` — ` or ` - `)
- `og:image` → `img` (use full absolute URL; if relative, prepend the origin)
- `og:description` → use as a starting point for `caption` (trim to one sentence max, ~100 chars)

If `og:image` is missing or empty: set `img` to `null` and note it to the user.

### 3. Build the snippet
Format the entry exactly like this (preserve spacing and quote style):

```
    {
      title:   'TITLE',
      url:     'URL',
      img:     'IMG_URL',
      caption: 'CAPTION — edit this to your own voice.',
    },
```

### 4. Insert into index.html
Read `/home/user/site-new/index.html`.
Find the line:
```
  const RX_ITEMS = [
```
Insert the new entry **immediately after** that line, before any existing entries or the comment block. The array must start with the newest item.

Use Edit with `old_string` = the exact `const RX_ITEMS = [` line plus the first line that follows it, and `new_string` = those same lines with the new entry prepended.

**Example — if array is currently empty (only comments):**

old_string:
```
  const RX_ITEMS = [
    // {
```

new_string:
```
  const RX_ITEMS = [
    {
      title:   'Product',
      url:     'https://...',
      img:     'https://...',
      caption: 'Caption here.',
    },
    // {
```

**Example — if array already has entries:**

old_string:
```
  const RX_ITEMS = [
    {
      title:   'Existing product',
```

new_string:
```
  const RX_ITEMS = [
    {
      title:   'New product',
      url:     'https://...',
      img:     'https://...',
      caption: 'Caption here.',
    },
    {
      title:   'Existing product',
```

### 5. Report to user
Show:
- The exact snippet inserted
- A one-line reminder: `caption:` is pre-filled from og:description — edit it to your own voice before shipping
- If `img` was null: note that they need to add an image URL manually
