//
//  AppearanceSettings.swift
//  Solstice
//
//  Created by Daniel Eden on 26/02/2023.
//

import SwiftUI

struct AppearanceSettings: View {
	@AppStorage(Preferences.appColorScheme) var appColorScheme
    var body: some View {
			Form {
				Picker(selection: $appColorScheme) {
					ForEach(Preferences.SolsticeColorScheme.allCases, id: \.self) { colorScheme in
						Text(colorScheme.rawValue)
					}
				} label: {
					Label("Color Scheme", systemImage: "circle.lefthalf.filled")
				}
			}
    }
}

struct AppearanceSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettings()
    }
}
