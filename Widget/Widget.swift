//
//  Widget.swift
//  Widget
//
//  Created by Daniel Eden on 08/01/2021.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let timeline = Timeline(
      entries: [SimpleEntry(date: Date())],
      policy: .atEnd
    )
    
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
}

struct SolsticeWidgetOverviewEntryView: View {
  var entry: Provider.Entry
  
  @StateObject var locationManager = LocationManager()
  
  var body: some View {
    Group {
      SolsticeWidgetOverview()
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
    SolsticeCountdownWidgetView()
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
    SolsticeWidgetOverviewEntryView(entry: SimpleEntry(date: Date()))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
