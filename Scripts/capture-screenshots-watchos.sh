#!/usr/bin/env bash
#
# capture-screenshots-watchos.sh — Apple Watch App Store screenshot capture.
#
# The watch app has no UI-test target, and doesn't need one for these shots: the
# shared screenshot launch environment (-UITestScreenshots + UITEST_* env) drives
# the app straight into each target state, so the pipeline is simply
# `simctl launch` with per-locale arguments followed by `simctl io screenshot`.
#
# Captures on the Apple Watch Ultra 3 (49mm) simulator — 422×514 px, the largest
# App Store watch size. App Store Connect scales one uploaded set down for all
# smaller watch sizes, so only this size is captured.
#
# Prereq: build the watch app for the simulator first, e.g.
#   xcodebuild build -project Solstice.xcodeproj -scheme "Solstice watchOS Watch App" \
#     -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)' \
#     -derivedDataPath .screenshots/DerivedData-watchos
#
# Usage:
#   Scripts/capture-screenshots-watchos.sh            # all locales
#   Scripts/capture-screenshots-watchos.sh en ja      # a subset
set -uo pipefail

cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE_NAME:-Apple Watch Ultra 3 (49mm)}"
APP="${APP:-$PWD/.screenshots/DerivedData-watchos/Build/Products/Debug-watchsimulator/Solstice watchOS Watch App.app}"
BUNDLE_ID="me.daneden.Solstice.watchkitapp"
OUT="$PWD/Screenshots/output"
SELECTED_LOCATION="7AAA4D87-4402-4D0E-A35E-2D84641A71BE"   # New York (ScreenshotFixtures)

# Pinned display instants — mirrors ScreenshotFixtures (SolsticeUITests/ScreenshotSupport.swift;
# keep in sync). Daily shots: June 1 12:41 PM New York, sun high, Time
# Machine visibly inactive. Time travel: October 26 sunset in New York, reached via
# the day offset so the app's "today" stays June 1. Without the pin, shots track
# the wall clock — a run at 4:30 AM New York time captures a pre-sunrise sky.
YEAR="$(TZ=America/New_York date +%Y)"
DAILY_EPOCH="$(TZ=America/New_York date -j -f "%Y-%m-%d %H:%M:%S" "$YEAR-06-01 12:41:00" +%s)"
TRAVEL_EPOCH="$(TZ=America/New_York date -j -f "%Y-%m-%d %H:%M:%S" "$YEAR-10-26 18:01:46" +%s)"
TIME_OFFSET_DAYS=$(( (TRAVEL_EPOCH - DAILY_EPOCH + 43200) / 86400 ))

if [ ! -d "$APP" ]; then
	echo "error: app not found at $APP — build it for the watchOS simulator first (see header)" >&2
	exit 1
fi

# AppleLocale per shipping locale (mirrors Screenshots.xctestplan). macOS ships
# bash 3.2 (no associative arrays), so map with a case.
apple_locale_for() {
	case "$1" in
		en) echo en_US ;; de) echo de_DE ;; fr) echo fr_FR ;; es) echo es_ES ;;
		ja) echo ja_JP ;; ar) echo ar_SA ;; nl) echo nl_NL ;; zh-Hans) echo zh_CN ;;
		pl) echo pl_PL ;; it) echo it_IT ;; *) echo en_US ;;
	esac
}

