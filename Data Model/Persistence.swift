//
//  Persistence.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newItem = SavedLocation(context: viewContext)
            newItem.title = "Example location \(i)"
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

    let container: NSPersistentCloudKitContainer
	
	private func preloadData() {
		let sourceSqliteURLs = [
			Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite"),
			Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite-wal"),
			Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite-shm")
		]
		
		let destSqliteURLs = [
			URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite"),
			URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite-wal"),
			URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite-shm")]
		
		for index in 0...sourceSqliteURLs.count-1 {
			do {
				try FileManager.default.copyItem(at: sourceSqliteURLs[index]!, to: destSqliteURLs[index])
			} catch {
				print("Could not preload data")
			}
		}
	}

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Solstice")
			
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
				} else {
					let fileUrl = NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite"
					
					if !FileManager.default.fileExists(atPath: fileUrl) {
						preloadData()
					}
				}
			
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
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
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension SavedLocation {
	public override func awakeFromInsert() {
		super.awakeFromInsert()
		uuid = UUID()
	}
}
