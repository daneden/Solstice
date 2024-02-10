//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import StoreKit

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
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
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
		.defaultSize(width: 900, height: 600)
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
		}
		.defaultSize(width: 450, height: 500)
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
				.frame(maxWidth: 500)
		}
		
		Window("About Equinox and Solstices", id: "about-equinox-and-solstice") {
			EquinoxAndSolsticeInfoView()
		}
		.defaultSize(width: 400, height: 650)
		#endif
	}
}
