//
//  AppChangeMigrator.swift
//  Solstice
//
//  Created by Daniel Eden on 19/06/2024.
//

import SwiftUI
import CoreData

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
				let nycUUIDString = "7AAA4D87-4402-4D0E-A35E-2D84641A71BE"
				guard let defaultDataUrl = Bundle.main.url(forResource: "defaultData", withExtension: "json") else {
					return print("No URL for defaultData.json")
				}
				
				do {
					let defaultDataFileData = try Data(contentsOf: defaultDataUrl)
					let defaultData = try JSONDecoder().decode([SavedLocation.CodableRepresentation].self, from: defaultDataFileData)
					
					let fetchRequest = SavedLocation.fetchRequest()
					let currentData = try modelContext.fetch(fetchRequest)
					
					if currentData.isEmpty {
						for entry in defaultData {
							let newRecord = SavedLocation(context: modelContext)
							newRecord.title = entry.title
							newRecord.subtitle = entry.subtitle
							newRecord.uuid = entry.uuid
							newRecord.latitude = entry.latitude
							newRecord.longitude = entry.longitude
							newRecord.timeZoneIdentifier = entry.timeZoneIdentifier
							
							modelContext.insert(newRecord)
							try modelContext.save()
						}
					} else if let newYorkStateEntry = currentData.first(where: { $0.uuid?.uuidString == nycUUIDString }),
										let newYorkCityEntry = defaultData.first(where: { $0.uuid?.uuidString == nycUUIDString }){
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
		self.modifier(AppChangeMigrator())
	}
}
