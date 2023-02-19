//
//  LocationSearchService.swift
//  Solstice
//
//  Created by Daniel Eden on 02/10/2022.
//

import Foundation
import Combine
import SwiftUI
import MapKit
import CoreLocation

struct Location: Identifiable, Hashable {
	static func == (lhs: Location, rhs: Location) -> Bool {
		lhs.hashValue == rhs.hashValue
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(name)
		hasher.combine(coordinates?.longitude ?? 0)
		hasher.combine(coordinates?.latitude ?? 0)
	}
	
	var id = UUID()
	var name: String
	@State var coordinates: CLLocationCoordinate2D?
	
	init(name: String) {
		self.name = name
		
		findCoordinates()
	}
	
	mutating func findCoordinates() {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(name) { [self] (response, error) in
			if let response = response, !response.isEmpty {
				self.coordinates = response[0].location?.coordinate
			}
		}
	}
}

class LocationSearchService: NSObject, ObservableObject {
	static let shared = LocationSearchService()
	
	enum LocationStatus: Equatable {
		case idle, noResults, isSearching, result
		case error(String)
	}
		
	@Published var queryFragment = ""
	@Published private(set) var status: LocationStatus = .idle
	@Published private(set) var searchResults: [MKLocalSearchCompletion] = []
	
	private var queryCancellable: AnyCancellable?
	private let searchCompleter: MKLocalSearchCompleter!
	
	init(searchCompleter: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
		self.searchCompleter = searchCompleter
		super.init()
		self.searchCompleter.delegate = self
		self.searchCompleter.resultTypes = [.address, .pointOfInterest]
		self.searchCompleter.pointOfInterestFilter = .init(including: [.airport, .nationalPark])
		
		queryCancellable = $queryFragment
			.receive(on: DispatchQueue.main)
			.debounce(for: .milliseconds(250), scheduler: RunLoop.main, options: nil)
			.sink(receiveValue: { fragment in
				self.status = .isSearching
				if !fragment.isEmpty {
					self.searchCompleter.queryFragment = fragment
				} else {
					self.status = .idle
					self.searchResults = []
				}
			})
	}
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.searchResults = completer.results
		self.status = completer.results.isEmpty ? .noResults : .result
	}
	
	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		self.status = .error(error.localizedDescription)
	}
}
