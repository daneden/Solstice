//
//  ContentView.swift
//  Solstice for watchOS Watch App
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct ContentView: View {
	@StateObject var currentLocation = CurrentLocation()
	@StateObject var timeMachine = TimeMachine()
	
	var body: some View {
		NavigationStack {
			DetailView(location: currentLocation)
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
