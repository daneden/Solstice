//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI

@main
struct SolsticeApp: App {
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
	}
}
