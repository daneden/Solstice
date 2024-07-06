//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import StoreKit
import TipKit

@main
struct SolsticeApp: App {
	@Environment(\.scenePhase) var phase
	@StateObject private var currentLocation = CurrentLocation()
	@StateObject private var timeMachine = TimeMachine()
	
	private let persistenceController = PersistenceController.shared

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(currentLocation)
				.environmentObject(timeMachine)
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
							await NotificationManager.scheduleNotifications(currentLocation: currentLocation)
						}
					#endif
					case .active:
						currentLocation.requestLocation()
					default:
						return
					}
				}
				.task {
					if #available(iOS 17, watchOS 10, macOS 13, *) {
						// Configure and load your tips at app launch.
						do {
							try Tips.configure([
								.displayFrequency(.immediate),
								.datastoreLocation(.applicationDefault)
							])
						}
						catch {
							// Handle TipKit errors
							print("Error initializing TipKit \(error.localizedDescription)")
						}
					}
				}
				.migrateAppFeatures()
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
		}
		#if os(macOS)
		.defaultSize(width: 800, height: 600)
		#elseif os(visionOS)
		.defaultSize(width: 1280, height: 720)
		#endif
		
		#if os(visionOS)
		WindowGroup(id: "settings") {
			SettingsView()
		}
		
		WindowGroup(Text("About Equinox and Solstices")) { _ in
			EquinoxAndSolsticeInfoWindow()
		} defaultValue: {
			AnnualSolarEvent.juneSolstice
		}
		.defaultSize(width: 900, height: 612)
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
				.frame(maxWidth: 500)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
				.environmentObject(currentLocation)
		}
		
		Window("About Equinox and Solstices", id: "about-equinox-and-solstice") {
			EquinoxAndSolsticeInfoSheet()
		}
		.defaultSize(width: 400, height: 650)
		#endif
	}
}
