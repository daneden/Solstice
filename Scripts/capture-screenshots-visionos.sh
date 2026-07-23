#!/usr/bin/env bash
#
# capture-screenshots-visionos.sh — Apple Vision Pro App Store screenshot capture.
#
# Like the watchOS pipeline (and unlike iOS/iPadOS), there is no UI-test runner:
# the shared screenshot launch environment (-UITestScreenshots + UITEST_* env)
# drives the app straight into each target state, so the pipeline is simply
# `simctl launch` with per-locale arguments followed by `simctl io screenshot`.
#
# App Store visionOS screenshots must be exactly 3840×2160 (16:9, landscape,
# PNG/JPEG, no alpha). The visionOS 27 simulator viewport renders 3840×2160
# natively; the post-processing pass strips the alpha channel (which App Store
# Connect rejects) and aspect-FILLS into 3840×2160 — a no-op at native size, but
# it keeps older 4:3 (2732×2048) simulator runtimes usable via upscale + crop.
#
# Prereq: build the app for the visionOS simulator first, e.g.
#   xcodebuild build -project Solstice.xcodeproj -scheme Solstice \
#     -destination 'platform=visionOS Simulator,name=Apple Vision Pro,OS=27.0' \
#     -derivedDataPath .screenshots/DerivedData-visionos
#
# Usage:
#   Scripts/capture-screenshots-visionos.sh            # all locales
#   Scripts/capture-screenshots-visionos.sh en ja      # a subset
set -uo pipefail

cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE_NAME:-Apple Vision Pro}"
APP="${APP:-$PWD/.screenshots/DerivedData-visionos/Build/Products/Debug-xrsimulator/Solstice.app}"
BUNDLE_ID="me.daneden.Solstice"
OUT="$PWD/Screenshots/output"
SELECTED_LOCATION="7AAA4D87-4402-4D0E-A35E-2D84641A71BE"   # New York (ScreenshotFixtures)
TIME_OFFSET_DAYS="92"                                       # mirrors ScreenshotFixtures.timeTravelOffsetDays

if [ ! -d "$APP" ]; then
	echo "error: app not found at $APP — build it for the visionOS simulator first (see header)" >&2
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

# Swift helper: rewrite a PNG in place as exactly 3840×2160 with no alpha —
# aspect-fill (upscale to width, centre-crop height) in one CoreGraphics pass.
# App Store screenshots must be this exact size, and simctl PNGs carry an alpha
# channel that App Store Connect rejects (sips can't drop it).
FILL_CROP_SWIFT="$(mktemp /tmp/solstice-vision-fill-XXXX.swift)"
cat > "$FILL_CROP_SWIFT" <<'SWIFT'
import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

let W = 3840, H = 2160
for path in CommandLine.arguments.dropFirst() {
	let url = URL(fileURLWithPath: path)
	guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
	      let img = CGImageSourceCreateImageAtIndex(src, 0, nil),
	      let ctx = CGContext(data: nil, width: W, height: H,
	                          bitsPerComponent: 8, bytesPerRow: 0,
	                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
	                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
	else { FileHandle.standardError.write("failed to read \(path)\n".data(using: .utf8)!); exit(1) }
	let scale = max(CGFloat(W) / CGFloat(img.width), CGFloat(H) / CGFloat(img.height))
	let drawW = CGFloat(img.width) * scale, drawH = CGFloat(img.height) * scale
	ctx.interpolationQuality = .high
	ctx.draw(img, in: CGRect(x: (CGFloat(W) - drawW) / 2, y: (CGFloat(H) - drawH) / 2, width: drawW, height: drawH))
	guard let out = ctx.makeImage(),
	      let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
	else { exit(1) }
	CGImageDestinationAddImage(dest, out, nil)
	guard CGImageDestinationFinalize(dest) else { exit(1) }
}
SWIFT
trap 'rm -f "$FILL_CROP_SWIFT"' EXIT

# Two Vision Pro sims can coexist (one per runtime); take the newest runtime —
# `simctl list` orders runtime sections ascending. Override via DEVICE_UDID.
UDID="${DEVICE_UDID:-$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | tail -1 | grep -oE '[0-9A-F-]{36}')}"
if [ -z "$UDID" ]; then
	echo "error: no available simulator named '$DEVICE_NAME'" >&2
	exit 1
fi

echo "==> Booting $DEVICE_NAME ($UDID)"
# Fresh boot: visionOS restores per-scene window placement across launches, and
# stale spatial state can leave windows parked far/dim against the bright wall.
xcrun simctl shutdown "$UDID" 2>/dev/null || true
sleep 2
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID"
xcrun simctl install "$UDID" "$APP"

# shoot <locale> <visionScreen-or-empty> <timeOffset-or-empty> <settle-secs> <outName>
shoot() {
	local loc="$1" screen="$2" offset="$3" settle="$4" name="$5"
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
	sleep 1

	# Locale comes from per-process launch arguments (same mechanism as the
	# watchOS capture); SwiftUI derives layout direction (ar → RTL) from the language.
	local langArgs=()
	if [ "$loc" != "en" ]; then
		langArgs=(-AppleLanguages "($loc)" -AppleLocale "$(apple_locale_for "$loc")")
	fi

	# Only set the UITEST_* env vars when they carry a value — an empty string is
	# not "unset" to the app (an empty forced selection would select nothing).
	local envArgs=("SIMCTL_CHILD_UITEST_SELECTED_LOCATION=$SELECTED_LOCATION")
	[ -n "$screen" ] && envArgs+=("SIMCTL_CHILD_UITEST_VISION_SCREEN=$screen")
	[ -n "$offset" ] && envArgs+=("SIMCTL_CHILD_UITEST_TIME_OFFSET_DAYS=$offset")

	env "${envArgs[@]}" \
		xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITestScreenshots "${langArgs[@]+"${langArgs[@]}"}" > /dev/null
	sleep "$settle"

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"
	rm -f "$dest"
	xcrun simctl io "$UDID" screenshot --type png "$dest" > /dev/null
	if [ -s "$dest" ]; then
		swift "$FILL_CROP_SWIFT" "$dest"
		echo "  ✓ $loc/$name.png ($(sips -g pixelWidth -g pixelHeight "$dest" | awk '/pixel/ {printf "%s ", $2}'| sed 's/ $//' | tr ' ' 'x'))"
	else
		echo "  ✗ $loc/$name — screenshot wrote nothing"
	fi
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
}

# The visionOS simulator takes ~15–20s past the launch plate before the window
# content is rendered, so the settle times are generous. The solstice-info
# window additionally hosts the RealityKit globe, which needs load + lighting.
for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	shoot "$loc" ""              ""                  20 "vision-01-app"
	shoot "$loc" "solstice-info" ""                  25 "vision-02-solstice-info"
	shoot "$loc" ""              "$TIME_OFFSET_DAYS" 20 "vision-03-time-travel"
done

echo "==> Done. Vision Pro shots in $OUT/<locale>/vision-*.png (3840×2160)"
