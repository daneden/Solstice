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
		#if os(iOS)
		.onChange(of: phase) { newPhase in
			switch newPhase {
			case .background: scheduleAppRefresh()
			default: break
			}
		}
		.backgroundTask(.appRefresh(NotificationManager.backgroundTaskIdentifier)) {
			scheduleAppRefresh()
			
			let notif = UNMutableNotificationContent()
			notif.title = "Hello world"
			notif.body = "This is a test notification sent at \(Date().formatted())"
			
			let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(5))
			let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
			let request = UNNotificationRequest(identifier: UUID().uuidString, content: notif, trigger: trigger)
			
			do {
				try await UNUserNotificationCenter.current().add(request)
			} catch {
				print(error)
			}
			
			// await NotificationManager.scheduleNotification()
		}
		#endif
		
		#if os(macOS)
		Settings {
			SettingsView()
		}
		#endif
	}
}

#if os(iOS)
func scheduleAppRefresh() {
	let noonComponent = DateComponents(hour: 12)
	let nextNoon = Calendar.autoupdatingCurrent.nextDate(after: Date(), matching: noonComponent, matchingPolicy: .nextTime)
	
	let request = BGAppRefreshTaskRequest(identifier: NotificationManager.backgroundTaskIdentifier)
	request.earliestBeginDate = nextNoon ?? .now
	
	do {
		try BGTaskScheduler.shared.submit(request)
	} catch {
		print(error)
	}
}
#endif
