//
//  Globals.swift
//  Solstice
//
//  Created by Daniel Eden on 07/03/2023.
//

import Foundation

var chartHeight: CGFloat = {
	#if !os(watchOS)
		360
	#else
		200
	#endif
}()

var chartMarkSize: Double = {
	#if os(watchOS)
		4
	#else
		6
	#endif
}()

/// The user's calendar. Correct for day-level arithmetic and for anything the user reads.
/// Every operation the app performs with it — `startOfDay`, day offsets, `isDateInToday` —
/// resolves to the same instant under any calendar, because all of them run midnight to
/// midnight in the local time zone.
let calendar = Calendar.autoupdatingCurrent

/// Solar-event arithmetic. `SolsticeCalculator` evaluates a polynomial over a proleptic
/// Gregorian year, so it cannot accept a year number from another calendar: a Hijri (1447),
/// Persian (1405) or Buddhist (2569) year lands centuries from the intended date.
let solarCalendar: Calendar = {
	var calendar = Calendar(identifier: .gregorian)
	calendar.locale = .autoupdatingCurrent
	return calendar
}()

/// The viewer's own time zone — what "3 hours behind you" is measured against.
///
/// Pinned to UTC while capturing screenshots. The offset shown next to a
/// location's local time is relative to this, so without pinning it the same
/// screen reads "-4 hr" captured on a UTC CI runner and "-5 hrs" captured on a
/// Mac in BST. Everything else about a capture is already pinned — clock,
/// location, locale, chart type — and this is the last thing that let the
/// machine leak into the output.
let localTimeZone: TimeZone = {
	#if DEBUG
		if ScreenshotLaunch.isCapturing {
			return TimeZone(secondsFromGMT: 0) ?? .gmt
		}
	#endif
	return .autoupdatingCurrent
}()

// MARK: - App Constants

enum Constants {
	/// App Group identifier for sharing data between app and extensions
	static let appGroupIdentifier = "group.me.daneden.Solstice"

	/// iCloud container identifier for CloudKit sync
	static let iCloudContainerIdentifier = "iCloud.me.daneden.Solstice"

	/// Background task identifier for notification scheduling
	static let backgroundTaskIdentifier = "me.daneden.Solstice.notificationScheduler"

	/// User activity type for viewing locations (Handoff/Spotlight)
	static let viewLocationActivityType = "me.daneden.Solstice.viewLocation"

	/// Prefix for notification request identifiers
	static let notificationIdentifierPrefix = "me.daneden.Solstice.notification-"

	enum IAPProducts {
		static let tipSmall = "me.daneden.Solstice.iap.tip.small"
		static let tipMedium = "me.daneden.Solstice.iap.tip.medium"
		static let tipLarge = "me.daneden.Solstice.iap.tip.large"

		static let all = [tipSmall, tipMedium, tipLarge]
	}
}
