//
//  LocationSearchService.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

#if !os(watchOS)
@Observable
class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
	static let shared = LocationSearchService()

	enum LocationStatus: Equatable {
		case idle, noResults, isSearching, result
		case error(String)
	}

	var queryFragment = "" {
		didSet {
			handleQueryChange()
		}
	}
	private(set) var status: LocationStatus = .idle
	private(set) var searchResults: [MKLocalSearchCompletion] = []
	var location: TemporaryLocation?

	@ObservationIgnored private var searchTask: Task<Void, Never>?
	@ObservationIgnored private let searchCompleter: MKLocalSearchCompleter

	override init() {
		searchCompleter = MKLocalSearchCompleter()
		super.init()
		searchCompleter.delegate = self
		searchCompleter.region = MKCoordinateRegion(.world)
		searchCompleter.resultTypes = [.address, .pointOfInterest]
		searchCompleter.pointOfInterestFilter = .init(including: [.airport, .nationalPark])
	}

	private func handleQueryChange() {
		searchTask?.cancel()
		status = .isSearching

		guard !queryFragment.isEmpty else {
			status = .idle
			searchResults = []
			return
		}

		searchTask = Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(250))
			guard !Task.isCancelled else { return }
			searchCompleter.queryFragment = queryFragment
		}
	}

	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		searchResults = completer.results.filter { result in
			guard result.title.contains(",") || !result.subtitle.isEmpty else { return false }
			guard !result.subtitle.contains("Nearby") else { return false }
			return true
		}

		status = completer.results.isEmpty ? .noResults : .result
	}

	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		status = .error(error.localizedDescription)
	}
}
#else
@Observable
class LocationSearchService {
	static var shared = LocationSearchService()
	var location: TemporaryLocation?
}
#endif
