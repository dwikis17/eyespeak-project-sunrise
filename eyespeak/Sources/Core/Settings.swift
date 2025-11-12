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
    @AppStorage("editLayoutCombo") private var editLayoutComboRaw: String?
    @AppStorage("swapCombo") private var swapComboRaw: String?
    @AppStorage("changeColorCombo") private var changeColorComboRaw: String?
    @AppStorage("deleteCombo") private var deleteComboRaw: String?
    @AppStorage("decrementTimerCombo") private var decrementTimerComboRaw: String?
    @AppStorage("incrementTimerCombo") private var incrementTimerComboRaw: String?
    @AppStorage("menuComboAssignments") private var menuComboAssignmentsData: Data?

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
    var editLayoutCombo: (GestureType, GestureType)? {
        get { decodePair(editLayoutComboRaw) }
        set { editLayoutComboRaw = encodePair(newValue) }
    }
    var swapCombo: (GestureType, GestureType)? {
        get { decodePair(swapComboRaw) }
        set { swapComboRaw = encodePair(newValue) }
    }
    var changeColorCombo: (GestureType, GestureType)? {
        get { decodePair(changeColorComboRaw) }
        set { changeColorComboRaw = encodePair(newValue) }
    }
    var deleteCombo: (GestureType, GestureType)? {
        get { decodePair(deleteComboRaw) }
        set { deleteComboRaw = encodePair(newValue) }
    }
    var decrementTimerCombo: (GestureType, GestureType)? {
        get { decodePair(decrementTimerComboRaw) }
        set { decrementTimerComboRaw = encodePair(newValue) }
    }
    var incrementTimerCombo: (GestureType, GestureType)? {
        get { decodePair(incrementTimerComboRaw) }
        set { incrementTimerComboRaw = encodePair(newValue) }
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
    
    // MARK: - Menu Combo Persistence
    
    struct MenuComboAssignment: Codable, Equatable {
        let menuName: String
        let actionId: Int
        let comboId: UUID
    }
    
    func setMenuComboAssignment(menuName: String, actionId: Int, comboId: UUID) {
        var assignments = loadMenuComboAssignments()
        if let index = assignments.firstIndex(where: { $0.menuName == menuName && $0.actionId == actionId }) {
            assignments[index] = MenuComboAssignment(menuName: menuName, actionId: actionId, comboId: comboId)
        } else {
            assignments.append(MenuComboAssignment(menuName: menuName, actionId: actionId, comboId: comboId))
        }
        persistMenuComboAssignments(assignments)
    }
    
    func removeMenuComboAssignment(menuName: String, actionId: Int) {
        var assignments = loadMenuComboAssignments()
        assignments.removeAll { $0.menuName == menuName && $0.actionId == actionId }
        persistMenuComboAssignments(assignments)
    }
    
    func comboAssignment(menuName: String, actionId: Int) -> MenuComboAssignment? {
        loadMenuComboAssignments().first { $0.menuName == menuName && $0.actionId == actionId }
    }
    
    func allMenuComboAssignments() -> [MenuComboAssignment] {
        loadMenuComboAssignments()
    }
    
    private func loadMenuComboAssignments() -> [MenuComboAssignment] {
        guard let data = menuComboAssignmentsData else { return [] }
        return (try? JSONDecoder().decode([MenuComboAssignment].self, from: data)) ?? []
    }
    
    private func persistMenuComboAssignments(_ assignments: [MenuComboAssignment]) {
        menuComboAssignmentsData = try? JSONEncoder().encode(assignments)
    }
}
