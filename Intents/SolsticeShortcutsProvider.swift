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
		]
	}
}
