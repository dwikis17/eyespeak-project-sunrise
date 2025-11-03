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

public class UserSettings {
    @AppStorage("timerSpeed") var timerSpeed: Double = 4.0
    @AppStorage("fontSize") var fontSize: Double = 14
    @AppStorage("gridRows") var gridRows: Int = 5
    @AppStorage("gridColumns") var gridColumns: Int = 5
    @AppStorage("navNextCombo") private var navNextRaw: String?
    @AppStorage("navPrevCombo") private var navPrevRaw: String?
    @AppStorage("settingsCombo") private var settingsComboRaw: String?

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

    // MARK: - Navigation Combos
    var navNextCombo: (GestureType, GestureType)? {
        get { decodePair(navNextRaw) }
        set { navNextRaw = encodePair(newValue) }
    }
    var navPrevCombo: (GestureType, GestureType)? {
        get { decodePair(navPrevRaw) }
        set { navPrevRaw = encodePair(newValue) }
    }
    var settingsCombo: (GestureType, GestureType)? {
        get { decodePair(settingsComboRaw) }
        set { settingsComboRaw = encodePair(newValue) }
    }

    private func encodePair(_ pair: (GestureType, GestureType)?) -> String? {
        guard let pair else { return nil }
        return "\(pair.0.rawValue)|\(pair.1.rawValue)"
    }

    private func decodePair(_ s: String?) -> (GestureType, GestureType)? {
        guard let s, let sep = s.firstIndex(of: "|") else { return nil }
        let a = String(s[..<sep])
        let b = String(s[s.index(after: sep)...])
        guard let g1 = GestureType(rawValue: a), let g2 = GestureType(rawValue: b) else { return nil }
        return (g1, g2)
    }
}

