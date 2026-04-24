//
//  SolsticeShortcutsProvider.swift
//  Solstice
//
//  Created by Daniel Eden on 21/03/2023.
//

import Foundation
import AppIntents

struct SolsticeShortcutsProvider: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		return [
			AppShortcut(
				intent: GetSunsetTime(),
				phrases: [
					"Get sunset time from \(.applicationName)",
					"Get sunset time in \(.applicationName)",
				],
				shortTitle: "Get sunset time",
				systemImageName: "sunset"
			),
			AppShortcut(
				intent: GetSunriseTime(),
				phrases: [
					"Get sunrise time from \(.applicationName)",
					"Get sunrise time in \(.applicationName)",
				],
				shortTitle: "Get sunrise time",
				systemImageName: "sunrise"
			),
			AppShortcut(
				intent: ViewDaylight(),
				phrases: [
					"View daylight for a location in \(.applicationName)",
				],
				shortTitle: "View daylight",
				systemImageName: "sun.max"
			),
			AppShortcut(
				intent: ViewRemainingDaylight(),
				phrases: [
					"View remaining daylight for a location in \(.applicationName)",
				],
				shortTitle: "View remaining daylight",
				systemImageName: "timer"
			),
			AppShortcut(
				intent: GetSunAltitude(),
				phrases: [
					"Get sun altitude from \(.applicationName)",
					"What's the sun's altitude in \(.applicationName)",
				],
				shortTitle: "Get sun altitude",
				systemImageName: "arrow.up.forward"
			),
			AppShortcut(
				intent: GetSunAzimuth(),
				phrases: [
					"Get sun azimuth from \(.applicationName)",
					"What's the sun's azimuth in \(.applicationName)",
				],
				shortTitle: "Get sun azimuth",
				systemImageName: "safari"
			),
			AppShortcut(
				intent: IsSunUp(),
				phrases: [
					"Is the sun up in \(.applicationName)",
				],
				shortTitle: "Is sun up",
				systemImageName: "sun.horizon"
			),
			AppShortcut(
				intent: GetSolarNoon(),
				phrases: [
					"Get solar noon from \(.applicationName)",
					"When is solar noon in \(.applicationName)",
				],
				shortTitle: "Get solar noon",
				systemImageName: "sun.max.fill"
			),
			AppShortcut(
				intent: IsSunOnBearing(),
				phrases: [
					"Is the sun shining on a bearing in \(.applicationName)",
				],
				shortTitle: "Is sun on bearing",
				systemImageName: "sun.max.circle"
			),
			AppShortcut(
				intent: GetSunPositionAtTime(),
				phrases: [
					"Get sun position from \(.applicationName)",
				],
				shortTitle: "Get sun position",
				systemImageName: "location.north.line"
			),
			AppShortcut(
				intent: GetNextAltitudeCrossing(),
				phrases: [
					"Next sun altitude crossing from \(.applicationName)",
				],
				shortTitle: "Next altitude crossing",
				systemImageName: "arrow.up.right.circle"
			),
			AppShortcut(
				intent: GetNextAzimuthCrossing(),
				phrases: [
					"Next sun azimuth crossing from \(.applicationName)",
				],
				shortTitle: "Next azimuth crossing",
				systemImageName: "arrow.clockwise.circle"
			),
		]
	}
}
