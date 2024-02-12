//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import StoreKit
import SwiftData
import CoreData

@main
struct SolsticeApp: App {
	@Environment(\.scenePhase) var phase
	@StateObject private var currentLocation = CurrentLocation()
	@StateObject private var timeMachine = TimeMachine()
	
	var container: ModelContainer = {
		let schema = Schema([SavedLocation.self])
		let existingStoreURL = NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite"
		let savedStoreURL = Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite")
		var dataExists = false
		
		if FileManager.default.fileExists(atPath: existingStoreURL) {
			dataExists = true
		} else {
			do {
				try FileManager.default.copyItem(at: savedStoreURL!, to: URL(fileURLWithPath: existingStoreURL))
			} catch {
				fatalError("Could not copy default store to app support library: \(error)")
			}
		}
		
		let modelConfiguration = ModelConfiguration(schema: schema, url: URL(fileURLWithPath: existingStoreURL))
		
		do {
			return try ModelContainer(for: schema, configurations: modelConfiguration)
		} catch {
			fatalError("Could not create ModelContainer: \(error)")
		}
	}()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(currentLocation)
				.environmentObject(timeMachine)
				.modelContainer(container)
				.task {
					for await result in Transaction.updates {
						switch result {
						case .verified(let transaction):
							print("Transaction verified in listener")
							await transaction.finish()
						case .unverified:
							print("Transaction unverified")
						}
					}
				}
		}
		#if os(visionOS) || os(macOS)
		.defaultSize(width: 1200, height: 900)
		#endif
		.onChange(of: phase) {
			switch phase {
			#if !os(watchOS)
			case .background:
				Task {
					await NotificationManager.scheduleNotifications(locationManager: currentLocation)
				}
			#endif
			default:
				currentLocation.requestLocation()
			}
		}
		
		#if os(visionOS)
		WindowGroup(id: "settings") {
			SettingsView()
				.environmentObject(currentLocation)
		}
		.defaultSize(width: 500, height: 650)
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
				.environmentObject(currentLocation)
				.frame(maxWidth: 500)
		}
		
		Window("About Equinox and Solstices", id: "about-equinox-and-solstice") {
			EquinoxAndSolsticeInfoView()
		}
		.defaultSize(width: 400, height: 650)
		#endif
	}
}
