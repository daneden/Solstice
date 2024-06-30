//
//  EquinoxAndSolsticeInfoWindow.swift
//  Solstice
//
//  Created by Daniel Eden on 29/06/2024.
//

import SwiftUI

struct EquinoxAndSolsticeInfoWindow: View {
    var body: some View {
			HStack {
				ScrollView {
					VStack(alignment: .leading, spacing: 20) {
						Text("About Equinox and Solstices")
							.font(.largeTitle.weight(.semibold))
						EquinoxAndSolsticeDescriptions()
					}
					.padding()
				}
				
				EarthRealityView()	
			}
			.scenePadding()
    }
}

#Preview {
    EquinoxAndSolsticeInfoWindow()
}
