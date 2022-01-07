//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 08/01/2021.
//

import WidgetKit
import SwiftUI
import Solar

enum SolsticeWidgetKind: String {
  case CountdownWidget, OverviewWidget
}

struct SolsticeWidgetTimelineProvider: TimelineProvider {
  var widgetIdentifier: String?
  
  func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
    SolsticeWidgetTimelineEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> ()) {
    let entry = SolsticeWidgetTimelineEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SolsticeWidgetTimelineEntry] = []
    let solar = Solar(coordinate: LocationManager.shared.coordinate)!

    let currentDate = Date()
    let distanceToSunrise = abs(currentDate.distance(to: solar.begins))
    let distanceToSunset = abs(currentDate.distance(to: solar.ends))
    let nearestEventDistance = min(distanceToSunset, distanceToSunrise)
    let relevance: TimelineEntryRelevance? = nearestEventDistance < (60 * 30)
      ? .init(score: 10, duration: nearestEventDistance)
      : nil
    
    var nextUpdateDate = currentDate.addingTimeInterval(60 * 15)
    
    if nextUpdateDate < solar.begins {
      nextUpdateDate = solar.begins.addingTimeInterval(1)
    } else if nextUpdateDate < solar.ends {
      nextUpdateDate = solar.ends.addingTimeInterval(1)
    }
    
    entries.append(
      SolsticeWidgetTimelineEntry(
        date: currentDate,
        relevance: relevance
      )
    )
    
    let timeline = Timeline(
      entries: entries,
      policy: .atEnd
    )
    print(timeline.entries, nextUpdateDate)
    completion(timeline)
  }
}

struct SolsticeWidgetTimelineEntry: TimelineEntry {
  let date: Date
  var relevance: TimelineEntryRelevance? = nil
}

@main
struct SolsticeWidgets: WidgetBundle {
  var body: some Widget {
    SolsticeOverviewWidget()
    SolsticeCountdownWidget()
  }
}

struct SolsticeOverviewWidget: Widget {
  let kind: String = "OverviewWidget"
  
  @StateObject var locationManager = LocationManager.shared
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SolsticeWidgetTimelineProvider()) { entry in
      OverviewWidgetView()
        .environmentObject(locationManager)
        .environmentObject(SolarCalculator(baseDate: entry.date, locationManager: locationManager))
    }
    .configurationDisplayName("Daylight Today")
    .description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
  }
}

struct SolsticeCountdownWidget: Widget {
  let kind: String = "CountdownWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SolsticeWidgetTimelineProvider(widgetIdentifier: kind)) { entry in
      CountdownWidgetView()
        .environmentObject(SolarCalculator(baseDate: entry.date))
    }
    .configurationDisplayName("Sunrise/Sunset Countdown")
    .description("See the time remaining until the next sunrise/sunset")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
