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

#if !os(watchOS)
import WidgetKit
#else
import ClockKit
#endif

enum LocationType {
  case real(withAuthorizationStatus: CLAuthorizationStatus)
  case synthesized(location: CLLocation)
}

class LocationManager: NSObject, ObservableObject {
  static let shared = LocationManager()
  
  private (set) var locationType: LocationType = .real(withAuthorizationStatus: .notDetermined)
  
  var locationAvailable: Bool {
    if case .real(let status) = locationType, status.isAuthorized {
      return true
    } else if case .synthesized(_) = locationType {
      return true
    } else {
      return false
    }
  }
  
  @AppStorage(UDValues.cachedLatitude) var latitude {
    didSet { self.geocode() }
  }
  
  @AppStorage(UDValues.cachedLongitude) var longitude {
    didSet { self.geocode() }
  }
  
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
      
      #if !os(watchOS)
      WidgetCenter.shared.reloadAllTimelines()
      #else
      let complicationServer = CLKComplicationServer.sharedInstance()
      for complication in complicationServer.activeComplications ?? [] {
        complicationServer.reloadTimeline(for: complication)
      }
      #endif
    }
  }
  
  @Published var placemark: CLPlacemark?
  
  var coordinate: CLLocationCoordinate2D {
    .init(latitude: latitude, longitude: longitude)
  }
  
  override init() {
    super.init()
    
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    self.status = self.locationManager.authorizationStatus
    self.location = CLLocation(latitude: latitude, longitude: longitude)
    
    self.updateLocationType()
  }
  
  func updateLocationType() {
    if let status = self.status {
      // If the locationType is already set as `.real`, we should update it
      if case .real(_) = locationType {
        self.locationType = .real(withAuthorizationStatus: status)
      }
      
      self.start()
    }
  }
  
  func manuallySetLocation(to location: CLLocation) {
    self.location = location
    self.locationType = .synthesized(location: location)
    self.stop()
    self.objectWillChange.send()
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
    if locationAvailable {
      #if os(watchOS)
      self.locationManager.startUpdatingLocation()
      #else
      self.locationManager.startMonitoringSignificantLocationChanges()
      #endif
    }
  }
  
  func stop() {
    #if os(watchOS)
    self.locationManager.stopUpdatingLocation()
    #else
    self.locationManager.stopMonitoringSignificantLocationChanges()
    #endif
  }
  
  private func geocode() {
    guard let location = self.location else { return }
    geocoder.reverseGeocodeLocation(location, completionHandler: { (places, error) in
      if error == nil {
        self.placemark = places?.first
      } else {
        self.placemark = nil
      }
    })
  }
  
  func resetLocation() {
    self.start()
    self.location = locationManager.location
    self.locationType = .real(withAuthorizationStatus: status!)
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    self.status = status
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if case .real(_) = locationType {
      guard let location = locations.last else { return }
      self.location = location
      self.geocode()
    }
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

extension CLAuthorizationStatus {
  var isAuthorized: Bool {
    switch self {
    case .authorizedAlways:
      return true
    case .authorizedWhenInUse:
      return true
    #if os(iOS)
    case .authorized:
      return true
    #endif
    case .notDetermined:
      return false
    case .restricted:
      return false
    case .denied:
      return false
    @unknown default:
      return false
    }
  }
}