LOCALES=("$@")
[ ${#LOCALES[@]} -eq 0 ] && LOCALES=(en de fr es ja ar nl zh-Hans pl it)

# Swift helper: rewrite a PNG without its alpha channel in place. App Store
# screenshots must have no alpha, simctl PNGs carry one, and sips can't drop it.
STRIP_ALPHA_SWIFT="$(mktemp /tmp/solstice-strip-alpha-XXXX.swift)"
cat > "$STRIP_ALPHA_SWIFT" <<'SWIFT'
import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

for path in CommandLine.arguments.dropFirst() {
	let url = URL(fileURLWithPath: path)
	guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
	      let img = CGImageSourceCreateImageAtIndex(src, 0, nil),
	      let ctx = CGContext(data: nil, width: img.width, height: img.height,
	                          bitsPerComponent: 8, bytesPerRow: 0,
	                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
	                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
	else { FileHandle.standardError.write("failed to read \(path)\n".data(using: .utf8)!); exit(1) }
	ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
	guard let out = ctx.makeImage(),
	      let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
	else { exit(1) }
	CGImageDestinationAddImage(dest, out, nil)
	guard CGImageDestinationFinalize(dest) else { exit(1) }
}
SWIFT
trap 'rm -f "$STRIP_ALPHA_SWIFT"' EXIT

UDID=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')
if [ -z "$UDID" ]; then
	echo "error: no available simulator named '$DEVICE_NAME'" >&2
	exit 1
fi

echo "==> Booting $DEVICE_NAME ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID"
xcrun simctl install "$UDID" "$APP"

# A missed shot is recoverable on a desk — you see the ✗ and rerun. On CI nobody
# reads a green log, so count the misses and exit non-zero at the end.
FAILURES=0

# shoot <locale> <selectedLocation-or-empty> <timeOffset-or-empty> <displayEpoch> <outName>
shoot() {
	local loc="$1" selected="$2" offset="$3" epoch="$4" name="$5"
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
	sleep 1

	# Locale comes from per-process launch arguments (same mechanism as the macOS
	# capture); SwiftUI derives layout direction (ar → RTL) from the language.
	local langArgs=()
	if [ "$loc" != "en" ]; then
		langArgs=(-AppleLanguages "($loc)" -AppleLocale "$(apple_locale_for "$loc")")
	fi

	# Only set the UITEST_* env vars when they carry a value — an empty string is
	# not "unset" to the app (an empty forced selection would select nothing).
	local envArgs=()
	[ -n "$selected" ] && envArgs+=("SIMCTL_CHILD_UITEST_SELECTED_LOCATION=$selected")
	[ -n "$offset" ] && envArgs+=("SIMCTL_CHILD_UITEST_TIME_OFFSET_DAYS=$offset")
	[ -n "$epoch" ] && envArgs+=("SIMCTL_CHILD_UITEST_DISPLAY_EPOCH=$epoch")

	env "${envArgs[@]+"${envArgs[@]}"}" \
		xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITestScreenshots "${langArgs[@]+"${langArgs[@]}"}" > /dev/null
	sleep 5   # let the UI settle (list render / detail push / time-machine offset)

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"
	rm -f "$dest"
	xcrun simctl io "$UDID" screenshot --type png "$dest" > /dev/null
	if [ -s "$dest" ]; then
		swift "$STRIP_ALPHA_SWIFT" "$dest"
		echo "  ✓ $loc/$name.png ($(sips -g pixelWidth -g pixelHeight "$dest" | awk '/pixel/ {printf "%s ", $2}'| sed 's/ $//' | tr ' ' 'x'))"
	else
		echo "  ✗ $loc/$name — screenshot wrote nothing"
		FAILURES=$((FAILURES + 1))
	fi
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
}

for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	shoot "$loc" ""                   ""                  "$DAILY_EPOCH"  "watch-01-location-list"
	shoot "$loc" "$SELECTED_LOCATION" ""                  "$DAILY_EPOCH"  "watch-02-detail"
	shoot "$loc" "$SELECTED_LOCATION" "$TIME_OFFSET_DAYS" "$TRAVEL_EPOCH" "watch-03-time-travel"
done

if [ "$FAILURES" -gt 0 ]; then
	echo "==> $FAILURES watch shot(s) failed — see the ✗ lines above" >&2
	exit 1
fi

echo "==> Done. Watch shots in $OUT/<locale>/watch-*.png (422×514, Ultra 3)"
