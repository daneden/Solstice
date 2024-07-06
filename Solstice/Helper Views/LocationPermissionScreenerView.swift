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
		AdaptiveLabeledContent {
			Button {
				currentLocation.requestAccess()
			} label: {
				Text("Set up")
			}
			.buttonStyle(.bordered)
			
		} label: {
			HStack {
				Image(systemName: "location")
					.imageScale(.small)
					.foregroundStyle(.secondary)
					.symbolVariant(.fill)
				
				Text("Current location")
			}
		}
		.padding(.vertical, 6)
	}
}

struct LocationPermissionScreenerView_Previews: PreviewProvider {
    static var previews: some View {
			Form {
				LocationPermissionScreenerView()
			}
    }
}
