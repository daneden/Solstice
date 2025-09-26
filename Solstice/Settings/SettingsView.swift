//
//  SettingsView.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@EnvironmentObject private var currentLocation: CurrentLocation
	
	@AppStorage(Preferences.timeTravelAppearance) private var timeTravelAppearance
	
    var body: some View {
			NavigationStack {
				Form {
					Section {
						AboutSolsticeView()
					}
					
					if !currentLocation.isAuthorized {
						Section {
							Button("Enable location services", systemImage: "location") {
								switch currentLocation.authorizationStatus {
								case .notDetermined:
									currentLocation.requestAccess()
								case .restricted, .denied:
									#if !os(macOS)
									if let url = URL(string: UIApplication.openSettingsURLString) {
										openURL(url)
									}
									#else
									return
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
					
					Section("Time Travel") {
						HStack {
							HStack {
								ForEach(TimeTravelAppearance.allCases) { appearance in
									let isActive = timeTravelAppearance == appearance
									Button {
										timeTravelAppearance = appearance
									} label: {
										VStack(spacing: 8) {
											Image(appearance.image)
												.resizable()
												.aspectRatio(contentMode: .fit)
												.frame(maxHeight: 80)
												.foregroundStyle(.tint)
												.tint(isActive ? .accent : .secondary)
											Text(appearance.title)
											
											Image(systemName: isActive ? "checkmark.circle" : "circle")
												.symbolVariant(isActive ? .fill : .none)
												.foregroundStyle(.tint)
												.tint(isActive ? .accent : .secondary)
												.imageScale(.large)
										}
										.frame(maxWidth: .infinity)
										.contentShape(.rect)
									}
									.buttonStyle(.plain)
								}
							}
						}
					}
					
					NotificationSettings()
					
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
