//
//  LocationAppEntity.swift
//  Solstice
//
//  Created by Daniel Eden on 31/01/2026.
//

import Foundation
import AppIntents
import CoreLocation
import CoreData
import MapKit

/// An AppEntity representing a location for widget configuration.
/// Can represent either a SavedLocation from Core Data or a searched location.
struct LocationAppEntity: AppEntity {
	/// Special ID for the current location entity
	static let currentLocationID = "currentLocation"

	/// Unique identifier for the entity
	var id: String

	/// Display title for the location
	var title: String

	/// Subtitle (e.g., country or region)
	var subtitle: String?

	/// Latitude coordinate
	var latitude: Double

	/// Longitude coordinate
	var longitude: Double

	/// Timezone identifier for accurate sunrise/sunset calculations
	var timeZoneIdentifier: String?

	/// UUID of the SavedLocation if this entity represents a saved location
	var savedLocationUUID: UUID?

	/// Whether this entity represents the current location
	var isCurrentLocation: Bool {
		id == Self.currentLocationID
	}

	/// The current location entity - uses device's current location
	static var currentLocation: LocationAppEntity {
		LocationAppEntity(
			id: currentLocationID,
			title: String(localized: "Current Location"),
			subtitle: nil,
			latitude: 0,
			longitude: 0,
			timeZoneIdentifier: nil,
			savedLocationUUID: nil
		)
	}

	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Location")
	}

	var displayRepresentation: DisplayRepresentation {
		if isCurrentLocation {
			return DisplayRepresentation(
				title: "\(title)",
				subtitle: nil,
				image: .init(systemName: "location.fill")
			)
		}
		return DisplayRepresentation(
			title: "\(title)",
			subtitle: subtitle.map { "\($0)" }
		)
	}

	static var defaultQuery = LocationEntityQuery()
}

// MARK: - Entity Query

struct LocationEntityQuery: EntityQuery, EntityStringQuery {
	private static let geocoder = CLGeocoder()

	/// Provides the default result when no selection is made
	func defaultResult() async -> LocationAppEntity? {
		.currentLocation
	}

	/// Fetch entities by their IDs
	func entities(for identifiers: [String]) async throws -> [LocationAppEntity] {
		var results: [LocationAppEntity] = []

		for id in identifiers {
			// Check for current location
			if id == LocationAppEntity.currentLocationID {
				results.append(.currentLocation)
			}
			// Check for saved location (encoded in ID)
			else if let entity = decodeSavedEntity(from: id) {
				results.append(entity)
			}
			// Check for temporary/searched location
			else if let entity = decodeTemporaryEntity(from: id) {
				results.append(entity)
			}
			// Legacy: Check if this is a raw UUID (old format)
			else if let uuid = UUID(uuidString: id) {
				let context = PersistenceController.shared.container.viewContext
				let request = SavedLocation.fetchRequest()
				request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
				request.fetchLimit = 1

				if let savedLocation = try? context.fetch(request).first {
					results.append(LocationAppEntity(from: savedLocation))
				}
			}
		}

		return results
	}

	/// Decode a saved location entity from its ID
	private func decodeSavedEntity(from id: String) -> LocationAppEntity? {
		guard id.hasPrefix("saved:") else { return nil }

		let encoded = String(id.dropFirst(6))
		guard let decoded = encoded.removingPercentEncoding,
			  let data = decoded.data(using: .utf8),
			  let locationData = try? JSONDecoder().decode(LocationData.self, from: data) else {
			return nil
		}

		return LocationAppEntity(
			id: id,
			title: locationData.title ?? "Unknown",
			subtitle: locationData.subtitle,
			latitude: locationData.latitude,
			longitude: locationData.longitude,
			timeZoneIdentifier: locationData.timeZoneIdentifier,
			savedLocationUUID: locationData.uuid
		)
	}

