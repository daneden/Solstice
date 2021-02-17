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
  @ObservedObject var locationService = LocationService.shared
  @State var currentCompletion: MKLocalSearchCompletion?
  
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
          
          Button(action: { useCurrentLocation() }) {
            Label("Use Current Location", systemImage: "location.fill")
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
                .onTapGesture { buildMKMapItem(from: completionResult) }
              }
            }
          }
        }
      }.navigationTitle(Text("Choose Location"))
    }
  }
  
  func buildMKMapItem(from completion: MKLocalSearchCompletion) {
    currentCompletion = completion
    
    searchRequest.naturalLanguageQuery = "\(completion.title), \(completion.subtitle)"
    MKLocalSearch(request: searchRequest).start { (response, error) in
      if let error = error {
        print(error.localizedDescription)
      }
      
      if let response = response,
         !response.mapItems.isEmpty {
        let item = response.mapItems[0]
        let coords = item.placemark.coordinate
        let location = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
        LocationManager.shared.location = location
        self.presentationMode.wrappedValue.dismiss()
      }
      
      currentCompletion = nil
    }
  }
  
  func useCurrentLocation() {
    locationService.queryFragment = ""
    LocationManager.shared.resetLocation()
    self.presentationMode.wrappedValue.dismiss()
  }
}

struct LocationPickerView_Previews: PreviewProvider {
  static var previews: some View {
    LocationPickerView()
  }
}
