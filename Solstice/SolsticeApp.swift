//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import UserNotifications
import StoreKit

@main
struct SolsticeApp: App {
	@Environment(\.scenePhase) var phase
	@StateObject private var currentLocation = CurrentLocation()
	
	@State private var currentDate = Date()
	
	let persistenceController = PersistenceController.shared

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(currentLocation)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
				.task {
					for await result in Transaction.updates {
						switch result {
						case .verified(let transaction):
							print("Transaction verified in listener")
							
							await transaction.finish()
							
							// Update the user's purchases...
						case .unverified:
							print("Transaction unverified")
						}
					}
				}
		}
		.onChange(of: phase) { newValue in
			switch newValue {
			#if !os(watchOS)
			case .background:
				Task { await NotificationManager.scheduleNotifications(locationManager: currentLocation) }
			#endif
			default:
				currentLocation.requestLocation() { _ in }
			}
		}
		
		#if os(macOS)
		Settings {
			SettingsView()
		}
		#endif
	}
}
