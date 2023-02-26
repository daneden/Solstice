//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import UserNotifications
import StoreKit

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

@main
struct SolsticeApp: App {	
	@Environment(\.scenePhase) var phase
	@StateObject var timeMachine = TimeMachine()
	let persistenceController = PersistenceController.shared

	var body: some Scene {
		WindowGroup {
			TimelineView(.everyMinute) { timeline in
				ContentView()
					.environmentObject(timeMachine)
					.environment(\.managedObjectContext, persistenceController.container.viewContext)
					.onChange(of: timeline.date) { newValue in
						timeMachine.referenceDate = newValue
					}
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
		}
		#if !os(watchOS)
		.onChange(of: phase) { newValue in
			switch newValue {
			case .background:
				Task { await NotificationManager.scheduleNotifications() }
			default:
				break
			}
		}
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
		}
		#endif
	}
}
