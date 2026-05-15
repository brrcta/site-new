# Project demo videos — Higgsfield → web pipeline

Source clips from Higgsfield land here. This dir holds the **originals**;
the encoded web outputs get copied into the framework's static directory
(`public/videos/` for Next/Astro/Vite, `/assets/videos/` for plain HTML,
or uploaded to `/content/files/` for Ghost).

Originals are gitignored — only this README is tracked. Keep masters in
your own backup, not in git.

---

## Pipeline

```
Higgsfield export (.mp4)
        │
        ▼
content/pages/videos/{slug}-master.mp4    ← original, do not edit
        │
        ▼ ffmpeg encode (recipe below)
public/videos/{slug}.mp4   (H.264 + AAC, ~1–3 MB, browser fallback)
public/videos/{slug}.webm  (VP9 + Opus,  ~30–50% smaller, modern browsers)
public/videos/{slug}-poster.jpg  (~50 KB, first-frame still)
```

Reference both `.webm` and `.mp4` in the `<video>` block on
`projects.html` — the browser picks the first format it can decode.

---

## Naming

`{slug}` is kebab-case, matches the `id="project-{slug}"` on the page.

```
agent-dashboard-v1-master.mp4   ← source
agent-dashboard-v1.mp4          ← encoded
agent-dashboard-v1.webm         ← encoded
agent-dashboard-v1-poster.jpg   ← poster
```

---

## ffmpeg recipes

Targets: 720p, ~24–30 fps, instant-start, ≤3 MB per clip.

**MP4 (H.264 + AAC) — universal fallback:**

```bash
ffmpeg -i {slug}-master.mp4 \
  -vf "scale='min(1280,iw)':-2,fps=30" \
  -c:v libx264 -preset slow -crf 26 \
  -c:a aac -b:a 96k \
  -movflags +faststart \
  -pix_fmt yuv420p \
  {slug}.mp4
```

**WebM (VP9 + Opus) — smaller, modern browsers:**

```bash
ffmpeg -i {slug}-master.mp4 \
  -vf "scale='min(1280,iw)':-2,fps=30" \
  -c:v libvpx-vp9 -b:v 0 -crf 32 -row-mt 1 \
  -c:a libopus -b:a 80k \
  {slug}.webm
```

**Poster frame (first frame, JPEG ~50 KB):**

```bash
ffmpeg -i {slug}-master.mp4 \
  -vframes 1 -q:v 4 \
  {slug}-poster.jpg
```

**Optional: silent clip (drops the audio track entirely, smaller file):**

Add `-an` and remove the `-c:a` / `-b:a` flags.

---

## Quality tips

- 10–30 s clips at 720p with CRF 26 (mp4) / CRF 32 (webm) typically land at
  1–3 MB. Bump CRF up to 30/36 for further savings if visual quality holds.
- For UI-recording-style content (sharp text, low motion), drop fps to 24.
- For motion-heavy generative footage, keep 30 fps and accept larger files.
- Always set `-pix_fmt yuv420p` on H.264 — required for Safari/QuickTime.
- `+faststart` moves the moov atom to the file head so playback starts
  before the full file is downloaded. Non-negotiable for web video.

---

## Embedding

See `content/pages/projects.html` for the `<video>` markup. Key points
already wired there:

- `muted` + `playsinline` → iOS Safari plays inline instead of fullscreen
- `loop` → seamless replay for short demos
- `preload="metadata"` → no bytes downloaded until user clicks play
- `<source>` order: WebM first (browsers pick the first they support)
- `poster=` → renders the still frame immediately, before any video loads
