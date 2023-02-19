//
//  TimeMachineView.swift
//  Solstice
//
//  Created by Daniel Eden on 18/02/2023.
//

import SwiftUI

struct TimeMachineView: View {
	@EnvironmentObject var timeMachine: TimeMachine
	
    var body: some View {
			if timeMachine.isOn {
				DatePicker(selection: $timeMachine.targetDate.animation(), displayedComponents: [.date]) {
					Text("\(Image(systemName: "clock.arrow.2.circlepath")) Time Travel")
				}
			}
    }
}

struct TimeMachineView_Previews: PreviewProvider {
    static var previews: some View {
        TimeMachineView()
    }
}
