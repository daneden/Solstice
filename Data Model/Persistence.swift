//
//  Persistence.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import CoreData

class PersistenceController {
	static let shared = PersistenceController()

	static var preview: PersistenceController = {
		let result = PersistenceController(inMemory: true)
		let viewContext = result.container.viewContext
		for entry in SavedLocation.defaultData {
			let newItem = SavedLocation(context: viewContext)
			newItem.title = entry.title
			newItem.subtitle = entry.subtitle
			newItem.latitude = entry.latitude
			newItem.longitude = entry.longitude
			newItem.timeZoneIdentifier = entry.timeZoneIdentifier
			newItem.uuid = entry.uuid
		}
		do {
			try viewContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		return result
	}()

	/// In-memory store seeded with the sample locations, with CloudKit disabled.
	/// Used for deterministic App Store screenshot capture — CloudKit on an
	/// in-memory (`/dev/null`) store makes the seeding save fail intermittently
	/// with "No eligible connection available".
	static var screenshots: PersistenceController = {
		let result = PersistenceController(inMemory: true, cloudKit: false)
		let viewContext = result.container.viewContext
		for entry in SavedLocation.defaultData {
			let newItem = SavedLocation(context: viewContext)
			newItem.title = entry.title
			newItem.subtitle = entry.subtitle
			newItem.latitude = entry.latitude
			newItem.longitude = entry.longitude
			newItem.timeZoneIdentifier = entry.timeZoneIdentifier
			newItem.uuid = entry.uuid
		}
		try? viewContext.save()
		return result
	}()

	let container: NSPersistentCloudKitContainer

	init(inMemory: Bool = false, cloudKit: Bool = true) {
		container = NSPersistentCloudKitContainer(name: "Solstice")

		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
		} else {
			let fileUrl = NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite"
			container.persistentStoreDescriptions.first?.url = URL(filePath: fileUrl)
		}

		if cloudKit {
			container.persistentStoreDescriptions.first?.cloudKitContainerOptions = .init(containerIdentifier: Constants.iCloudContainerIdentifier)
		} else {
			// NSPersistentCloudKitContainer pre-populates cloudKitContainerOptions from the
			// model's CloudKit configuration, so mirroring spins up even here unless it's
			// explicitly cleared. On a /dev/null in-memory store that makes the seeding save
			// throw "No eligible connection available" — an Objective-C exception `try?` cannot
			// catch, which aborts the process. Clearing it truly disables CloudKit.
			container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil
			// Load synchronously so the store is ready before the seeding save() runs.
			container.persistentStoreDescriptions.first?.shouldAddStoreAsynchronously = false
		}

		container.viewContext.automaticallyMergesChangesFromParent = true

		container.loadPersistentStores(completionHandler: { _, error in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})

		// Observe Core Data remote change notifications.
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(storeRemoteChange(_:)),
		                                       name: .NSPersistentStoreRemoteChange,
		                                       object: container.persistentStoreCoordinator)
	}

	@objc func storeRemoteChange(_: Notification) {
		deduplicateRecords()
	}

	func deduplicateRecords() {
		container.performBackgroundTask { context in
			for entry in SavedLocation.defaultData {
				do {
					guard let uuidString = entry.uuid?.uuidString else { return }
					let request = SavedLocation.fetchRequest()
					request.predicate = NSPredicate(format: "uuid == %@", uuidString)
					let results = try context.fetch(request)

					for (index, result) in results.enumerated() {
						if index != 0 {
							context.delete(result)
						}
					}

					try context.save()
				} catch {
					print(error.localizedDescription)
				}
			}
		}
	}
}

public extension SavedLocation {
	override func awakeFromInsert() {
		super.awakeFromInsert()

		if uuid == nil {
			uuid = UUID()
		}
	}
}
