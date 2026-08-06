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

# `screencapture` records at the display's backing scale, so a 1x CI runner
# produces window art with a quarter of the pixels a Retina Mac gives. GitHub's
# runners offer no HiDPI mode, so this cannot be recovered — what it does buy is
# a display roomy enough not to squeeze the window. Opt-in only: never
# reconfigure a real person's display out from under them.
if [ "${SCREENSHOT_FORCE_HIDPI:-0}" = "1" ]; then
	swift "$(dirname "$0")/hidpi-display.swift" --set || true
else
	swift "$(dirname "$0")/hidpi-display.swift" || true
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
# A run-scoped temp dir, not `mktemp <name>-XXXX.swift`: macOS mktemp only
# substitutes X's at the END of the template, so that form creates the literal
# "-XXXX.swift" file, succeeds once, and fails with "File exists" on every later
# run of the day. CI never noticed because each job gets a clean machine.
TMP_DIR="$(mktemp -d)"
WINID_SWIFT="$TMP_DIR/winid.swift"
cat > "$WINID_SWIFT" <<'SWIFT'
import CoreGraphics
import Foundation
let list = (CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]) ?? []
// With --all, dump every on-screen window instead: the failure path uses it to
// show what *was* present when the Solstice window was not.
if CommandLine.arguments.contains("--all") {
	for w in list {
		let owner = w[kCGWindowOwnerName as String] as? String ?? "?"
		let layer = w[kCGWindowLayer as String] as? Int ?? -1
		print("\(owner) layer=\(layer)")
	}
	exit(0)
}
for w in list {  // front-to-back order; first match is frontmost
	guard (w[kCGWindowOwnerName as String] as? String) == "Solstice" else { continue }
	guard (w[kCGWindowLayer as String] as? Int) == 0 else { continue }
	if let n = w[kCGWindowNumber as String] as? Int { print(n); break }
}
SWIFT

kill_app() { pkill -9 -f "$BIN_MATCH" 2>/dev/null || true; }

# Compile the helper once. `swift file.swift` recompiles on every invocation —
# tens of seconds per call against a fraction of a second of actual work, and
# this one runs on every iteration of the window poll below, so the poll's
# "seconds" were never seconds.
WINID_BIN="$TMP_DIR/winid"
swiftc -O "$WINID_SWIFT" -o "$WINID_BIN"

trap 'kill_app; rm -rf "$TMP_DIR"' EXIT

# A missed shot is recoverable on a desk — you see the ✗ and rerun. On CI nobody
# reads a green log, so count the misses and exit non-zero at the end.
FAILURES=0

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

	# Let the launch settle, then send a reopen event (dock-icon-click equivalent);
	# combined with the app's .defaultLaunchBehavior(.presented) this presents the
	# main window.
	#
	# Every locale gets this, English included. Non-English needs it because
	# applying -AppleLanguages relaunches the app window-less, but English needs it
	# too: without the nudge the settings window's presentation is a race that
	# English alone was losing. On a full 10-locale run, en/mac-03 was the only one
	# of 30 shots to miss — the other nine locales, which already got the reopen,
	# all passed.
	sleep 6
	open "$APP"
	sleep 2   # allow the window (and, for settings, the overlay window) to present

	# Poll for the app's window (launch / settings-window can be slow). The ceiling
	# is generous because it costs nothing when things go well — the loop breaks on
	# the first sighting. It is headroom, not a fix: raising it did not stop the
	# settings shot missing, because the window was never coming.
	local wid="" i=0
	while [ "$i" -lt 45 ]; do
		sleep 1
		wid=$("$WINID_BIN" 2>/tmp/solstice-winid.err)
		[ -n "$wid" ] && break
		i=$((i + 1))
	done

	mkdir -p "$OUT/$loc"
	local dest="$OUT/$loc/$name.png"
	if [ -z "$wid" ]; then
		echo "  ✗ $loc/$name — no window found after 45s (swift: $(head -1 /tmp/solstice-winid.err 2>/dev/null))"
		# A window that never appears has two very different causes: the process
		# died, or it is alive and simply never presented. Say which, and hand over
		# the crash log when there is one — otherwise the next debugging round is
		# guesswork against a 20-minute CI cycle.
		if pgrep -f "$BIN_MATCH" > /dev/null; then
			echo "     process is alive but presented no layer-0 window; on-screen windows:"
			"$WINID_BIN" --all 2>&1 | sed 's/^/       /' | head -20
		else
			echo "     process is NOT running — it failed to launch or crashed"
			local crash
			crash=$(ls -t "$HOME/Library/Logs/DiagnosticReports/Solstice"*.ips 2>/dev/null | head -1)
			if [ -n "$crash" ]; then
				echo "     crash report $crash:"
				grep -aE '"termination"|"exception"|Namespace|Code Signing|signal' "$crash" 2>/dev/null | head -10 | sed 's/^/       /'
			else
				echo "     no crash report found in ~/Library/Logs/DiagnosticReports"
			fi
		fi
		FAILURES=$((FAILURES + 1))
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
		FAILURES=$((FAILURES + 1))
	fi
	kill_app
}

for loc in "${LOCALES[@]}"; do
	echo "== $loc =="
	shoot "$loc" ""                                         "mac-01-detail-daily"
	shoot "$loc" "UITEST_MAC_SCREEN=detail-annual"          "mac-02-detail-annual"
	shoot "$loc" "UITEST_MAC_SCREEN=settings-notifications" "mac-03-settings-notifications"
done

if [ "$FAILURES" -gt 0 ]; then
	echo "==> $FAILURES macOS shot(s) failed — see the ✗ lines above" >&2
	exit 1
fi

echo "==> Done. macOS shots in $OUT/<locale>/mac-*.png"
