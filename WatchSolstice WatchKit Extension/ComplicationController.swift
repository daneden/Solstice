//
//  ComplicationController.swift
//  WatchSolstice WatchKit Extension
//
//  Created by Daniel Eden on 27/09/2021.
//

import ClockKit
import SwiftUI


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "Solstice", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
      guard let template = getTemplate(for: complication.family) else {
        handler(nil)
        return
      }
      
      handler(CLKComplicationTimelineEntry(
        date: Date(),
        complicationTemplate: template
      ))
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
      handler(getTemplate(for: complication.family))
    }
  
  func getTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
    let today = SolarCalculator.shared.today
    
    let sunSize: CGFloat
    
    switch family {
    case .graphicCircular:
      sunSize = 6
    case .graphicExtraLarge:
      sunSize = 16
    default:
      sunSize = 8
    }
    
    let sundial = SundialView(sunSize: sunSize, trackWidth: 2)
    
    let rectangularSundialView = ZStack(alignment: .bottom) {
      HStack {
        HStack {
          Image(systemName: "sunrise")
          Text(today.begins.formatted(date: .omitted, time: .shortened))
        }
        Spacer()
        
        HStack {
          Text(today.ends.formatted(date: .omitted, time: .shortened))
          Image(systemName: "sunset")
        }
      }
      .font(.caption2)
      .imageScale(.small)
      .foregroundStyle(.primary, .secondary)
      
      sundial
        .padding(.bottom, sunSize)
        .complicationForeground()
    }
    
    switch family {
    case .graphicRectangular:
      return CLKComplicationTemplateGraphicRectangularFullView(rectangularSundialView)
    case .graphicCircular:
      return CLKComplicationTemplateGraphicCircularView(sundial.ellipticalEdgeMask())
    case .graphicExtraLarge:
      return CLKComplicationTemplateGraphicExtraLargeCircularView(sundial.ellipticalEdgeMask())
    default:
      return nil
    }
  }
}

struct EllipticalEdgeMaskModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .mask(
        EllipticalGradient(
          gradient: Gradient(stops: [
            Gradient.Stop(color: .black, location: 0.9),
            Gradient.Stop(color: .clear, location: 1.0)
          ])
        )
      )
  }
}

extension View {
  func ellipticalEdgeMask() -> some View {
    self.modifier(EllipticalEdgeMaskModifier())
  }
}
