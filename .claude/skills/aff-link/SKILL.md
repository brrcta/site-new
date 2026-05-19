---
name: aff-link
description: Add a new affiliate product to the recs slider in index.html. Usage: /aff-link URL 'your caption'. Fetches og:title and og:image automatically; caption is taken verbatim from the command.
allowed-tools: WebFetch, Read, Edit
---

# aff-link — Add Affiliate Product

## Invocation format
```
/aff-link https://affiliate-link.com 'One-line personal take — who it's for, what it changed.'
```

Both URL and caption are required in the same command. If either is missing, ask for the missing piece before proceeding.

## Process

### 1. Parse inputs from the user's message
- **URL**: the first URL-like token in the message
- **Caption**: the text inside single quotes `'...'` (use verbatim, no edits)

### 2. Fetch metadata from the URL
Use WebFetch on the URL. Extract:
- `og:title` → `title` (fall back to `<title>` tag; strip site name suffix after ` | ` or ` — ` or ` - `)
- `og:image` → `img` (use full absolute URL; resolve relative paths against the page origin)

If `og:image` is missing: set `img` to `null` and flag it to the user.

### 3. Build the entry object
Format exactly like this (preserve indentation and quote style):

```
    {
      title:   'TITLE',
      url:     'URL',
      img:     'IMG_URL',
      caption: 'CAPTION',
    },
```

### 4. Insert into index.html
Read `/home/user/site-new/index.html`.

Find the line:
```
  const RX_ITEMS = [
```

Insert the new entry **immediately after** that line, before any existing entries or the comment block. Newest item must be first (descending chronological order).

**If array is currently empty (only comments):**

old_string:
```
  const RX_ITEMS = [
    // {
```

new_string:
```
  const RX_ITEMS = [
    {
      title:   'TITLE',
      url:     'URL',
      img:     'IMG_URL',
      caption: 'CAPTION',
    },
    // {
```

**If array already has entries:**

old_string:
```
  const RX_ITEMS = [
    {
      title:   'Existing first product',
```

new_string:
```
  const RX_ITEMS = [
    {
      title:   'New product',
      url:     'URL',
      img:     'IMG_URL',
      caption: 'CAPTION',
    },
    {
      title:   'Existing first product',
```

### 5. Report to user
Show:
- The snippet that was inserted
- If `img` was null: note they need to add an image URL manually at the `img:` field
