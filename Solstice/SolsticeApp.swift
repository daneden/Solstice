//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import BackgroundTasks
import OSLog

@main
struct SolsticeApp: App {
	@AppStorage("testLastUpdated") var testLastUpdated = "never"
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
			os_log("SDTE: \(Date().formatted(date: .abbreviated, time: .standard)) Running background task with id: \(NotificationManager.backgroundTaskIdentifier)")
			DispatchQueue.main.async {
				testLastUpdated = Date().formatted()
			}
			await NotificationManager.scheduleNotification()
		}
	}
}

func scheduleAppRefresh() {
	let request = BGAppRefreshTaskRequest(identifier: NotificationManager.backgroundTaskIdentifier)
	request.earliestBeginDate = Date().addingTimeInterval(60 * 60)
	try? BGTaskScheduler.shared.submit(request)
}
