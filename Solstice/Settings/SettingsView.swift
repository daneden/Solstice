//
//  SettingsView.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI
#if os(macOS)
	import AppKit
#endif

struct SettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@Environment(CurrentLocation.self) private var currentLocation

	@AppStorage(Preferences.timeTravelAppearance) private var timeTravelAppearance
	@AppStorage(Preferences.chartType) private var chartType

	var body: some View {
		#if os(macOS)
			if ScreenshotLaunch.macScreen == .settingsNotifications {
				// macOS marketing shot: show the Notifications pane directly in the Settings window.
				NavigationStack {
					NotificationSettings()
						.formStyle(.grouped)
				}
				.frame(minWidth: 420, minHeight: 520)
				.accessibilityIdentifier(A11y.settingsWindow)
			} else {
				standardSettings
			}
		#else
			standardSettings
		#endif
	}

	@ViewBuilder private var standardSettings: some View {
		NavigationStack {
			Form {
				Section {
					AboutSolsticeView()
				}

				if !currentLocation.isAuthorized {
					Section {
						Button("Enable location services", systemImage: "location") {
							#if os(macOS)
								// On macOS, open System Settings directly since requestWhenInUseAuthorization
								// doesn't reliably trigger the authorization prompt
								if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_LocationServices") {
									NSWorkspace.shared.open(url)
								}
							#else
								switch currentLocation.authorizationStatus {
								case .notDetermined:
									currentLocation.requestAccess()
								case .restricted, .denied:
									if let url = URL(string: UIApplication.openSettingsURLString) {
										openURL(url)
									}
								default: return
								}
							#endif
						}
					} header: {
						Text("Location")
					} footer: {
						Text("Enable location services to see the daylight duration in your current location")
					}
				}

				Section {
					NavigationLink {
						AppearanceSettingsView()
					} label: {
						Label("Appearance", systemImage: "paintpalette")
					}

					NavigationLink {
						NotificationSettings()
					} label: {
						Label("Notifications", systemImage: "bell.badge")
					}
					.accessibilityIdentifier(A11y.notificationsLink)
				}

				SupporterSettings()

				#if os(iOS)
					Section {
						NavigationLink {
							EquinoxAndSolsticeInfoSheet()
						} label: {
							Label("About solstices and equinoxes", systemImage: "info.circle")
						}
					}
				#endif
			}
			#if os(visionOS)
			.navigationTitle("Settings")
			#endif
			.formStyle(.grouped)
			// Lets the macOS screenshot capture locate the Settings window.
			.accessibilityIdentifier(A11y.settingsWindow)
		}
		#if !os(macOS)
		.toolbar {
			Button {
				dismiss()
			} label: {
				Text("Close")
			}
		}
		#endif
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}
