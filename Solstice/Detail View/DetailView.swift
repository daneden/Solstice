//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import CoreData
import Suite
import SwiftUI
import TimeMachine

struct DetailView<Location: ObservableLocation>: View {
	static var userActivity: String {
		Constants.viewLocationActivityType
	}

	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.dismiss) var dismiss
	@Environment(LocationNameResolver.self) private var nameResolver: LocationNameResolver?

	var location: Location
	@Environment(\.timeMachine) var timeMachine: TimeMachine
	#if !os(watchOS)
		@Environment(LocationSearchService.self) var locationSearchService
	#endif
	@State private var showRemainingDaylight = false
	@State private var showShareSheet = false

	@AppStorage(Preferences.detailViewChartAppearance) private var chartAppearance
	@SceneStorage("selectedLocation") private var selectedLocation: String?

	var solar: NTSolar? {
		NTSolar(for: timeMachine.date, coordinate: location.coordinate, timeZone: location.timeZone)
	}

	/// Whether the sun is above the horizon at this location at the displayed (time-machine) date.
	private var sunIsUp: Bool {
		guard let solar else { return false }
		return solar.altitude(at: solar.date) > 0
	}

	var navBarTitleText: Text {
		let resolvedTitle = nameResolver?.displayName(for: location).title ?? location.title
		guard let title = resolvedTitle else {
			return location is CurrentLocation ? Text("Current Location") : Text(verbatim: "Solstice")
		}

		return Text(title)
	}

	var body: some View {
		ScrollViewReader { proxy in
			Form {
				if let solar {
					DailyOverview(solar: solar, location: location)
				}

				AnnualOverview(location: location)
					.id(Self.annualAnchor)
			}
			.formStyle(.grouped)
			#if os(macOS)
				// The macOS toolbar has no Share button to carry the detail-screen identifier
				// (that's iOS-only below), so tag the detail root for screenshot navigation.
				.accessibilityIdentifier(A11y.detailScreen)
				// For the macOS annual marketing shot, open scrolled to the annual chart.
				.task {
					guard ScreenshotLaunch.macScreen == .detailAnnual else { return }
					try? await Task.sleep(for: .milliseconds(500))
					proxy.scrollTo(Self.annualAnchor, anchor: .top)
				}
			#endif
			#if os(watchOS)
			// The default tint-coloured title is low contrast against the daytime sky in the
			// container background; while the sun is up here, use a sun yellow instead.
			.navigationTitle {
				navBarTitleText
					.foregroundStyle(sunIsUp ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.tint))
			}
			#else
			.navigationTitle(navBarTitleText)
			#endif
			.toolbar {
				toolbarItems
			}
			.userActivity(Self.userActivity) { userActivity in
				var navigationSelection: String? = nil

				if let location = location as? SavedLocation {
					navigationSelection = location.uuid?.uuidString
				} else if let location = location as? CurrentLocation {
					navigationSelection = location.id
				}

				userActivity.title = "See daylight for \(location is CurrentLocation ? "current location" : location.title ?? "location")"

				userActivity.targetContentIdentifier = navigationSelection
				userActivity.isEligibleForSearch = true
				userActivity.isEligibleForHandoff = false
			}
			#if os(watchOS)
			.modify {
				if let solar {
					$0.containerBackground(
						SkyGradient(ntSolar: solar),
						for: .navigation
					)
				} else {
					$0
				}
			}
			#endif
			.sheet(isPresented: $showShareSheet) {
				if let solar {
					ShareSolarChartView(solar: solar, location: location, chartAppearance: chartAppearance)
				}
			}
		}
	}

	static var annualAnchor: String {
		"annual-overview"
	}

	var toolbarItemPlacement: ToolbarItemPlacement {
		#if os(macOS)
			return .automatic
		#else
			return .topBarTrailing
		#endif
	}

	@ToolbarContentBuilder
	var toolbarItems: some ToolbarContent {
		#if !os(macOS)
			ToolbarItem(placement: .topBarTrailing) {
				Button("Share...", systemImage: "square.and.arrow.up") {
					showShareSheet.toggle()
				}
				.accessibilityIdentifier(A11y.detailScreen)
			}
		#endif

		if let location = location as? TemporaryLocation {
			ToolbarItem(placement: .confirmationAction) {
				Button {
					dismiss()
					withAnimation {
						if let id = try? location.saveLocation(to: viewContext) {
							selectedLocation = id.uuidString
						}
					}
				} label: {
					Label("Save Location", systemImage: "plus")
						.backportCircleSymbolVariant()
				}
			}
		}

		#if !os(watchOS)
			if locationSearchService.location != nil {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						locationSearchService.location = nil
					} label: {
						Text("Close")
					}
				}
			}
		#endif
	}
}

#Preview {
	NavigationStack {
		DetailView(location: TemporaryLocation.placeholderLondon)
	}
	.withTimeMachine(.solsticeTimeMachine)
	.environment(LocationSearchService())
}
