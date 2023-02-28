//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var currentLocation: CurrentLocation
	@EnvironmentObject var timeMachine: TimeMachine
	
	var body: some View {
		NavigationStack {
			DetailView(
				navigationSelection: .constant(nil),
				location: currentLocation
			)
		}
			.environmentObject(timeMachine)
			.imageScale(.small)
			.navigationTitle("Solstice")
	}
	
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
