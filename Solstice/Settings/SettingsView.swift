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
						} footer: {
							Text("Enable location services to see the daylight duration in your current location")
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
