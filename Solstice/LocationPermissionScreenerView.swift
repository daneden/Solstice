//
//  LocationPermissionScreenerView.swift
//  Solstice
//
//  Created by Daniel Eden on 28/02/2023.
//

import SwiftUI

struct LocationPermissionScreenerView: View {
	@EnvironmentObject var currentLocation: CurrentLocation
	
	var body: some View {
		Section {
			Button {
				currentLocation.requestAccess()
			} label: {
				Text("Set Up Location Access")
			}
			.buttonStyle(.borderless)
		} header: {
			Label("Location Permission", systemImage: "location")
		} footer: {
			Text("Set up location access to see sunrise and sunset times for your current location in the app, widgets, and notifications")
		}
		.navigationTitle("Solstice")
	}
}

struct LocationPermissionScreenerView_Previews: PreviewProvider {
    static var previews: some View {
			Form {
				LocationPermissionScreenerView()
			}
    }
}
