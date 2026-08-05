#!/usr/bin/env bash
#
# capture-screenshots-macos.sh — macOS App Store screenshot capture.
#
# XCUITest can't reliably present the macOS app's window to the runner, so macOS
# uses a different mechanism than iOS: launch the built app via `open` (which
# always presents the window), let it open straight into the target state via
# launch flags, find its window with a tiny CoreGraphics/Swift helper, and grab
# just that window with `screencapture -l` (transparent PNG incl. window chrome
# + shadow — ideal for compositing onto the Figma wallpaper template).
#
# Prereq: build the app for macOS first, e.g.
#   xcodebuild build -project Solstice.xcodeproj -scheme Screenshots \
#     -destination 'platform=macOS' -derivedDataPath .screenshots/DerivedData-mac
#
# Usage:
#   Scripts/capture-screenshots-macos.sh            # all locales
#   Scripts/capture-screenshots-macos.sh en         # a subset
set -uo pipefail

cd "$(dirname "$0")/.."

APP="${APP:-$PWD/.screenshots/DerivedData-mac/Build/Products/Debug/Solstice.app}"
BIN_MATCH="Debug/Solstice.app/Contents/MacOS/Solstice"
OUT="$PWD/Screenshots/output"
SELECTED_LOCATION="7AAA4D87-4402-4D0E-A35E-2D84641A71BE"   # New York (ScreenshotFixtures)

# Pinned display instant — mirrors ScreenshotFixtures.dailyDisplayDate
# (SolsticeUITests/ScreenshotSupport.swift; keep in sync): June 1
# 12:41 PM New York, sun high. Without the pin, shots track the wall clock — a
# run at 4:30 AM New York time captures a pre-sunrise sky.
YEAR="$(TZ=America/New_York date +%Y)"
DAILY_EPOCH="$(TZ=America/New_York date -j -f "%Y-%m-%d %H:%M:%S" "$YEAR-06-01 12:41:00" +%s)"

if [ ! -d "$APP" ]; then
	echo "error: app not found at $APP — build it for macOS first (see header)" >&2
	exit 1
fi

# AppleLocale per shipping locale (mirrors Screenshots.xctestplan). The BCP-47
# language code is the locale name itself. macOS ships bash 3.2 (no associative
# arrays), so map with a case.
apple_locale_for() {
	case "$1" in
		en) echo en_US ;; de) echo de_DE ;; fr) echo fr_FR ;; es) echo es_ES ;;
		ja) echo ja_JP ;; ar) echo ar_SA ;; nl) echo nl_NL ;; zh-Hans) echo zh_CN ;;
		pl) echo pl_PL ;; it) echo it_IT ;; *) echo en_US ;;
	esac
}

LOCALES=("$@")
[ ${#LOCALES[@]} -eq 0 ] && LOCALES=(en de fr es ja ar nl zh-Hans pl it)

# Swift helper: print the frontmost on-screen Solstice window's CGWindowID.
WINID_SWIFT="$(mktemp /tmp/solstice-winid-XXXX.swift)"
cat > "$WINID_SWIFT" <<'SWIFT'
import CoreGraphics
import Foundation
let list = (CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]) ?? []
for w in list {  // front-to-back order; first match is frontmost
	guard (w[kCGWindowOwnerName as String] as? String) == "Solstice" else { continue }
	guard (w[kCGWindowLayer as String] as? Int) == 0 else { continue }
	if let n = w[kCGWindowNumber as String] as? Int { print(n); break }
}
SWIFT

kill_app() { pkill -9 -f "$BIN_MATCH" 2>/dev/null || true; }
trap 'kill_app; rm -f "$WINID_SWIFT"' EXIT

# shoot <locale> <screenEnv> <outName>
shoot() {
	local loc="$1" screenEnv="$2" name="$3"
	kill_app; sleep 1
	# Force the capture locale with -AppleLanguages. AppKit relaunches the app to apply
	# it (and that relaunch would otherwise restore a zero-window state) — the app's
	# capture-only .restorationBehavior(.disabled)/.defaultLaunchBehavior(.presented)
	# ensure the window still presents. English needs no override (default locale).
	local langArg=""
	[ "$loc" != "en" ] && langArg="-AppleLanguages ($loc)"
	# shellcheck disable=SC2086
	env UITEST_SELECTED_LOCATION="$SELECTED_LOCATION" UITEST_DISPLAY_EPOCH="$DAILY_EPOCH" $screenEnv \
		open -n "$APP" --args -UITestScreenshots $langArg

	# Non-English relaunches to apply the locale and comes up window-less. Let the
	# relaunch settle, then send a reopen event (dock-icon-click equivalent); combined
	# with the app's .defaultLaunchBehavior(.presented) this presents the main window.
	if [ -n "$langArg" ]; then
		sleep 6
		open "$APP"
		sleep 2   # allow the window (and, for settings, the overlay window) to present
	fi

	# Poll up to ~20s for the app's window (launch / settings-window can be slow).
	local wid="" i=0
	while [ "$i" -lt 20 ]; do
		sleep 1
		wid=$(swift "$WINID_SWIFT" 2>/tmp/solstice-winid.err)
		[ -n "$wid" ] && break
		i=$((i + 1))
	done

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"
	if [ -z "$wid" ]; then
		echo "  ✗ $loc/$name — no window found after 20s (swift: $(head -1 /tmp/solstice-winid.err 2>/dev/null))"
		kill_app; return
	fi
	rm -f "$dest"
	screencapture -l"$wid" "$dest"
	local rc=$?
	if [ -s "$dest" ]; then
		echo "  ✓ $loc/$name.png (window $wid, $(stat -f%z "$dest") bytes)"
	else
		echo "  ✗ $loc/$name — window $wid found but screencapture wrote nothing (rc=$rc)."
		echo "     → Grant your terminal Screen Recording permission (System Settings › Privacy & Security)."
	fi
	kill_app
}

for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	shoot "$loc" ""                                         "mac-01-detail-daily"
	shoot "$loc" "UITEST_MAC_SCREEN=detail-annual"          "mac-02-detail-annual"
	shoot "$loc" "UITEST_MAC_SCREEN=settings-notifications" "mac-03-settings-notifications"
done

echo "==> Done. macOS shots in $OUT/<locale>/mac-*.png"
