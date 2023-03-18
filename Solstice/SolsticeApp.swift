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
	
	private let persistenceController = PersistenceController.shared
	
	private let timer = Timer.publish(every: 60, on: RunLoop.main, in: .common).autoconnect()

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
				.onReceive(timer) { _ in
					Task(priority: .utility) {
						TimeMachine.shared.referenceDate = Date()
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
				TimeMachine.shared.referenceDate = Date()
			}
		}
		
		#if os(macOS)
		Settings {
			SettingsView()
		}
		#endif
	}
}
