//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) var scenePhase
	@EnvironmentObject var currentLocation: CurrentLocation
	@EnvironmentObject var timeMachine: TimeMachine
	
	private let timer = Timer.publish(every: 60, on: RunLoop.main, in: .common).autoconnect()
	
	var body: some View {
		NavigationStack {
				switch currentLocation.authorizationStatus {
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
		.navigationTitle(Text(verbatim: "Solstice"))
		.onChange(of: scenePhase) {
			timeMachine.referenceDate = Date()
			if currentLocation.isAuthorized,
				 scenePhase != .background {
				currentLocation.requestLocation()
			}
		}
		.onReceive(timer) { _ in
			timeMachine.referenceDate = Date()
			if currentLocation.isAuthorized {
				currentLocation.requestLocation()
			}
		}
	}
	
}

#Preview {
	ContentView()
		.environmentObject(TimeMachine.preview)
		.environmentObject(CurrentLocation())
}
