//
//  LocationService.swift
//  Solstice
//
//  Created by Daniel Eden on 30/01/2021.
//

import Foundation
import Combine
import SwiftUI
import MapKit
import CoreLocation

class LocationService: NSObject, ObservableObject {
  static let shared = LocationService()
  
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
    self.searchCompleter.resultTypes = [.address]
    
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

extension LocationService: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    self.searchResults = completer.results
    self.status = completer.results.isEmpty ? .noResults : .result
  }
  
  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    self.status = .error(error.localizedDescription)
  }
}
