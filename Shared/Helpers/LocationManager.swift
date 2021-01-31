//
//  LocationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI
import WidgetKit

class LocationManager: NSObject, ObservableObject {
  @AppStorage(UDValues.cachedLatitude) var latitude {
    didSet { self.geocode() }
  }
  
  @AppStorage(UDValues.cachedLongitude) var longitude {
    didSet { self.geocode() }
  }
  
  let objectWillChange = PassthroughSubject<Void, Never>()
  static let shared = LocationManager()
  
  private let locationManager = CLLocationManager()
  private let geocoder = CLGeocoder()
  
  @Published var status: CLAuthorizationStatus?
  
  @Published var location: CLLocation? {
    // Update stored location for cached/spoofed location access
    didSet {
      if let latitude = location?.latitude, let longitude = location?.longitude {
        self.latitude = latitude
        self.longitude = longitude
      }
      self.geocode()
      
      WidgetCenter.shared.reloadAllTimelines()
      objectWillChange.send()
    }
  }
  
  @Published var placemark: CLPlacemark?
  
  override init() {
    super.init()
    
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    self.status = self.locationManager.authorizationStatus
    self.location = CLLocation(latitude: latitude, longitude: longitude)
    
    if self.status == .authorizedAlways || self.status == .authorizedWhenInUse {
      self.start()
    }
  }
  
  func requestAuthorization(completionBlock: @escaping () -> Void?) {
    self.requestAuthorization()
    completionBlock()
  }
  
  func requestAuthorization() {
    self.locationManager.requestWhenInUseAuthorization()
    self.start()
  }
  
  func start() {
    self.locationManager.startUpdatingLocation()
  }
  
  private func geocode() {
    guard let location = self.location else { return }
    geocoder.reverseGeocodeLocation(location, completionHandler: { (places, error) in
      if error == nil {
        self.placemark = places?[0]
        SolarCalculator.shared.timezone = places?[0].timeZone ?? .current
      } else {
        self.placemark = nil
      }
      
      self.objectWillChange.send()
    })
  }
  
  func resetLocation() {
    self.location = locationManager.location
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    self.status = status
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    self.location = location
    self.geocode()
    
    self.objectWillChange.send()
  }
}

extension CLLocation {
  var latitude: Double {
    return self.coordinate.latitude
  }
  
  var longitude: Double {
    return self.coordinate.longitude
  }
}
