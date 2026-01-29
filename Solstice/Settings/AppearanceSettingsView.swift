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
				timeTravelSection
				#if os(iOS)
				listAppearanceSection
				#endif
				chartAppearanceSection
			}
			.navigationTitle("Appearance")
			.formStyle(.grouped)
    }

	private var timeTravelSection: some View {
		Section("Time Travel") {
			HStack {
				ForEach(TimeTravelAppearance.allCases) { appearance in
					timeTravelButton(for: appearance)
				}
			}
		}
	}

	private func timeTravelButton(for appearance: TimeTravelAppearance) -> some View {
		let isActive: Bool = timeTravelAppearance == appearance
		return Button {
			timeTravelAppearance = appearance
		} label: {
			timeTravelButtonLabel(appearance: appearance, isActive: isActive)
		}
		.buttonStyle(.plain)
	}

	private func timeTravelButtonLabel(appearance: TimeTravelAppearance, isActive: Bool) -> some View {
		VStack(spacing: 8) {
			Image(appearance.image)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(maxHeight: 80)
				.foregroundStyle(.tint)
				.tint(isActive ? .accent : .secondary)
			Text(appearance.title)

			selectionIndicator(isActive: isActive)
		}
		.frame(maxWidth: .infinity)
		.contentShape(.rect)
	}

	#if os(iOS)
	private var listAppearanceSection: some View {
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
	}
	#endif

	private var chartAppearanceSection: some View {
		Section("Chart appearance") {
			HStack {
				ForEach(ChartType.allCases) { type in
					chartTypeButton(for: type)
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

	private func chartTypeButton(for type: ChartType) -> some View {
		let isActive: Bool = self.chartType == type
		return Button {
			self.chartType = type
		} label: {
			chartTypeButtonLabel(chartType: type, isActive: isActive)
		}
		.buttonStyle(.plain)
	}

	private func chartTypeButtonLabel(chartType: ChartType, isActive: Bool) -> some View {
		VStack(spacing: 8) {
			Image(chartType.icon)
				.font(.largeTitle)
				.fontWeight(.light)
				.symbolRenderingMode(.hierarchical)
				.foregroundStyle(.tint)
				.tint(isActive ? .accent : .secondary)

			Text(chartType.title)

			selectionIndicator(isActive: isActive)
		}
		.frame(maxWidth: .infinity)
		.contentShape(.rect)
	}

	private func selectionIndicator(isActive: Bool) -> some View {
		Image(systemName: isActive ? "checkmark.circle" : "circle")
			.symbolVariant(isActive ? .fill : .none)
			.foregroundStyle(.tint)
			.tint(isActive ? .accent : .secondary)
			.imageScale(.large)
	}
}

#Preview {
    AppearanceSettingsView()
}
