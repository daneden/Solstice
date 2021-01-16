//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import Combine
import CoreLocation

struct ContentView: View {
  @EnvironmentObject var locationManager: LocationManager
  @State var calculator = SolarCalculator.shared
  @State var selectedDate = Date()
  @State var dateOffset = 0.0
  @State var settingsVisible = false
  @State var timeTravelVisible = false
  
  @State var monthlyDaylight: [Daylight] = []
  
  var body: some View {
    TabView {
      Group {
        VStack {
          Spacer()
          
          SolarTimeMachine(
            timeTravelVisible: $timeTravelVisible,
            dateOffset: $dateOffset,
            selectedDate: $selectedDate,
            calculator: calculator
          )
          
          Spacer()
          Spacer()
          
          SolsticeOverview(calculator: calculator)
            .padding()
        }
      }
      .tag(0)
      .padding(.bottom)
      .padding(.bottom)
      
      Group {
        VStack {
          SunCalendarView(solarCalculator: calculator)
          
          VStack(alignment: .leading, spacing: 8) {
            Filler()
            Text("The next solstice is \(nextSolsticeDistance).")
              .fixedSize(horizontal: false, vertical: true)
            
            Text(prevSolsticeDifference)
              .fixedSize(horizontal: false, vertical: true)
          }
          .font(Font.system(.title, design: .rounded).bold())
        }
      }
      .tag(1)
      .padding()
      .padding(.bottom)
      .padding(.bottom)
      .frame(maxWidth: .infinity)
    }
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    .toolbar {
      ToolbarItem {
        Button(action: { settingsVisible.toggle() }) {
          Label("Settings", systemImage: "gearshape")
        }
      }
    }.sheet(isPresented: $settingsVisible) {
      SettingsView()
    }
    .onChange(of: dateOffset) { value in
      self.selectedDate = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
      self.calculator.baseDate = self.selectedDate
    }
  }
  
  var prevSolsticeDifference:String {
    guard let prevSolsticeDaylight = calculator.prevSolsticeDaylight else { return "" }
    let today = calculator.today
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
  
  var nextSolsticeDistance: String {
    let formatter = RelativeDateTimeFormatter()
    return formatter.localizedString(for: calculator.nextSolstice, relativeTo: selectedDate)
  }
}

struct SolarTimeMachine: View {
  @Binding var timeTravelVisible: Bool
  @Binding var dateOffset: Double
  @Binding var selectedDate: Date
  
  var calculator: SolarCalculator
  var body: some View {
    VStack {
      VStack {
        VStack {
          if timeTravelVisible {
            Text("\(selectedDate, style: .date)")
          }
          if let duration = calculator.today.duration.toColloquialTimeString() {
            Text("\(duration)")
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        }
        .foregroundColor(timeTravelVisible ? .primary : .secondary)
        .padding(6)
        .padding(.horizontal, 6)
        .background(VisualEffectView.SystemMaterial())
        .cornerRadius(8)
        .onTapGesture {
          withAnimation(stiffSpringAnimation) {
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
              }.foregroundColor(.accentColor)
              .modifier(modifiers.knob)
            }
          }.frame(height: 16).padding()
        }
        
        SundialView(calculator: calculator)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