	/// Provide suggested entities - current location first, then saved locations
	func suggestedEntities() async throws -> [LocationAppEntity] {
		var results: [LocationAppEntity] = [.currentLocation]

		let context = PersistenceController.shared.container.viewContext
		let request = SavedLocation.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.title, ascending: true)]

		let savedLocations = (try? context.fetch(request)) ?? []
		results.append(contentsOf: savedLocations.map { LocationAppEntity(from: $0) })

		return results
	}

	/// Search for locations using MapKit
	func entities(matching string: String) async throws -> [LocationAppEntity] {
		guard !string.isEmpty else {
			return try await suggestedEntities()
		}

		var results: [LocationAppEntity] = []

		// Include "Current Location" if search matches
		let currentLocationTitle = String(localized: "Current Location")
		if currentLocationTitle.localizedCaseInsensitiveContains(string) {
			results.append(.currentLocation)
		}

		// Search saved locations
		let context = PersistenceController.shared.container.viewContext
		let request = SavedLocation.fetchRequest()
		request.predicate = NSPredicate(
			format: "title CONTAINS[cd] %@ OR subtitle CONTAINS[cd] %@",
			string, string
		)
		let savedLocations = (try? context.fetch(request)) ?? []
		results.append(contentsOf: savedLocations.map { LocationAppEntity(from: $0) })

		// Then, search using MapKit
		let searchRequest = MKLocalSearch.Request()
		searchRequest.naturalLanguageQuery = string
		searchRequest.resultTypes = [.address, .pointOfInterest]

		let search = MKLocalSearch(request: searchRequest)

		do {
			let response = try await search.start()

			for item in response.mapItems.prefix(5) {
				guard let location = item.placemark.location else { continue }

				let timeZoneIdentifier: String?
				if let timeZone = item.placemark.timeZone {
					timeZoneIdentifier = timeZone.identifier
				} else {
					timeZoneIdentifier = await fetchTimezone(for: location)
				}

				let entity = LocationAppEntity(
					id: encodeTemporaryEntity(
						title: item.name ?? item.placemark.locality ?? "Unknown",
						subtitle: item.placemark.country,
						latitude: location.coordinate.latitude,
						longitude: location.coordinate.longitude,
						timeZoneIdentifier: timeZoneIdentifier
					),
					title: item.name ?? item.placemark.locality ?? "Unknown",
					subtitle: [item.placemark.locality, item.placemark.administrativeArea, item.placemark.country]
						.compactMap { $0 }
						.filter { $0 != item.name }
						.joined(separator: ", "),
					latitude: location.coordinate.latitude,
					longitude: location.coordinate.longitude,
					timeZoneIdentifier: timeZoneIdentifier,
					savedLocationUUID: nil
				)

				// Avoid duplicates with saved locations
				if !results.contains(where: { existing in
					let distance = CLLocation(latitude: existing.latitude, longitude: existing.longitude)
						.distance(from: location)
					return distance < 5000 // Within 5km
				}) {
					results.append(entity)
				}
			}
		} catch {
			// Search failed, return only saved location matches
		}

		return results
	}

	/// Fetch timezone for a location via reverse geocoding
	private func fetchTimezone(for location: CLLocation) async -> String? {
		do {
			let placemarks = try await Self.geocoder.reverseGeocodeLocation(location)
			return placemarks.first?.timeZone?.identifier
		} catch {
			return nil
		}
	}

	// MARK: - Temporary Entity Encoding

	/// Encode a temporary (searched) location into an ID string
	private func encodeTemporaryEntity(
		title: String,
		subtitle: String?,
		latitude: Double,
		longitude: Double,
		timeZoneIdentifier: String?
	) -> String {
		let data = LocationData(
			title: title,
			subtitle: subtitle,
			latitude: latitude,
			longitude: longitude,
			timeZoneIdentifier: timeZoneIdentifier
		)

		guard let encoded = try? JSONEncoder().encode(data),
			  let string = String(data: encoded, encoding: .utf8) else {
			return "temp:\(latitude),\(longitude)"
		}

		return "temp:" + string.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
	}

	/// Decode a temporary location from an ID string
	private func decodeTemporaryEntity(from id: String) -> LocationAppEntity? {
		guard id.hasPrefix("temp:") else { return nil }

		let encoded = String(id.dropFirst(5))
		guard let decoded = encoded.removingPercentEncoding,
			  let data = decoded.data(using: .utf8),
			  let locationData = try? JSONDecoder().decode(LocationData.self, from: data) else {
			return nil
		}

		return LocationAppEntity(
			id: id,
			title: locationData.title ?? "Unknown",
			subtitle: locationData.subtitle,
			latitude: locationData.latitude,
			longitude: locationData.longitude,
			timeZoneIdentifier: locationData.timeZoneIdentifier,
			savedLocationUUID: nil
		)
	}
}

// MARK: - Convenience Initializers

extension LocationAppEntity {
	/// Initialize from a SavedLocation Core Data object
	/// Encodes the full location data in the ID for resilient entity resolution
	init(from savedLocation: SavedLocation) {
		let title = savedLocation.title ?? "Unknown"
		let subtitle = savedLocation.subtitle

		// Encode full location data in ID so entity can be resolved even if Core Data lookup fails
		let data = LocationData(
			title: title,
			subtitle: subtitle,
			latitude: savedLocation.latitude,
			longitude: savedLocation.longitude,
			timeZoneIdentifier: savedLocation.timeZoneIdentifier,
			uuid: savedLocation.uuid
		)

		if let encoded = try? JSONEncoder().encode(data),
		   let jsonString = String(data: encoded, encoding: .utf8) {
			self.id = "saved:" + jsonString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
		} else {
			// Fallback to UUID if encoding fails
			self.id = savedLocation.uuid?.uuidString ?? UUID().uuidString
		}

		self.title = title
		self.subtitle = subtitle
		self.latitude = savedLocation.latitude
		self.longitude = savedLocation.longitude
		self.timeZoneIdentifier = savedLocation.timeZoneIdentifier
		self.savedLocationUUID = savedLocation.uuid
	}
}
