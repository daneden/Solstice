//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import Combine
import CoreLocation

let springAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)

struct ContentView: View {
  @EnvironmentObject var locationManager: LocationManager
  @State var calculator = SolarCalculator()
  @State var selectedDate = Date()
  @State var dateOffset = 0.0
  @State var settingsVisible = false
  @State var alertPresented = false
  @State var timeTravelVisible = false
  
  var body: some View {
    VStack {
      VStack {
        VStack {
          if timeTravelVisible {
            Text("\(selectedDate, style: .date)")
          }
          if let duration = calculator.today?.durationComponents {
            Text("\(duration.hour ?? 0)hrs, \(duration.minute ?? 0)min")
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        }
          .foregroundColor(timeTravelVisible ? .primary : .secondary)
          .padding(6)
          .padding(.horizontal, 8)
          .background(VisualEffectView.SystemMaterial())
          .cornerRadius(8)
          .scaleEffect(timeTravelVisible ? 1 : 0.9)
          .onTapGesture {
            withAnimation(springAnimation) {
              if timeTravelVisible {
                if self.dateOffset != 0 {
                  self.dateOffset = 0
                } else {
                  timeTravelVisible = false
                }
              } else {
                timeTravelVisible = true
              }
            }
          }
        if timeTravelVisible {
          TimeMachineView(value: $dateOffset, range: (-182.0, 182.0)) { modifiers in
            ZStack {
                Group {
                  VisualEffectView.SystemMaterial()
                    .modifier(modifiers.barRight)
                  
                  VisualEffectView.SystemMaterial()
                    .modifier(modifiers.barLeft)
                }.cornerRadius(24)
              
              VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.down.fill").imageScale(.small)
                  .padding(.vertical, -2)
                Rectangle().frame(width: 2)
              }.foregroundColor(.systemTeal)
                .modifier(modifiers.knob)
              }
          }.frame(height: 16).padding()
        }
      }
      
      SundialView(calculator: calculator)
      
      VStack(alignment: .leading, spacing: 4) {
        TabView {
          SolsticeOverview(calculator: calculator)
            .padding()
          if let nextSolstice = calculator.nextSolstice,
             let prevSolsticeDifference = prevSolsticeDifference {
            VStack {
              VStack(alignment: .leading, spacing: 8) {
                Text("\(nextSolstice, style: .relative) until the next solstice.")
                
                Text(prevSolsticeDifference)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .font(Font.system(.title, design: .rounded).bold())
            .padding()
            .frame(maxWidth: .infinity)
          }
        }.tabViewStyle(PageTabViewStyle())
      }
    }.toolbar {
      ToolbarItem {
        Button(action: { settingsVisible.toggle() }) {
          Label("Settings", systemImage: "gearshape")
        }
      }
    }.sheet(isPresented: $settingsVisible) {
      SettingsView()
    }
    .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
      // Debug stubs
//      alertPresented = true
    }
    .alert(isPresented: $alertPresented) {
      Alert(title: Text("Debug Information"),
            message: Text("""
              Latitude: \(LocationManager.shared.latitude)
              Longitude: \(LocationManager.shared.longitude)
              Daylight length (today): \(calculator.today?.duration ?? 0)
              Daylight length (yesterday): \(calculator.yesterday?.duration ?? 0)
              Previous solstice: \(calculator.prevSolstice ?? Date(), style: .date)
              Previous solstice length: \(calculator.prevSolsticeDaylight?.duration ?? 0)
              """),
            dismissButton: .default(Text("Close")))
    }
    .onChange(of: dateOffset) { value in
      self.selectedDate = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
      self.calculator = SolarCalculator(baseDate: self.selectedDate)
    }
  }
  
  var prevSolsticeDifference: String? {
    guard let prevSolsticeDaylight = calculator.prevSolsticeDaylight else { return nil }
    guard let today = calculator.today else { return nil }
    let difference = today.difference(from: prevSolsticeDaylight)
    
    var value = today.difference(from: prevSolsticeDaylight).toColloquialTimeString()
    
    if difference >= 0 {
      value += " more "
    } else {
      value += " less "
    }
    
    value += "daylight today than at the previous solstice."
    
    return value
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
