//
//  SwiftUIView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/06/2024.
//

import SwiftUI

struct EquinoxAndSolsticeDescriptions: View {
    var body: some View {
			Text("The equinox and solstice define the transitions between the seasons of the astronomical calendar and are a key part of the Earth’s orbit around the Sun.")
			
			VStack(alignment: .leading) {
				Text("Equinox")
					.font(.headline)
				Text("The equinox occurs twice a year, in March and September, and mark the points when the Sun crosses the equator’s path. During the equinox, day and night are around the same length all across the globe.")
			}
			
			VStack(alignment: .leading) {
				Text("Solstice")
					.font(.headline)
				Text("The solstice occurs twice a year, in June and December (otherwise known as the summer and winter solstices), and mark the sun’s northernmost and southernmost excursions. During the June solstice, the Earth’s northern hemisphere is pointed towards the sun, resulting in increased sunlight and warmer temperatures; the same is true for the southern hemisphere during the December solstice.")
			}
    }
}

#Preview {
    EquinoxAndSolsticeDescriptions()
}
