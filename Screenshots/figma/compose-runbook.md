# Stage 3 — Compose in Figma (runbook)

This is the runbook for turning the raw `Screenshots/output/<locale>/<screen>.png` files
into finished App Store frames (device frame + background + localized caption)
using the **official Figma MCP server**. It is written to be handed to an agent
(or followed by hand) once the Figma MCP server is connected.

> **Not yet runnable in this session.** The Figma MCP server (`use_figma` +
> `upload_assets`) was not connected when this pipeline was built. Connect it,
> confirm you have a **Full seat** with edit access to the target file, then follow
> the steps below. The two write tools are beta — test on a duplicate/draft first.

## Inputs

- `Screenshots/output/<locale>/<screen>.png` — raw captures from Stages 1–2.
  Screens: `01-location-list`, `02-detail-daily`, `03-detail-annual`,
  `04-time-travel`, `05-notifications`.
- `Screenshots/figma/captions.json` — localized caption copy (draft; review first).
- Locales: `en de fr es ja ar nl zh-Hans pl it`.

## Why two tools

- `use_figma` writes native Figma structure (frames, auto-layout, text, components,
  variables) but **cannot place raster images** — it leaves placeholder nodes.
- `upload_assets` uploads a PNG and sets it as a target node's **fill** — this is what
  actually drops each screenshot in.

## Naming convention (critical)

Name every screenshot placeholder node exactly:

```
shot@<locale>@<screen>
```

e.g. `shot@de-DE@02-detail-daily`. The fill step matches
`Screenshots/output/<locale>/<screen>.png` to the node with the corresponding name, so the
mapping is unambiguous. Use the same locale codes as the capture folders.

## Steps

1. **Template (once).** With `use_figma`, build one marketing-screenshot template per
   screen (there are 5). Each template frame contains:
   - a background (use the app's existing design-system color/gradient components/variables
     where available);
   - a device-frame shape sized to the 6.9" iPhone canvas (App Store: 1320×2868);
   - a caption text layer (top or bottom third);
   - an **empty rectangle placeholder** named `shot@<locale>@<screen>` where the
     screenshot fill goes.

2. **Fan out across locales (still `use_figma`).** Duplicate the 5 templates for each of
   the 10 locales (50 frames total), substituting the caption copy from `captions.json`
   for each locale and renaming each placeholder to encode that locale.

3. **Fill screenshots (`upload_assets`).** For every placeholder node, call
   `upload_assets` targeting that node's id with the matching
   `Screenshots/output/<locale>/<screen>.png`, setting it as the fill.

## Constraints

- **Full seat + edit access** required to write to the canvas.
- **10 MB per asset** cap in `upload_assets`. A 1320×2868 PNG of a busy screen can
  approach this — verify captures are under the cap, or export optimized PNG/JPG first.
- **Fonts must be uploaded to the Figma account** to be usable when writing to canvas;
  locally installed fonts won't work. This matters for CJK (`ja`, `zh-Hans`) and RTL
  (`ar`) caption coverage — confirm a font with full coverage is available in Figma.
- For `ar`, set the caption text layer direction to RTL.

## Alternative (if Figma isn't the source of truth)

If you just want finished flat PNGs with minimal moving parts, skip Figma and composite
the device frame + caption in code (SwiftUI/Core Graphics or a Pillow-style compositor)
driven by `captions.json`. Trade-off: no editable Figma template.
