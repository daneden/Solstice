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

# Compile the helper once. `swift file.swift` recompiles on every invocation,
# which dominated the runtime here — tens of seconds per call against a fraction
# of a second of actual work, paid once per screenshot.
FILL_CROP_BIN="${FILL_CROP_SWIFT%.swift}"
swiftc -O "$FILL_CROP_SWIFT" -o "$FILL_CROP_BIN"

trap 'rm -f "$FILL_CROP_SWIFT" "$FILL_CROP_BIN"' EXIT

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

# A missed shot is recoverable on a desk — you see the ✗ and rerun. On CI nobody
# reads a green log, so count the misses and exit non-zero at the end.
FAILURES=0
# Carried across shots so each one can prove it differs from the last.
LAST_SUM=""
LAST_PID=""

# shoot <locale> <visionScreen-or-empty> <timeOffset-or-empty> <displayEpoch> <settle-secs> <outName>
shoot() {
	local loc="$1" screen="$2" offset="$3" epoch="$4" settle="$5" name="$6"

	# Wait for the process to actually be gone before relaunching. `simctl launch`
	# returns a PID immediately, and against a still-running instance it surfaces
	# that one without applying the new arguments — which is how a shot ends up
	# with the previous window *and* the previous locale.
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
	local gone=0 t=0
	while [ "$t" -lt 15 ]; do
		if ! xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE_ID"; then
			gone=1; break
		fi
		sleep 1
		t=$((t + 1))
	done
	[ "$gone" = "1" ] || echo "     warning: $BUNDLE_ID still listed after 15s; relaunch may not apply"

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
	[ -n "$epoch" ] && envArgs+=("SIMCTL_CHILD_UITEST_DISPLAY_EPOCH=$epoch")

	# `simctl launch` prints "<bundle id>: <pid>" — keep it, so a PID that did not
	# change tells us the relaunch was a no-op rather than a fresh process.
	local launchOut
	launchOut=$(env "${envArgs[@]}" \
		xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITestScreenshots "${langArgs[@]+"${langArgs[@]}"}" 2>&1)
	local pid="${launchOut##*: }"
	if [ -n "$LAST_PID" ] && [ "$pid" = "$LAST_PID" ]; then
		echo "     warning: pid $pid unchanged from the previous shot — the app did not restart"
	fi
	LAST_PID="$pid"
	sleep "$settle"

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"
	rm -f "$dest"
	xcrun simctl io "$UDID" screenshot --type png "$dest" > /dev/null
	if [ -s "$dest" ]; then
		"$FILL_CROP_BIN" "$dest"
		# A shot byte-identical to the previous one means the app never changed
		# state — the relaunch was swallowed and this frame belongs to the shot
		# before it. Silently, that ships one locale's screenshot under another
		# language, which is exactly what happened before this check existed.
		local sum
		sum="$(md5 -q "$dest")"
		if [ -n "$LAST_SUM" ] && [ "$sum" = "$LAST_SUM" ]; then
			echo "  ✗ $loc/$name — identical to the previous shot; the app did not change state"
			rm -f "$dest"
			FAILURES=$((FAILURES + 1))
		else
			LAST_SUM="$sum"
			echo "  ✓ $loc/$name.png ($(sips -g pixelWidth -g pixelHeight "$dest" | awk '/pixel/ {printf "%s ", $2}'| sed 's/ $//' | tr ' ' 'x'))"
		fi
	else
		echo "  ✗ $loc/$name — screenshot wrote nothing"
		FAILURES=$((FAILURES + 1))
	fi
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
}

# The visionOS simulator takes ~15–20s past the launch plate before the window
# content is rendered, so the settle times are generous. The solstice-info
# window additionally hosts the RealityKit globe, which needs load + lighting.
for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	shoot "$loc" ""              ""                  "$DAILY_EPOCH"  20 "vision-01-app"
	shoot "$loc" "solstice-info" ""                  "$DAILY_EPOCH"  25 "vision-02-solstice-info"
	shoot "$loc" ""              "$TIME_OFFSET_DAYS" "$TRAVEL_EPOCH" 20 "vision-03-time-travel"
done

if [ "$FAILURES" -gt 0 ]; then
	echo "==> $FAILURES Vision Pro shot(s) failed — see the ✗ lines above" >&2
	exit 1
fi

echo "==> Done. Vision Pro shots in $OUT/<locale>/vision-*.png (3840×2160)"
