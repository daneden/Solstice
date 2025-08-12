//
//  SettingsView.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	
    var body: some View {
			NavigationStack {
				Form {
					Section {
						AboutSolsticeView()
					}
					
					NotificationSettings()
					
					SupporterSettings()
				}
				.formStyle(.grouped)
			}
			#if !os(macOS)
			.toolbar {
				Button {
					dismiss()
				} label: {
					Text("Close")
				}
			}
			#endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
