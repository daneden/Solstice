#!/usr/bin/env bash
#
# figma-compose.sh — runbook for composing the localized App Store screenshots into
# the Figma marketing file, deterministically, via the Figma MCP tools.
#
# Prereq: screenshots captured into Screenshots/output/<locale>/ (see
# capture-screenshots.sh for iOS shots + widgets, capture-screenshots-macos.sh for
# macOS window shots). The Figma templates are componentized (Stage A): each locale
# section is component instances, so this only sets image fills — captions and all
# shared design come from the master components.
#
# This is a RUNBOOK, not a fully self-contained script: the upload and the Figma
# mutation go through the Figma MCP server (use_figma / upload_assets), which an agent
# (or Figma plugin) drives. The reusable, deterministic composition logic lives in
# Scripts/figma/compose.js. File key: aow401cEu0tQKxdh8tI442, page "Screenshots" 1:109.
#
# ── Phase 1: upload → hashes ──────────────────────────────────────────────────
# For every PNG in Screenshots/output/<locale>/, upload it and record its imageHash
# keyed by "<locale>/<filename-without-.png>". Collect the hashes PROGRAMMATICALLY
# into a JSON object (never parse them out of shell string output — that is what
# caused an earlier bad run). Example per-file POST once you hold an upload URL:
#
#   curl -s -F "file=@$png;type=image/png" "$submitUrl" | \
#     python3 -c 'import sys,json;print(json.load(sys.stdin)["imageHash"])'
#
# Build:  { "en/mac-01-detail-daily": "<hash>", "de/02-detail-daily": "<hash>", … }
#
# ── Phase 2: compose ──────────────────────────────────────────────────────────
# Paste Scripts/figma/compose.js into the `use_figma` tool with the SOURCE_HASHES
# object at the top filled from Phase 1, then run it. It fills every locale section's
# instance slots (macOS windows + widgets, iOS device screenshots) idempotently and
# returns { set, missing }. `missing` must be empty; a non-empty `missing` means a
# hash key or a slot rule didn't match.
#
# ── Verify ────────────────────────────────────────────────────────────────────
# get_screenshot each locale section (e.g. macOS en 65:94, iOS ar 27:94) and confirm.
# To prove component propagation: edit a master component (Screenshot Templates
# section) and confirm all 10 locale instances reflect it without re-running compose.

echo "This is a runbook. See the comments above and Scripts/figma/compose.js."
echo "Screenshots present:"
for d in Screenshots/output/*/; do
	[ -d "$d" ] && echo "  $(basename "$d"): $(ls "$d"*.png 2>/dev/null | wc -l | tr -d ' ') png"
done
