//
//  DetailView.swift
//  Solstice
//
//  Created by Daniel Eden on 29/09/2022.
//

import CoreData
import CoreLocation
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
	@State private var eclipse: EclipseCalculator.LocalCircumstances?
	@State private var moon: LunarCalculator.Moon?

	@AppStorage(Preferences.bodyMode) private var bodyMode

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
					DailyOverview(solar: solar, location: location, moon: moon)
				}

				if let eclipse {
					EclipseOverview(circumstances: eclipse, location: location)
				}

				AnnualOverview(location: location)
					.id(Self.annualAnchor)
			}
			.formStyle(.grouped)
			.task(id: eclipseSearchKey) {
				await findEclipse()
			}
			.task(id: moonSearchKey) {
				await findMoon()
			}
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

	/// Keyed on the place and the *day*, not the instant. Searching for eclipses is far
	/// heavier than building an `NTSolar`, so it can't live in a computed property that
	/// re-evaluates on every body pass — and keying on the day means dragging the
	/// time-travel slider doesn't restart the search on every frame.
	private var eclipseSearchKey: String {
		"\(location.latitude),\(location.longitude),\(timeMachine.date.startOfDay.timeIntervalSince1970)"
	}

	/// Keyed the same way the eclipse search is, and for the same reason: working out
	/// moonrise samples the moon's position well over a hundred times, which has no place
	/// in a computed property that re-evaluates on every body pass.
	private var moonSearchKey: String {
		"\(location.latitude),\(location.longitude),\(timeMachine.date.startOfDay.timeIntervalSince1970)"
	}

	/// Computed regardless of the current mode, deliberately. It costs a few hundred
	/// microseconds off the main thread once per day and place, and doing it eagerly means
	/// switching to the moon shows data immediately rather than after a round trip.
	private func findMoon() async {
		let latitude = location.latitude
		let longitude = location.longitude
		let date = timeMachine.date
		let timeZone = location.timeZone

		let result = await Task.detached(priority: .utility) {
			LunarCalculator.moon(
				for: date,
				coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
				timeZone: timeZone
			)
		}.value

		withAnimation {
			moon = result
		}
	}

	private func findEclipse() async {
		let latitude = location.latitude
		let longitude = location.longitude
		let date = timeMachine.date

		let result = await Task.detached(priority: .utility) {
			EclipseCalculator.nextEclipse(
				at: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
				after: date,
				within: Constants.Eclipse.detailWindow,
				minimumObscuration: Constants.Eclipse.detailThreshold
			)
		}.value

		// Animating at the mutation site rather than with `.animation(_:value:)` on the
		// form, which would also animate everything else in it. Covers all three
		// transitions: the section arriving once the first search finishes, leaving when
		// the eclipse is time-travelled past, and swapping one eclipse for another.
		withAnimation {
			eclipse = result
		}
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
		ToolbarItem(placement: toolbarItemPlacement) {
			#if os(watchOS)
				// A menu is clumsy on the watch, so cycle instead. The label carries the
				// current state, which is what makes cycling legible here.
				Button {
					withAnimation {
						bodyMode = bodyMode.next
					}
				} label: {
					Label(bodyMode.title, systemImage: bodyMode.icon)
				}
			#else
				Menu {
					Picker(selection: $bodyMode.animation()) {
						ForEach(CelestialBodyMode.allCases) { mode in
							Label(mode.title, systemImage: mode.icon)
								.tag(mode)
						}
					} label: {
						Text("Show")
					}
					.pickerStyle(.inline)
				} label: {
					Label(bodyMode.title, systemImage: bodyMode.icon)
						.contentTransition(.symbolEffect)
				}
			#endif
		}

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
