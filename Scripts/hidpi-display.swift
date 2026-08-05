// hidpi-display.swift — report the main display's modes and, with --set, switch
// to a HiDPI (2x) one.
//
// Why this exists: `screencapture` records at the display's backing scale. A
// Retina Mac yields 2x window captures; a CI runner's virtual display is 1x, so
// the same capture arrives with a quarter of the pixels and the composed App
// Store screenshot goes soft. Switching the runner to a HiDPI mode restores it.
//
// The catch is that a HiDPI mode halves the point-space, and the Solstice window
// needs roughly 912x764 pt. A 1920x1080 display in HiDPI offers only 960x540 pt,
// which the window does not fit in — a smaller capture than we started with.
// So only modes with room to spare are eligible, and when none qualifies this
// leaves the display alone and the capture proceeds at 1x.
//
//   swift Scripts/hidpi-display.swift          # report only
//   swift Scripts/hidpi-display.swift --set    # report, then switch if eligible

import CoreGraphics
import Foundation

// Enough for the window plus margin for the shadow `screencapture -l` includes.
let requiredPointWidth = 1100
let requiredPointHeight = 850

let display = CGMainDisplayID()

/// Without this option the list omits the scaled (HiDPI) variants entirely.
let options = ["kCGDisplayShowDuplicateLowResolutionModes": kCFBooleanTrue!] as CFDictionary

guard let modes = CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode] else {
	print("hidpi: could not read display modes")
	exit(0)
}

func describe(_ m: CGDisplayMode) -> String {
	"\(m.width)x\(m.height) pt -> \(m.pixelWidth)x\(m.pixelHeight) px"
}

func isHiDPI(_ m: CGDisplayMode) -> Bool {
	m.pixelWidth >= m.width * 2
}

if let current = CGDisplayCopyDisplayMode(display) {
	let scale = Double(current.pixelWidth) / Double(current.width)
	print("hidpi: current \(describe(current)) (scale \(String(format: "%.1f", scale))x)")
}

let hiDPI = modes.filter(isHiDPI)
print("hidpi: \(modes.count) modes total, \(hiDPI.count) HiDPI")
for m in hiDPI.sorted(by: { $0.pixelWidth < $1.pixelWidth }) {
	let fits = m.width >= requiredPointWidth && m.height >= requiredPointHeight
	print("hidpi:   \(describe(m))\(fits ? "  [fits the window]" : "  [too small]")")
}

let eligible = hiDPI
	.filter { $0.width >= requiredPointWidth && $0.height >= requiredPointHeight }
	.sorted { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }

guard CommandLine.arguments.contains("--set") else { exit(0) }

guard let best = eligible.last else {
	print("hidpi: no HiDPI mode leaves room for a \(requiredPointWidth)x\(requiredPointHeight) pt window — leaving the display alone")
	exit(0)
}

let result = CGDisplaySetDisplayMode(display, best, nil)
if result == .success {
	// Re-read rather than trust the call: a mode change can be silently refused.
	if let now = CGDisplayCopyDisplayMode(display) {
		print("hidpi: set \(describe(now))")
	}
} else {
	print("hidpi: CGDisplaySetDisplayMode failed (\(result.rawValue)) — continuing at the current scale")
}
