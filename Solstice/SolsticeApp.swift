//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import SwiftUI
import StoreKit
import TipKit
import TimeMachine

@main
struct SolsticeApp: App {
	@Environment(\.scenePhase) var phase
	@State private var currentLocation = CurrentLocation()
	@State private var locationSearchService = LocationSearchService()

	private let persistenceController = PersistenceController.shared

	var body: some Scene {
		WindowGroup {
			ContentView()
				.withAppOnboarding()
				.withTimeMachine(.solsticeTimeMachine)
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
						await NotificationManager.scheduleNotifications(location: currentLocation.location)
					#endif
					case .active:
						currentLocation.requestLocation()
					default:
						return
					}
				}
				.migrateAppFeatures()
				.environment(currentLocation)
				.environment(locationSearchService)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
		}
		#if os(iOS)
		.backgroundTask(.appRefresh(NotificationManager.backgroundTaskIdentifier)) {
			await NotificationManager.scheduleNotifications()
		}
		#endif
		#if os(macOS)
		.defaultSize(width: 800, height: 600)
		#elseif os(visionOS)
		.defaultSize(width: 900, height: 720)
		#endif
		
		#if os(visionOS)
		WindowGroup(id: "settings") {
			SettingsView()
				.environment(currentLocation)
		}
		.defaultSize(width: 600, height: 600)
		
		WindowGroup(Text("About solstices and equinoxes")) { _ in
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
				.environment(currentLocation)
		}
		
		Window("About solstices and equinoxes", id: "about-equinox-and-solstice") {
			EquinoxAndSolsticeInfoSheet()
		}
		.defaultSize(width: 400, height: 650)
		#endif
	}
}
