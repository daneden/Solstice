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
	@AppStorage(Preferences.listViewAppearance) private var listAppearance
	@AppStorage(Preferences.chartType) private var chartType
	
    var body: some View {
			Form {
				Section("Time Travel") {
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
				
				#if os(iOS)
				Section("List appearance") {
					Picker(selection: $listAppearance.animation()) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Text(appearance.description)
						}
					} label: {
						Text("List row style")
					}
					.pickerStyle(.segmented)
				}
				#endif
				
				Section("Chart appearance") {
					HStack {
						ForEach(ChartType.allCases) { chartType in
							let isActive = self.chartType == chartType
							Button {
								self.chartType = chartType
							} label: {
								VStack(spacing: 8) {
									Image(chartType.icon)
										.font(.largeTitle)
										.fontWeight(.light)
										.symbolRenderingMode(.hierarchical)
										.foregroundStyle(.tint)
										.tint(isActive ? .accent : .secondary)
									
									Text(chartType.title)
									
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
					
					Picker("Chart theme", selection: $chartAppearance) {
						ForEach(DaylightChart.Appearance.allCases, id: \.self) { appearance in
							Text(appearance.description)
						}
					}
					.pickerStyle(.segmented)
				}
			}
			.navigationTitle("Appearance")
			.formStyle(.grouped)
    }
}

#Preview {
    AppearanceSettingsView()
}
