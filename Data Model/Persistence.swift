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

	/// Waits until the first CloudKit import finishes (or `timeout` elapses) so the
	/// seed gate decides against the account's true state rather than a store that's
	/// only momentarily empty because sync hasn't landed yet. No-ops when CloudKit
	/// mirroring is disabled or the store is in-memory (screenshots/preview), which
	/// would otherwise stall those paths for the full timeout.
	func awaitInitialImport(timeout: TimeInterval = 10) async {
		let description = container.persistentStoreDescriptions.first
		guard description?.cloudKitContainerOptions != nil,
		      description?.url?.path != "/dev/null",
		      // No iCloud account → no cross-device sync → no seeding race, and no import
		      // event would ever fire (which would otherwise burn the full timeout).
		      FileManager.default.ubiquityIdentityToken != nil
		else { return }

		let center = NotificationCenter.default
		let resumeGuard = ResumeOnce()
		var observer: NSObjectProtocol?

		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			observer = center.addObserver(
				forName: NSPersistentCloudKitContainer.eventChangedNotification,
				object: container,
				queue: .main
			) { notification in
				guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
					as? NSPersistentCloudKitContainer.Event
				else { return }
				if event.type == .import, event.endDate != nil, resumeGuard.tryResume() {
					continuation.resume()
				}
			}

			Task {
				try? await Task.sleep(for: .seconds(timeout))
				if resumeGuard.tryResume() { continuation.resume() }
			}
		}

		if let observer { center.removeObserver(observer) }
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

/// Ensures a continuation is resumed exactly once when two sources (the import
/// notification and the timeout) can race to complete it.
private final class ResumeOnce: @unchecked Sendable {
	private let lock = NSLock()
	private var resumed = false

	func tryResume() -> Bool {
		lock.lock()
		defer { lock.unlock() }
		if resumed { return false }
		resumed = true
		return true
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
