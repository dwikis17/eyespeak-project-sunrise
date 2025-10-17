//
//  AppStateManager.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//
import Foundation

@MainActor
@Observable

class AppStateManager {
    var currentTab: Tab = .keyboard
    let settings = UserSettings()
}
