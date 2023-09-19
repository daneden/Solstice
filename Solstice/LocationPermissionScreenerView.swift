//
//  LocationPermissionScreenerView.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import SwiftUI

struct LocationPermissionScreenerView: View {
	@Environment(\.openURL) var openURL
	@EnvironmentObject var currentLocation: CurrentLocation
	
	var body: some View {
		Section {
			Button {
				currentLocation.requestAccess()
				#if os(macOS)
				openURL.callAsFunction(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
				#endif
			} label: {
				Text("Set Up Location Services")
			}
			#if os(iOS)
			.buttonStyle(.borderless)
			#elseif os(macOS)
			.buttonStyle(.bordered)
			#endif
		} header: {
			Label("Location Services", systemImage: "location")
		} footer: {
			Text("Set up location services to see sunrise and sunset times for your current location in the app, widgets, and notifications")
		}
		.navigationTitle(Text(verbatim: "Solstice"))
	}
}

struct LocationPermissionScreenerView_Previews: PreviewProvider {
    static var previews: some View {
			Form {
				LocationPermissionScreenerView()
			}
    }
}
