//
//  LocationPickerView.swift
//  Solstice
//
//  Created by Daniel Eden on 23/01/2021.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var locationManager: LocationManager
  @EnvironmentObject var locationService: LocationService
  @State var currentCompletion: MKLocalSearchCompletion?
  
  var onSelection: (Location?) -> Void = { _ in }
  
  private let searchRequest = MKLocalSearch.Request()
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Search for a location")) {
          ZStack(alignment: .trailing) {
            TextField("Search", text: $locationService.queryFragment)
            
            if locationService.status == .isSearching {
              ProgressView()
            } else if !locationService.queryFragment.isEmpty {
              Button(action: { locationService.queryFragment = "" }) {
                Label("Clear search", systemImage: "xmark.circle.fill")
                  .labelStyle(IconOnlyLabelStyle())
                  .foregroundColor(.secondary)
              }
            }
          }
        }
        
        if !locationService.searchResults.isEmpty {
          Section(header: Text("Results")) {
            List {
              Group { () -> AnyView in
                switch locationService.status {
                case .noResults: return AnyView(Text("No results"))
                case .error(let description): return AnyView(Text("Error: \(description)"))
                default: return AnyView(EmptyView())
                }
              }.foregroundColor(.secondary)
              
              ForEach(locationService.searchResults, id: \.self) { completionResult in
                HStack {
                  VStack(alignment: .leading) {
                    Text(completionResult.title)
                    if !completionResult.subtitle.isEmpty {
                      Text(completionResult.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                  }.opacity(completionResult == currentCompletion ? 0.75 : 1)
                  
                  
                  Spacer()
                  
                  if completionResult == currentCompletion {
                    ProgressView()
                  }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                  buildMKMapItem(from: completionResult) { location in
                    self.presentationMode.wrappedValue.dismiss()
                    onSelection(location)
                  }
                  locationService.queryFragment = completionResult.title
                }
              }
            }
          }
        }
      }.navigationTitle(Text("Choose Location"))
    }
  }
  
  func buildMKMapItem(
    from searchCompletion: MKLocalSearchCompletion,
    with completion: @escaping (Location?) -> Void = { _ in }
  ) {
    currentCompletion = searchCompletion
    
    searchRequest.naturalLanguageQuery = "\(searchCompletion.title), \(searchCompletion.subtitle)"
    MKLocalSearch(request: searchRequest).start { (response, error) in
      if let error = error {
        print(error.localizedDescription)
      }
      
      if let response = response,
         !response.mapItems.isEmpty {
        let item = response.mapItems[0]
        let coords = item.placemark.coordinate
        let clLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
        locationManager.location = clLocation
        
        let location = Location(
          name: item.placemark.name!,
          region: searchCompletion.subtitle,
          latitude: coords.latitude,
          longitude: coords.longitude
        )
        
        completion(location)
      } else {
        completion(nil)
      }
      
      currentCompletion = nil
    }
  }
}

struct LocationPickerView_Previews: PreviewProvider {
  static var previews: some View {
    LocationPickerView()
      .environmentObject(LocationManager())
      .environmentObject(LocationService())
  }
}
