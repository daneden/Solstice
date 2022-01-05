//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 08/01/2021.
//

import WidgetKit
import SwiftUI

struct SolsticeWidgetTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> SolsticeWidgetTimelineEntry {
    SolsticeWidgetTimelineEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SolsticeWidgetTimelineEntry) -> ()) {
    let entry = SolsticeWidgetTimelineEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SolsticeWidgetTimelineEntry] = []
    
    let solarCalculator = SolarCalculator()
    let calendar = Calendar.autoupdatingCurrent
    
    // Add one entry per hour
    for hour in 0...23 {
      let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
      entries.append(SolsticeWidgetTimelineEntry(date: date))
    }
    
    // Also add entries corresponding to one second after key events, with a
    // high relevance score
    entries.append(contentsOf: [
      SolsticeWidgetTimelineEntry(
        date: solarCalculator.today.begins.addingTimeInterval(1),
        relevance: .init(score: 10, duration: 60 * 10)
      ),
      SolsticeWidgetTimelineEntry(
        date: solarCalculator.today.ends.addingTimeInterval(1),
        relevance: .init(score: 10, duration: 60 * 10)
      ),
    ])
    
    let timeline = Timeline(
      entries: entries.sorted(by: { $0.date < $1.date }),
      policy: .atEnd
    )
    
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
    StaticConfiguration(kind: kind, provider: SolsticeWidgetTimelineProvider()) { entry in
      CountdownWidgetView()
        .environmentObject(SolarCalculator(baseDate: entry.date))
    }
    .configurationDisplayName("Sunrise/Sunset Countdown")
    .description("See the time remaining until the next sunrise/sunset")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
