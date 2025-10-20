//
//  Settings.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import Foundation
import SwiftUI

/// Represents settings for combo input behavior. Adjust properties as needed for your app.
struct ComboInputSettings: Codable, Equatable {
    var isEnabled: Bool
    var maxCombos: Int
    var sensitivity: Double

    static let defaults = ComboInputSettings(isEnabled: true, maxCombos: 2, sensitivity: 0.5)
}

class UserSettings {
    @AppStorage("timerSpeed") var timerSpeed: Double = 4.0
    @AppStorage("fontSize") var fontSize: Double = 14

    @AppStorage("comboInputSettings") private var comboInputSettingsData: Data?

    var comboInputSettings: ComboInputSettings {
        get {
            if let data = comboInputSettingsData, let decoded = try? JSONDecoder().decode(ComboInputSettings.self, from: data) {
                return decoded
            }
            return .defaults
        }
        set {
            comboInputSettingsData = try? JSONEncoder().encode(newValue)
        }
    }
}

