//
//  SolsticeApp.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import StoreKit
import SwiftUI
import TimeMachine
import TipKit

@main
struct SolsticeApp: App {
	@State private var currentLocation = CurrentLocation()
	@State private var locationSearchService = LocationSearchService()
	@State private var nameResolver = LocationNameResolver()

	private let persistenceController = ScreenshotLaunch.isCapturing
		? PersistenceController.screenshots
		: PersistenceController.shared

	init() {
		ScreenshotLaunch.prepareForCaptureIfNeeded()
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
				.withAppOnboarding()
				.withSolsticeTimeMachine()
				.task {
					for await result in Transaction.updates {
						switch result {
						case let .verified(transaction):
							print("Transaction verified in listener")
							await transaction.finish()
						case .unverified:
							print("Transaction unverified")
						}
					}
				}
				.migrateAppFeatures()
				.environment(currentLocation)
				.environment(nameResolver)
				.environment(locationSearchService)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
				// Forced appearance for dark-mode marketing shots; nil (any normal
				// launch) leaves the system appearance in charge.
				.preferredColorScheme(ScreenshotLaunch.forcedColorScheme)
			#if os(macOS)
				// Deterministic, compact window size for marketing captures; nil leaves
				// normal launches free to size/resize as usual.
				.frame(
					width: ScreenshotLaunch.isCapturing ? 800 : nil,
					height: ScreenshotLaunch.isCapturing ? 600 : nil
				)
			#endif
		}
		#if os(iOS)
		.backgroundTask(.appRefresh(NotificationManager.backgroundTaskIdentifier)) {
			await NotificationManager.scheduleNotifications()
		}
		#endif
		#if !os(watchOS)
		.windowResizability(.contentSize)
		#endif
		#if os(macOS)
		// Passing -AppleLanguages to force the capture locale makes AppKit relaunch the
		// app, and that relaunch restores the prior (zero-window) state instead of
		// presenting the main window. Disable restoration and force presentation while
		// capturing so the window always appears; normal launches keep system behavior.
		.restorationBehavior(ScreenshotLaunch.isCapturing ? .disabled : .automatic)
		.defaultLaunchBehavior(ScreenshotLaunch.isCapturing ? .presented : .automatic)
		#endif
		#if os(visionOS)
		.defaultSize(width: 900, height: 720)
		#endif

		#if os(visionOS)
			WindowGroup(id: "settings") {
				SettingsView()
					.environment(currentLocation)
					.environment(nameResolver)
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
					.environment(nameResolver)
			}

			Window("About solstices and equinoxes", id: "about-equinox-and-solstice") {
				EquinoxAndSolsticeInfoSheet()
			}
			.defaultSize(width: 400, height: 650)

			#if DEBUG
				// Screenshot-only window: the SwiftUI `Settings` scene can't be opened
				// programmatically, so the macOS capture opens this stand-in (Notifications
				// pane in a Settings-sized window) via openWindow(id:). DEBUG-only, so it
				// never ships and doesn't clutter the real app's menus.
				Window("Settings", id: "capture-settings") {
					NavigationStack {
						NotificationSettings()
							.formStyle(.grouped)
					}
					.frame(width: 420, height: 520)
					.environment(\.managedObjectContext, persistenceController.container.viewContext)
					.environment(currentLocation)
					.environment(nameResolver)
				}
				.defaultSize(width: 420, height: 520)
				.windowResizability(.contentSize)
			#endif
		#endif
	}
}
