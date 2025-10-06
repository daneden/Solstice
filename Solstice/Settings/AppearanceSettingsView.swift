//
//  AppearanceSettingsView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/10/2025.
//

import SwiftUI

struct AppearanceSettingsView: View {
	@AppStorage(Preferences.timeTravelAppearance) private var timeTravelAppearance
	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@AppStorage(Preferences.chartType) private var chartType
	
    var body: some View {
			Form {
				Section("Time Travel") {
					HStack {
						HStack {
							ForEach(TimeTravelAppearance.allCases) { appearance in
								let isActive = timeTravelAppearance == appearance
								Button {
									timeTravelAppearance = appearance
								} label: {
									VStack(spacing: 8) {
										Image(appearance.image)
											.resizable()
											.aspectRatio(contentMode: .fit)
											.frame(maxHeight: 80)
											.foregroundStyle(.tint)
											.tint(isActive ? .accent : .secondary)
										Text(appearance.title)
										
										Image(systemName: isActive ? "checkmark.circle" : "circle")
											.symbolVariant(isActive ? .fill : .none)
											.foregroundStyle(.tint)
											.tint(isActive ? .accent : .secondary)
											.imageScale(.large)
									}
									.frame(maxWidth: .infinity)
									.contentShape(.rect)
								}
								.buttonStyle(.plain)
							}
						}
					}
				}
				
				Section("Chart appearance") {
					Picker("Chart type", selection: $chartType) {
						ForEach(ChartType.allCases) { type in
							Text(type.title)
						}
					}
					.pickerStyle(.segmented)
					
					Picker("Chart theme", selection: $chartAppearance) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Text(appearance.description)
						}
					}
					.pickerStyle(.inline)
				}
			}
			.navigationTitle("Appearance")
    }
}

#Preview {
    AppearanceSettingsView()
}
