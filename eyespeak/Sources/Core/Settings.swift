//
//  Settings.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import Foundation
import SwiftUI

class UserSettings {
    @AppStorage("timerSpeed") var timerSpeed: Double = 4.0
    @AppStorage("fontSize") var fontSize: Double = 14
}
