//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import BackgroundTasks
import UserNotifications
import OSLog

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
					.symbolRenderingMode(.hierarchical)
					.symbolVariant(.fill)
					.onChange(of: timeline.date) { newValue in
						timeMachine.referenceDate = newValue
					}
			}
		}
		.onChange(of: phase) { newPhase in
			switch newPhase {
			case .background: scheduleAppRefresh()
			default: break
			}
		}
		.backgroundTask(.appRefresh(NotificationManager.backgroundTaskIdentifier)) {
			scheduleAppRefresh()
			await withTaskCancellationHandler {
				let notif = UNMutableNotificationContent()
				notif.title = "Hello world"
				notif.subtitle = "This is a test"
				
				let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(5))
				let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
				let request = UNNotificationRequest(identifier: UUID().uuidString, content: notif, trigger: trigger)
				
				do {
					try await UNUserNotificationCenter.current().add(request)
					os_log("SDTE: Sent notification")
				} catch {
					os_log("SDTE: \(error.localizedDescription)")
				}
				
				// await NotificationManager.scheduleNotification()
			} onCancel: {
				os_log("SDTE: bg task timed out")
			}
		}
	}
}

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
