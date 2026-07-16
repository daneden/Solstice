#!/usr/bin/env bash
#
# capture-screenshots.sh — Stages 1 & 2 of the localized App Store screenshot
# pipeline: run the `Screenshots` test plan once per locale on the simulator,
# then extract the raw PNGs out of the .xcresult into Screenshots/output/<locale>/.
#
# Native Xcode tooling only (xcodebuild + xcresulttool). No third-party
# screenshot framework, no Ruby/gems.
#
# Usage:
#   Scripts/capture-screenshots.sh                # all locales in the test plan
#   Scripts/capture-screenshots.sh en ja ar       # a subset of locales
#
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

# ---- Configuration -----------------------------------------------------------

PROJECT="Solstice.xcodeproj"
SCHEME="Screenshots"
TEST_PLAN="Screenshots"

DERIVED_DIR="$PWD/.screenshots/DerivedData"
RESULTS_DIR="$PWD/.screenshots/results"
OUT_DIR="$PWD/Screenshots/output"

# iPhone 17 Pro (6.3") — matches the device bezel in the Figma marketing
# template. Swap to "iPhone 17 Pro Max" for the 6.9" App Store size, or add the
# 13" iPad line if the app ships an iPad build.
DEVICE_NAME="iPhone 17 Pro"
# DEVICE_NAME="iPhone 17 Pro Max"
# DEVICE_NAME="iPad Pro 13-inch (M4)"

# All locales present in Screenshots.xctestplan. Override via CLI args.
ALL_LOCALES=(en de fr es ja ar nl zh-Hans pl it)
LOCALES=("${ALL_LOCALES[@]}")
if [ "$#" -gt 0 ]; then
	LOCALES=("$@")
fi

echo "==> Locales: ${LOCALES[*]}"
echo "==> Device:  $DEVICE_NAME"

# Resolve (and boot) the target simulator so we can pin a clean status bar.
UDID=$(xcrun simctl list devices available | awk -F '[()]' -v name="$DEVICE_NAME" '
	$0 ~ name" \\(" { print $2; exit }')
if [ -z "${UDID:-}" ]; then
	echo "error: simulator '$DEVICE_NAME' not found (see: xcrun simctl list devices available)" >&2
	exit 1
fi

echo "==> Booting simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b || true

echo "==> Overriding status bar (9:41, full signal & battery)"
xcrun simctl status_bar "$UDID" override \
	--time "9:41" \
	--dataNetwork wifi --wifiMode active --wifiBars 3 \
	--cellularMode notSupported \
	--batteryState charged --batteryLevel 100

# ---- Stage 1: run the test plan (one configuration per locale) ---------------

rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"
RESULT_BUNDLE="$RESULTS_DIR/Screenshots.xcresult"

ONLY_CONFIGS=()
for loc in "${LOCALES[@]}"; do
	ONLY_CONFIGS+=(-only-test-configuration "$loc")
done

echo "==> Running screenshot test plan"
set -x
xcodebuild test \
	-project "$PROJECT" \
	-scheme "$SCHEME" \
	-testPlan "$TEST_PLAN" \
	-destination "id=$UDID" \
	-derivedDataPath "$DERIVED_DIR" \
	-resultBundlePath "$RESULT_BUNDLE" \
	"${ONLY_CONFIGS[@]}"
set +x

# ---- Stage 2: extract screenshots from the .xcresult -------------------------
#
# xcparse doesn't read the Xcode 26+ xcresult format, so we use the native
# `xcresulttool export attachments`, which writes a manifest.json mapping each
# UUID-named file to its test-plan configuration (the locale) and its
# human-readable name (the capture name, e.g. "02-detail-daily").

echo "==> Exporting attachments with xcresulttool"
RAW_DIR="$RESULTS_DIR/raw"
rm -rf "$RAW_DIR"
mkdir -p "$RAW_DIR"
xcrun xcresulttool export attachments \
	--path "$RESULT_BUNDLE" \
	--output-path "$RAW_DIR" >/dev/null

echo "==> Normalizing into $OUT_DIR/<locale>/"
for loc in "${LOCALES[@]}"; do
	# Clear only what THIS run produces (iOS device shots + the Frame-4 widget
	# renders); leave the macOS window shots (mac-01/02/03) from the other script.
	rm -f "${OUT_DIR:?}/$loc"/[0-9][0-9]-*.png "${OUT_DIR:?}/$loc"/mac-04-widget-*.png
done
mkdir -p "$OUT_DIR"

python3 - "$RAW_DIR" "$OUT_DIR" <<'PY'
import json, os, re, shutil, sys
raw, out = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(raw, "manifest.json")))
# Attachments are "<screen>_0_<uuid>.png": iOS shots ("02-detail-daily") and the
# Frame-4 widget renders ("mac-04-widget-overview"). Locale = test-plan configuration.
pat = re.compile(r"^((?:mac-)?\d\d-[a-z0-9-]+)_0_.*\.png$")
count = 0
for group in manifest:
    for a in group.get("attachments", []):
        m = pat.match(a.get("suggestedHumanReadableName", ""))
        if not m:
            continue
        locale = a.get("configurationName", "unknown")
        dest_dir = os.path.join(out, locale)
        os.makedirs(dest_dir, exist_ok=True)
        shutil.copy(os.path.join(raw, a["exportedFileName"]),
                    os.path.join(dest_dir, m.group(1) + ".png"))
        count += 1
print(f"  extracted {count} screenshots")
PY

echo "==> Done. Screenshots in $OUT_DIR/"
find "$OUT_DIR" -type f -name '*.png' | sort
