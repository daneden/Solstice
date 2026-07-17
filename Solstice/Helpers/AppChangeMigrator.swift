//
//  AppChangeMigrator.swift
//  Solstice
//
//  Created by Daniel Eden on 19/06/2024.
//

import CoreData
import SwiftUI

struct AppChangeMigrator: ViewModifier {
	@Environment(\.managedObjectContext) var modelContext
	@AppStorage(Preferences.NotificationSettings._notificationTime) var notificationTime
	@AppStorage(Preferences.NotificationSettings.notificationDateComponents) var notificationDateComponents

	func body(content: Content) -> some View {
		content
			.task(id: "Notification schedule strategy migration") {
				if notificationDateComponents == Preferences.NotificationSettings.defaultDateComponents {
					notificationDateComponents = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: notificationTime)
				}
			}
			.task(id: "Default data initialisation/migration") {
				// The screenshot store is pre-seeded and uses its own controller; skip
				// the gate entirely so we never touch (or await CloudKit on) `.shared`.
				guard !ScreenshotLaunch.isCapturing else { return }

				// Decide against the account's true state, not a store that's only
				// momentarily empty because CloudKit hasn't imported yet.
				await PersistenceController.shared.awaitInitialImport()
				SeedState.synchronize()

				do {
					let fetchRequest = SavedLocation.fetchRequest()
					let currentData = try modelContext.fetch(fetchRequest)

					// Seed the defaults exactly once per iCloud account. If the account has
					// never been seeded and the store is empty, seed now; either way, mark it
					// seeded so a later transient-empty (e.g. a new device before import) or a
					// user who deleted every location never triggers a re-seed.
					if !SeedState.didSeedDefaultLocations {
						if currentData.isEmpty {
							for entry in SavedLocation.defaultData {
								let newRecord = SavedLocation(context: modelContext)
								newRecord.title = entry.title
								newRecord.subtitle = entry.subtitle
								newRecord.uuid = entry.uuid
								newRecord.latitude = entry.latitude
								newRecord.longitude = entry.longitude
								newRecord.timeZoneIdentifier = entry.timeZoneIdentifier

								modelContext.insert(newRecord)
							}
							try modelContext.save()
						}
						SeedState.didSeedDefaultLocations = true
					}

					// Migrate the legacy "New York State" record to New York City. Runs for
					// existing users regardless of the seed gate (freshly seeded data already
					// carries the corrected city entry).
					if let newYorkStateEntry = currentData.first(where: { $0.uuid?.uuidString == SavedLocation.nycUUIDString }),
					   let newYorkCityEntry = SavedLocation.defaultData.first(where: { $0.uuid?.uuidString == SavedLocation.nycUUIDString })
					{
						newYorkStateEntry.title = newYorkCityEntry.title
						newYorkStateEntry.subtitle = newYorkCityEntry.subtitle
						newYorkStateEntry.latitude = newYorkCityEntry.latitude
						newYorkStateEntry.longitude = newYorkCityEntry.longitude
						try modelContext.save()
					}
				} catch {
					print(error.localizedDescription)
				}
			}
	}
}

extension View {
	func migrateAppFeatures() -> some View {
		modifier(AppChangeMigrator())
	}
}
