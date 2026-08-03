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

	#if os(macOS)
		private enum SettingsPane: Hashable {
			case general, appearance, notifications
		}

		@State private var selectedPane: SettingsPane = ScreenshotLaunch.macScreen == .settingsNotifications
			? .notifications
			: .general
	#endif

	var body: some View {
		#if os(macOS)
			tabbedSettings
		#else
			standardSettings
		#endif
	}

	#if os(macOS)
		/// The Settings scene forces a System Settings-style window whose toolbar
		/// renders navigation back buttons below the title, so macOS uses the
		/// HIG-idiomatic pane switcher instead of push navigation.
		private var tabbedSettings: some View {
			TabView(selection: $selectedPane) {
				Tab("About", systemImage: "info.circle", value: .general) {
					Form {
						Section {
							AboutSolsticeView()
						}

						locationSection

						SupporterSettings()
					}
					.formStyle(.grouped)
				}

				Tab("Appearance", systemImage: "paintpalette", value: .appearance) {
					AppearanceSettingsView()
				}

				Tab("Notifications", systemImage: "bell.badge", value: .notifications) {
					NotificationSettings()
				}
			}
			// Lets the macOS screenshot capture locate the Settings window.
			.accessibilityIdentifier(A11y.settingsWindow)
		}
	#endif

	@ViewBuilder private var locationSection: some View {
		if !currentLocation.isAuthorized {
			Section {
				Button("Enable location services", systemImage: "location") {
					switch currentLocation.authorizationStatus {
					case .notDetermined:
						currentLocation.requestAccess()
					case .restricted, .denied:
						#if os(macOS)
							if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_LocationServices") {
								NSWorkspace.shared.open(url)
							}
						#else
							if let url = URL(string: UIApplication.openSettingsURLString) {
								openURL(url)
							}
						#endif
					default: return
					}
				}
			} header: {
				Text("Location")
			} footer: {
				Text("Enable location services to see the daylight duration in your current location")
			}
		}
	}

	@ViewBuilder private var standardSettings: some View {
		NavigationStack {
			Form {
				Section {
					AboutSolsticeView()
				}

				locationSection

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
