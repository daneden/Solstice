//
//  LocationManager.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation

class LocationManager: NSObject, ObservableObject {
  let objectWillChange = PassthroughSubject<Void, Never>()
  static let shared = LocationManager()
  
  private let locationManager = CLLocationManager()
  private let geocoder = CLGeocoder()
  
  @Published var status: CLAuthorizationStatus? {
    willSet { objectWillChange.send() }
  }
  
  @Published var location: CLLocation? {
    willSet { objectWillChange.send() }
  }
  
  @Published var placemark: CLPlacemark? {
    willSet { objectWillChange.send() }
  }
  
  override init() {
    super.init()
    
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    self.status = self.locationManager.authorizationStatus
    
    if self.status == .authorizedAlways || self.status == .authorizedWhenInUse {
      self.start()
    }
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
      } else {
        self.placemark = nil
      }
    })
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
