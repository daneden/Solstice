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
  
  private let searchRequest = MKLocalSearch.Request()
  
  @State private var showLocationWarning = false
  
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
                .onTapGesture {
                  buildMKMapItem(from: completionResult)
                  locationService.queryFragment = completionResult.title
                }
              }
            }
          }
        }
      }.navigationTitle(Text("Choose Location"))
        .toolbar {
          Button("Close") { self.presentationMode.wrappedValue.dismiss() }
        }
        .alert("Location Permission Needed",
               isPresented: $showLocationWarning,
               actions: {
          Button("Open Settings") {
            let url = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(url, options: [:])
          }
          
          Button("Cancel") {
            showLocationWarning = false
          }
        }, message: {
          Text("Open Settings and allow Solstice to access your location to enable this feature.")
        })
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
        locationManager.manuallySetLocation(to: location)
        self.presentationMode.wrappedValue.dismiss()
      }
      
      currentCompletion = nil
    }
  }
  
  func useCurrentLocation() {
    if locationManager.locationAvailable {
      locationService.queryFragment = ""
      locationManager.resetLocation()
      self.presentationMode.wrappedValue.dismiss()
    } else if case .real(let status) = locationManager.locationType,
              status == .notDetermined {
      locationManager.requestAuthorization()
      self.presentationMode.wrappedValue.dismiss()
    } else {
      showLocationWarning = true
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
