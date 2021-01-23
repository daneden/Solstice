//
//  LocationPickerView.swift
//  Solstice
//
//  Created by Daniel Eden on 23/01/2021.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
  private let locationManager = LocationManager.shared
  @Environment(\.presentationMode) var presentationMode
  @State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude),
    span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
  )
  @State private var trackingMode = MapUserTrackingMode.none
  @State private var showsUserLocation = false
  
  var body: some View {
    NavigationView {
      Map(
        coordinateRegion: $region,
        showsUserLocation: showsUserLocation,
        userTrackingMode: $trackingMode,
        annotationItems: [region.center]
      ) { item in
        MapPin(coordinate: item)
      }
      .navigationTitle(Text("Choose Location"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem {
          Button(action: { self.updateLocationAndDismiss() }) {
            Text("Done")
          }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { self.useCurrentLocation() }) {
            Label("Current Location", systemImage: "location.fill")
          }
        }
      }
    }
  }
  
  func useCurrentLocation() {
    if let location = locationManager.location {
      region.center = location.coordinate
      trackingMode = .follow
      showsUserLocation = true
      locationManager.manuallyAdjusted = false
    }
  }
  
  func updateLocationAndDismiss() {
    if region.center != locationManager.location?.coordinate {
      locationManager.manuallyAdjusted = true
    }
    locationManager.location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
    locationManager.latitude = region.center.latitude
    locationManager.longitude = region.center.longitude
    
    self.presentationMode.wrappedValue.dismiss()
  }
}

extension CLLocationCoordinate2D: Equatable, Identifiable {
  public var id: UUID {
    UUID()
  }
  
  static public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}

extension MKCoordinateRegion: Equatable {
  static public func ==(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
    return lhs.center == rhs.center
  }
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPickerView()
    }
}
