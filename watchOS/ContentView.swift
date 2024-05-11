//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) var scenePhase
	@Environment(CurrentLocation.self) var currentLocation
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
		}
		.onReceive(timer) { _ in
			timeMachine.referenceDate = Date()
		}
	}
	
}

#Preview {
	ContentView()
		.environmentObject(TimeMachine.preview)
		.environment(CurrentLocation())
}
