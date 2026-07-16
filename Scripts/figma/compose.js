// compose.js — deterministic Figma composition for the localized App Store screenshots.
//
// Run via the Figma MCP `use_figma` tool (load the /figma-use skill first), against
// file aow401cEu0tQKxdh8tI442, page "Screenshots" (1:109). It fills every locale
// section's component instances (see Stage A componentization) with the screenshot
// images — no LLM judgement, no hand-composition.
//
// TWO-PHASE USAGE (see Scripts/figma-compose.sh):
//   1. Upload every PNG in Screenshots/output/<locale>/ via `upload_assets`, recording
//      { "<locale>/<filename-without-.png>": "<imageHash>" } into SOURCE_HASHES below.
//      Collect hashes PROGRAMMATICALLY into this object — never via shell string capture.
//   2. Paste this file into `use_figma` and run. It is idempotent: re-running with the
//      same hashes is a no-op; it only ever sets image fills on instance slots.
//
// Captions are NOT touched (they stay hand-edited per the design decision); this only
// sets images. Design changes propagate via the master components, not this script.

const SOURCE_HASHES = {
  // Filled by the upload phase, e.g.:
  // "en/mac-01-detail-daily": "b8a5937d…", "de/mac-02-detail-annual": "b781afa1…", …
};

const SECTIONS = {
  ios:   { en:"10:94", de:"30:94", fr:"30:134", es:"30:174", ja:"18:94", ar:"27:94", nl:"30:214", "zh-Hans":"30:334", pl:"30:254", it:"30:294" },
  macos: { en:"65:94", de:"67:94", fr:"67:112", es:"67:130", ja:"67:148", ar:"67:166", nl:"67:184", "zh-Hans":"67:202", pl:"67:220", it:"67:238" },
};

// Per-frame slot → source file (filename without extension, under Screenshots/output/<locale>/).
// Each rule locates the slot in the instance by `name`, `startsWith`, or rounded `width`.
const MACOS_FRAMES = [
  [{ startsWith: "Screenshot", file: "mac-01-detail-daily",          scaleMode: "FIT" }],
  [{ startsWith: "Screenshot", file: "mac-02-detail-annual",         scaleMode: "FIT" }],
  [{ width: 1066,              file: "mac-02-detail-annual",         scaleMode: "FIT" },
   { width: 612,               file: "mac-03-settings-notifications", scaleMode: "FIT" }],
  [{ name: "Widget — Overview",  file: "mac-04-widget-overview",  scaleMode: "FILL" },
   { name: "Widget — Countdown", file: "mac-04-widget-countdown", scaleMode: "FILL" }],
];

// iOS frame → source file for the single "Screenshot (REPLACE ME)" slot, in frame order.
// Frame 6 ("widgets, dark mode, Apple Watch") uses a shared, locale-independent image, so
// it is left untouched (null). VERIFY this order against a fresh capture before trusting it.
const IOS_FRAMES = ["02-detail-daily", "03-detail-annual", "04-time-travel", "01-location-list", "05-notifications", null];

function hashFor(locale, file) {
  if (!file) return null;
  return SOURCE_HASHES[`${locale}/${file}`] || null;
}
function setImage(node, hash, scaleMode) {
  if (!node || !hash) return false;
  node.fills = [{ type: "IMAGE", imageHash: hash, scaleMode }];
  return true;
}
function findSlot(inst, rule) {
  const kids = inst.children;
  if (rule.name) return kids.find(c => c.name === rule.name);
  if (rule.width) return kids.find(c => c.name && c.name.startsWith("Screenshot") && Math.round(c.width) === rule.width);
  if (rule.startsWith) return kids.find(c => c.name && c.name.startsWith(rule.startsWith));
  return null;
}

const page = figma.root.children.find(p => p.id === "1:109");
await figma.setCurrentPageAsync(page);

const report = { set: 0, missing: [] };

for (const loc of Object.keys(SECTIONS.macos)) {
  const insts = figma.getNodeById(SECTIONS.macos[loc]).children.filter(c => c.type === "INSTANCE");
  insts.forEach((inst, i) => {
    for (const rule of (MACOS_FRAMES[i] || [])) {
      const hash = hashFor(loc, rule.file);
      const slot = findSlot(inst, rule);
      if (setImage(slot, hash, rule.scaleMode)) report.set++;
      else report.missing.push(`macos/${loc}/frame${i + 1}/${rule.file}`);
    }
  });
}

for (const loc of Object.keys(SECTIONS.ios)) {
  const insts = figma.getNodeById(SECTIONS.ios[loc]).children.filter(c => c.type === "INSTANCE");
  insts.forEach((inst, i) => {
    const file = IOS_FRAMES[i];
    if (!file) return;
    const hash = hashFor(loc, file);
    const slot = inst.findOne(n => n.name === "Screenshot (REPLACE ME)");
    if (setImage(slot, hash, "FIT")) report.set++;
    else report.missing.push(`ios/${loc}/frame${i + 1}/${file}`);
  });
}

return report;
