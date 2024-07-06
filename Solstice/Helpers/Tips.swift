//
//  Tips.swift
//  Solstice
//
//  Created by Daniel Eden on 05/07/2024.
//

import Foundation
import TipKit

struct WelcomeTip: Tip {
	var title: Text {
		Text("Welcome to Solstice")
	}
	
	var message: Text? {
		Text("You can use Solstice with or without your real location. Tap this button to allow or deny access to your location.")
	}
	
	let id = "WelcomeTip"
}
