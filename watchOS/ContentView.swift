//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var currentLocation: CurrentLocation
	@ObservedObject var timeMachine =  TimeMachine.shared
	@StateObject var navigationState = NavigationStateManager()
	
	var body: some View {
		NavigationStack {
				switch CurrentLocation.authorizationStatus {
				case .notDetermined:
					LocationPermissionScreenerView()
				case .authorizedAlways, .authorizedWhenInUse:
					DetailView(location: currentLocation)
				case .denied, .restricted:
					Text("Solstice on Apple Watch requires location access in order to show local sunrise and sunset times. For custom and saved locations, use Solstice on iPhone, iPad, or Mac.")
				@unknown default:
					fatalError()
				}
		}
			.environmentObject(navigationState)
			.navigationTitle("Solstice")
	}
	
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
