//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 08/01/2021.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SolsticeWidgetEntry {
    SolsticeWidgetEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SolsticeWidgetEntry) -> ()) {
    let entry = SolsticeWidgetEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SolsticeWidgetEntry] = []
    
    let solarCalculator = SolarCalculator()
    let calendar = Calendar.autoupdatingCurrent
    let dayStarts = calendar.component(.hour, from: solarCalculator.today.begins)
    let dayEnds = calendar.component(.hour, from: solarCalculator.today.ends)
    
    for hour in 0...23 {
      let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
      let isRelevantHour: Bool = hour == dayStarts || hour == dayEnds
      var duration: TimeInterval
      
      switch hour {
      case dayStarts:
        duration = Date.now.distance(to: solarCalculator.today.begins)
      case dayEnds:
        duration = Date.now.distance(to: solarCalculator.today.ends)
      default:
        duration = 0
      }
      
      entries.append(
        SolsticeWidgetEntry(
          date: date,
          relevance: isRelevantHour ? nil : .init(score: 10, duration: duration)
        )
      )
    }
    
    let timeline = Timeline(
      entries: entries,
      policy: .atEnd
    )
    
    completion(timeline)
  }
}

struct SolsticeWidgetEntry: TimelineEntry {
  let date: Date
  var relevance: TimelineEntryRelevance? = nil
}

struct SolsticeWidgetOverviewEntryView: View {
  var entry: Provider.Entry
  
  @StateObject var locationManager = LocationManager()
  
  var body: some View {
    Group {
      OverviewWidgetView()
        .environmentObject(locationManager)
        .environmentObject(SolarCalculator(baseDate: entry.date, locationManager: locationManager))
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.systemBackground)
  }
}

struct SolsticeCountdownWidgetEntryView: View {
  var entry: Provider.Entry
  
  @StateObject var locationManager = LocationManager()
  
  var body: some View {
    CountdownWidgetView()
      .environmentObject(locationManager)
      .environmentObject(SolarCalculator(baseDate: entry.date, locationManager: locationManager))
  }
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
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      SolsticeWidgetOverviewEntryView(entry: entry)
    }
    .configurationDisplayName("Daylight Today")
    .description("See today’s daylight length, how it compares to yesterday, and sunrise/sunset times.")
  }
}

struct SolsticeCountdownWidget: Widget {
  let kind: String = "CountdownWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      SolsticeCountdownWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Sunrise/Sunset Countdown")
    .description("See the time remaining until the next sunrise/sunset")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct Widget_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeWidgetOverviewEntryView(entry: SolsticeWidgetEntry(date: Date()))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
