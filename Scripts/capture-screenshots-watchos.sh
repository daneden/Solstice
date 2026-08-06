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

# Compile the helper once. `swift file.swift` recompiles on every invocation,
# which dominated the runtime here — tens of seconds per call against a fraction
# of a second of actual work, paid once per screenshot.
STRIP_ALPHA_BIN="${STRIP_ALPHA_SWIFT%.swift}"
swiftc -O "$STRIP_ALPHA_SWIFT" -o "$STRIP_ALPHA_BIN"

trap 'rm -f "$STRIP_ALPHA_SWIFT" "$STRIP_ALPHA_BIN"' EXIT

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
# Carried across shots so each one can prove it differs from the last. Reset by
# launch_locale, since the first shot of a locale has nothing to differ from.
LAST_SUM=""
COMMAND_DIR=""
SEQ=0

# One launch per locale, every shot within it.
#
# Selecting each shot's state through launch environment variables meant a
# terminate/launch/first-render cycle per shot. The app also reads a command
# file now, so selection and time offset can change in place.
#
# Locale still needs its own launch: SwiftUI resolves `Text` against the
# environment locale, but the app formats several strings through
# `Locale.current`, which no environment override reaches. See
# ScreenshotSupport.swift.

# launch_locale <locale> — fresh process in that language, on the list, pinned to
# the daily instant.
launch_locale() {
	local loc="$1"
	xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
	local t=0
	while [ "$t" -lt 15 ]; do
		xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE_ID" || break
		sleep 1
		t=$((t + 1))
	done

	# SwiftUI derives layout direction (ar → RTL) from the launch language.
	local langArgs=()
	if [ "$loc" != "en" ]; then
		langArgs=(-AppleLanguages "($loc)" -AppleLocale "$(apple_locale_for "$loc")")
	fi

	env "SIMCTL_CHILD_UITEST_DISPLAY_EPOCH=$DAILY_EPOCH" \
		xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITestScreenshots "${langArgs[@]+"${langArgs[@]}"}" > /dev/null

	COMMAND_DIR="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)/Documents"
	mkdir -p "$COMMAND_DIR"
	rm -f "$COMMAND_DIR/capture-command.json"
	SEQ=0
	LAST_SUM=""
}

# command_app <json-body> — asks the running app to change state, no relaunch.
command_app() {
	SEQ=$((SEQ + 1))
	printf '{"seq":%s,%s}' "$SEQ" "$1" > "$COMMAND_DIR/capture-command.json"
}

# shoot <locale> <settle-secs> <outName>
shoot() {
	local loc="$1" settle="$2" name="$3"
	sleep "$settle"

	# A terminated app leaves the simulator showing its home screen, and a home
	# screen frame differs from the previous shot just like a real state change
	# would — so the frame-change check below waves it through. Thirty visionOS
	# shots once collapsed to eleven unique images this way, most of them the
	# springboard. Confirm the process is alive before believing any frame.
	if ! xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE_ID"; then
		echo "  ✗ $loc/$name — app is not running; the frame would be the home screen"
		FAILURES=$((FAILURES + 1))
		return
	fi

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"

	# The settle is a floor: a command is applied asynchronously, so keep
	# re-grabbing until the frame differs from the previous shot. An identical
	# frame means the new state hasn't rendered, and accepting it would ship one
	# shot's content under another shot's name.
	local sum="" attempt=0
	while [ "$attempt" -lt 8 ]; do
		rm -f "$dest"
		xcrun simctl io "$UDID" screenshot --type png "$dest" > /dev/null
		[ -s "$dest" ] || break
		sum="$(md5 -q "$dest")"
		[ -z "$LAST_SUM" ] && break
		[ "$sum" != "$LAST_SUM" ] && break
		sleep 3
		attempt=$((attempt + 1))
	done

	if [ ! -s "$dest" ]; then
		echo "  ✗ $loc/$name — screenshot wrote nothing"
		FAILURES=$((FAILURES + 1))
	elif [ -n "$LAST_SUM" ] && [ "$sum" = "$LAST_SUM" ]; then
		echo "  ✗ $loc/$name — still identical to the previous shot after $((attempt * 3))s; the app never changed state"
		rm -f "$dest"
		FAILURES=$((FAILURES + 1))
	else
		LAST_SUM="$sum"   # compare raw captures: strip-alpha rewrites the file
		"$STRIP_ALPHA_BIN" "$dest"
		echo "  ✓ $loc/$name.png ($(sips -g pixelWidth -g pixelHeight "$dest" | awk '/pixel/ {printf "%s ", $2}'| sed 's/ $//' | tr ' ' 'x'))"
	fi
}

for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	launch_locale "$loc"
	shoot "$loc" 5 "watch-01-location-list"

	command_app "\"location\":\"$SELECTED_LOCATION\""
	shoot "$loc" 3 "watch-02-detail"

	command_app "\"location\":\"$SELECTED_LOCATION\",\"offset\":$TIME_OFFSET_DAYS,\"epoch\":$TRAVEL_EPOCH"
	shoot "$loc" 3 "watch-03-time-travel"
done

if [ "$FAILURES" -gt 0 ]; then
	echo "==> $FAILURES watch shot(s) failed — see the ✗ lines above" >&2
	exit 1
fi

echo "==> Done. Watch shots in $OUT/<locale>/watch-*.png (422×514, Ultra 3)"
