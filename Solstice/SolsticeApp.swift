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
	private var currentLocation = CurrentLocation()
	@StateObject private var timeMachine = TimeMachine()
	
	var container: ModelContainer = {
		let schema = Schema([SavedLocation.self])
		let existingStoreURL = NSPersistentContainer.defaultDirectoryURL().relativePath + "/Solstice.sqlite"
		let savedStoreURL = Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite")
		
		if !FileManager.default.fileExists(atPath: existingStoreURL) {
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
				.environment(currentLocation)
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
				.task(id: phase) {
					switch phase {
					#if !os(watchOS)
					case .background:
						Task {
							await NotificationManager.scheduleNotifications(locationManager: currentLocation)
						}
					#endif
					default:
						try? await currentLocation.requestLocation()
					}
				}
				.task(id: currentLocation.authorizationStatus) {
					do {
						if currentLocation.isAuthorized {
							try await currentLocation.requestLocation()
						}
					} catch {
						print(error)
					}
				}
		}
		#if os(visionOS) || os(macOS)
		.defaultSize(width: 1200, height: 900)
		#endif
		
		#if os(visionOS)
		WindowGroup(id: "settings") {
			SettingsView()
				.environment(currentLocation)
		}
		.defaultSize(width: 500, height: 650)
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
				.environment(currentLocation)
				.frame(maxWidth: 500)
		}
		
		Window("About Equinox and Solstices", id: "about-equinox-and-solstice") {
			EquinoxAndSolsticeInfoView()
		}
		.defaultSize(width: 400, height: 650)
		#endif
	}
}
