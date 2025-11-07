//
//  AACViewModel.swift
//  eyespeak
//
//  Created by Dwiki on 22/10/25.
//

import Foundation
import Observation
import SwiftData
import SwiftUI

/// Represents a menu action trigger for UI updates
public struct MenuActionTrigger: Equatable {
    public let menu: String
    public let actionId: Int
    public let timestamp: Date
    
    public init(menu: String, actionId: Int) {
        self.menu = menu
        self.actionId = actionId
        self.timestamp = Date()
    }
}

@Observable
public final class AACViewModel: ObservableObject {
    public let modelContext: ModelContext
    public let dataManager: DataManager
    public let gestureInputManager: GestureInputManager
    private let speechService: SpeechService
    
    // MARK: - UI State Properties
    public var columns: Int = 5
    public var rows: Int = 5
    public let settings = UserSettings()
    public var currentPage: Int = 0
    public var showingSettings = false
    public var isGestureMode = true
    public var selectedPosition: GridPosition?
    public var faceStatus = FaceStatus()
    public var isCalibrating = false
    public var lastDetectedGesture: GestureType?
    public var recentCombos: [(GestureType, GestureType)] = []
    
    // Current active menu/tab
    public var currentMenu: Tab = .settings
    
    // Edit mode for AAC grid
    public var isEditMode = false
    
    // Menu-specific combo storage (for Settings and Keyboard menus)
    // Key: menu name ("settings", "keyboard"), Value: Dictionary of combo -> action ID
    private var menuCombos: [String: [ActionCombo: Int]] = [:]
    
    // Callback to navigate to settings (needs to be set by parent view)
    public var onNavigateToSettings: (() -> Void)?
    
    // Callback to navigate to AAC (needs to be set by parent view)
    public var onNavigateToAAC: (() -> Void)?
    
    // Callback for menu-specific combo matches (Settings, Keyboard)
    public var onMenuComboMatched: ((String, ActionCombo, Int) -> Void)?
    
    // Published trigger for menu-specific actions (for UI updates)
    public var menuActionTrigger: MenuActionTrigger? = nil
    
    // MARK: - Manager Access
    public var dataManagerInstance: DataManager { dataManager }
    public var gestureInputManagerInstance: GestureInputManager { gestureInputManager }
    
    // MARK: - Computed Properties
    public var positions: [GridPosition] {
        let descriptor = FetchDescriptor<GridPosition>(
            sortBy: [SortDescriptor(\.order)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    public var pageSize: Int { rows * columns }
    public var totalPages: Int {
        let count = positions.count
        let size = max(1, pageSize)
        return max(1, (count + size - 1) / size)
    }
    
    public var currentPagePositions: [GridPosition] {
        guard pageSize > 0 else { return [] }
        let start = currentPage * pageSize
        let end = min(start + pageSize, positions.count)
        if start >= positions.count || start >= end { return [] }
        return Array(positions[start..<end])
    }

    init(
        modelContext: ModelContext,
        dataManager: DataManager,
        gestureInputManager: GestureInputManager,
        speechService: SpeechService
    ) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        self.gestureInputManager = gestureInputManager
        self.speechService = speechService
        setupGestureManager()
    }
    
    // MARK: - Convenience Initializer for Backward Compatibility
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        self.gestureInputManager = GestureInputManager()
        self.speechService = SpeechService.shared
        setupGestureManager()
    }
    
    // MARK: - Setup Methods
    
    private func setupGestureManager() {
        gestureInputManager.onComboMatchedBySlot = { [weak self] combo, slotIndex in
            guard let self = self else { return }
            
            // Check if we're in a menu that has its own combos (Settings, Keyboard)
            if self.currentMenu == .settings || self.currentMenu == .keyboard {
                let menuName = self.currentMenu == .settings ? "settings" : "keyboard"
                
                // First check if this is the settings navigation combo (works from any menu)
                if let settingsCombo = self.settings.settingsCombo,
                   combo.firstGesture == settingsCombo.0 && combo.secondGesture == settingsCombo.1 {
                    // Settings combo - navigate bidirectionally
                    print("✨ Settings navigation combo matched in \(menuName) menu")
                    if self.currentMenu == .aac {
                        self.onNavigateToSettings?()
                    } else if self.currentMenu == .settings {
                        self.onNavigateToAAC?()
                    }
                    return
                }
                
                // Find the combo in menuCombos by matching the gesture pattern
                if let menuComboMap = self.menuCombos[menuName] {
                    // Search for matching combo by gesture pattern (not by object reference)
                    for (menuCombo, actionId) in menuComboMap {
                        if menuCombo.firstGesture == combo.firstGesture && 
                           menuCombo.secondGesture == combo.secondGesture {
                            // Match found in menu-specific combos
                            print("✨ Menu combo matched: \(combo.name) in \(menuName) menu -> actionId \(actionId)")
                            
                            // Trigger the callback
                            self.onMenuComboMatched?(menuName, menuCombo, actionId)
                            
                            // Also set the published trigger for UI updates
                            self.menuActionTrigger = MenuActionTrigger(menu: menuName, actionId: actionId)
                            
                            return
                        }
                    }
                }
                // If no match in menu combos, don't trigger AAC actions
                print("❌ No match found in \(menuName) menu combos")
                return
            }
            
            // For AAC menu, use the existing handler
            self.handleComboMatched(combo: combo, slotIndex: slotIndex)
        }
    }
    
    public func setupManagers() {
        // Pull saved grid configuration from settings and size grid to exactly the current layout needs
        rows = settings.gridRows
        columns = settings.gridColumns
        let desired = pageSize
        let current = positions.count
        if current == 0 {
            try? dataManager.initializeGrid(totalPositions: desired)
        } else if current % desired != 0 {
            // Normalize to a whole number of pages of current page size
            let pages = max(1, Int(ceil(Double(current) / Double(desired))))
            try? dataManager.resizeGrid(newTotal: pages * desired)
        }
        if isGestureMode {
            if totalPages > 1 {
                gestureInputManager.setNavigationCombos(
                    prev: settings.navPrevCombo,
                    next: settings.navNextCombo
                )
            } else {
                gestureInputManager.setNavigationCombos(prev: nil, next: nil)
            }
            // Always set settings combo regardless of page count
            gestureInputManager.setSettingsCombo(settings.settingsCombo)
            print("settings.editLayoutCombo: \(settings.editLayoutCombo)")
            // Always set edit layout combo regardless of page count
            gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            // Always sanitize conflicts if nav combos are configured (even with 1 page)
            sanitizeNavigationComboConflicts()
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }
    }
    
    // MARK: - Gesture Mode Methods
    
    public func toggleGestureMode() {
        withAnimation {
            isGestureMode.toggle()
            if isGestureMode {
                // Configure navigation priority if there is more than one page
                if totalPages > 1 {
                    gestureInputManager.setNavigationCombos(
                        prev: settings.navPrevCombo,
                        next: settings.navNextCombo
                    )
                } else {
                    gestureInputManager.setNavigationCombos(prev: nil, next: nil)
                }
                // Always set settings combo regardless of page count
                gestureInputManager.setSettingsCombo(settings.settingsCombo)
                // Always set edit layout combo regardless of page count
                gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
                // Always sanitize conflicts if nav combos are configured (even with 1 page)
                sanitizeNavigationComboConflicts()
                gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
            } else {
                isCalibrating = false
                gestureInputManager.reset()
                faceStatus.direction = .center
                faceStatus.gazeActivation = 0
                lastDetectedGesture = nil
            }
        }
    }
    
    public func resetGestureMode() {
        withAnimation {
            isGestureMode = false
            isCalibrating = false
            gestureInputManager.reset()
            faceStatus.direction = .center
            faceStatus.gazeActivation = 0
            lastDetectedGesture = nil
        }
    }
    
    // MARK: - Face Tracking Methods
    
    public func handleDetectedGesture(_ gesture: GestureType) {
        guard isGestureMode, !isCalibrating else { return }
        
        lastDetectedGesture = gesture
        
        gestureInputManager.registerGesture(gesture)
    }
    
    public func beginCalibration() {
        guard isGestureMode else { return }
        isCalibrating = true
    }
    
    public func endCalibration() {
        isCalibrating = false
    }

    public func toggleCalibration() {
        guard isGestureMode else { return }
        if isCalibrating {
            endCalibration()
        } else {
            beginCalibration()
        }
    }
    
    // MARK: - Edit Mode Methods
    
    public func toggleEditMode() {
        withAnimation {
            isEditMode.toggle()
        }
    }
    
    // MARK: - Settings Methods
    
    public func showSettings() {
        showingSettings = true
    }
    
    public func hideSettings() {
        showingSettings = false
    }
    
    public func showComboInfo() {
        // This will be handled by showing an alert or sheet
        // For now, we'll use a simple print statement
        print("Combo Info: Some buttons don't have combos because:")
        print("1. Limited gestures selected during onboarding")
        print("2. Navigation combos reserved for page switching")
        print("3. Unique combos per page to avoid duplicates")
        print("4. Grid size may be larger than available unique combos")
    }
    
    // MARK: - Grid Methods
    
    public func setColumns(_ newColumns: Int) {
        columns = newColumns
    }

    /// Ensure that combos are consistent across pages by mirroring
    /// the combo assigned to each slot in the first page to the same
    /// slot index on subsequent pages.
    public func syncCombosAcrossPages(itemsPerPage: Int) {
        guard itemsPerPage > 0 else { return }
        let total = positions.count
        guard total > itemsPerPage else { return }
        let pagesCount = Int(ceil(Double(total) / Double(itemsPerPage)))
        guard pagesCount > 1 else { return }

        for slotIndex in 0..<itemsPerPage {
            let baseIndex = slotIndex
            guard baseIndex < total else { continue }
            let baseCombo = positions[baseIndex].actionCombo

            // Mirror to pages 1...N for the same slot index
            if pagesCount > 1 {
                for page in 1..<pagesCount {
                    let idx = page * itemsPerPage + slotIndex
                    if idx < total {
                        positions[idx].actionCombo = baseCombo
                    }
                }
            }
        }

        try? modelContext.save()

        if isGestureMode {
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }
    }
    
    public func incrementCardUsage(_ card: AACard) {
        try? dataManager.incrementCardUsage(card)
    }
    
    public func deleteCard(_ card: AACard) {
        try? dataManager.deleteCard(card)
    }
    
    public func createCard(title: String, imageData: Data?) -> AACard? {
        return try? dataManager.createCard(title: title, imageData: imageData)
    }
    
    // MARK: - Combo Handling
    
    private func handleComboMatched(combo: ActionCombo, position: GridPosition) {
        print("🎯 Combo matched: \(combo.name) at position \(position.order)")
        recordRecentCombo(combo)
        
        // Highlight the matched position
        withAnimation {
            selectedPosition = position
        }
        
        // Trigger card action
        if let card = position.card {
            incrementCardUsage(card)
            speak(text: card.title)
        }
        
        // Reset highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation {
                self?.selectedPosition = nil
            }
        }
    }
    
    private func handleComboMatched(combo: ActionCombo, slotIndex: Int) {
        // Special negative indices reserved for navigation from the matcher
        if slotIndex == -1 { recordRecentCombo(combo); goToNextPage(); return }
        if slotIndex == -2 { recordRecentCombo(combo); goToPreviousPage(); return }
        if slotIndex == -3 { 
            // Settings combo - navigate bidirectionally based on current menu
            recordRecentCombo(combo)
            if currentMenu == .aac {
                // From AAC → navigate to Settings
                onNavigateToSettings?()
            } else if currentMenu == .settings {
                // From Settings → navigate to AAC
                onNavigateToAAC?()
            }
            return 
        }
        if slotIndex == -4 {
            // Edit Layout combo - toggle edit mode
            recordRecentCombo(combo)
            toggleEditMode()
            return
        }

        let index = currentPage * pageSize + slotIndex
        guard index >= 0, index < positions.count else {
            print("⚠️ Slot index out of bounds for current page: \(slotIndex)")
            return
        }
        // Navigation combos (dynamic based on onboarding selection)
        if let (ng1, ng2) = settings.navNextCombo,
           combo.firstGesture == ng1, combo.secondGesture == ng2 {
            goToNextPage()
            return
        }
        if let (pg1, pg2) = settings.navPrevCombo,
           combo.firstGesture == pg1, combo.secondGesture == pg2 {
            goToPreviousPage()
            return
        }
        let position = positions[index]
        handleComboMatched(combo: combo, position: position)
    }

    private func recordRecentCombo(_ combo: ActionCombo) {
        recentCombos.insert((combo.firstGesture, combo.secondGesture), at: 0)
        if recentCombos.count > 3 {
            recentCombos = Array(recentCombos.prefix(3))
        }
    }
    
    // MARK: - Data Access Methods
    
    public func fetchAllCards() -> [AACard] {
        return dataManager.fetchAllCards()
    }
    
    public func fetchAllActionCombos() -> [ActionCombo] {
        return dataManager.fetchAllActionCombos()
    }
    
    public func fetchAllUserGestures() -> [UserGesture] {
        return dataManager.fetchAllUserGestures()
    }
    
    // MARK: - Grid Position Methods
    
    public func assignCardToPosition(_ card: AACard, position: GridPosition) {
        try? dataManager.assignCardToPosition(card, position: position)
        if isGestureMode {
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }
    }
    
    public func assignComboToPosition(_ combo: ActionCombo, position: GridPosition) {
        // Prevent assigning navigation-priority combos to positions when paging is available
        if totalPages > 1 {
            if let n = settings.navNextCombo, combo.firstGesture == n.0 && combo.secondGesture == n.1 {
                print("⛔️ Not assigning navigation NEXT combo to a grid position")
                return
            }
            if let p = settings.navPrevCombo, combo.firstGesture == p.0 && combo.secondGesture == p.1 {
                print("⛔️ Not assigning navigation PREV combo to a grid position")
                return
            }
        }
        try? dataManager.assignComboToPosition(combo, position: position)
        if isGestureMode {
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }
    }
    
    public func fetchPosition(at index: Int) -> GridPosition? {
        return dataManager.fetchPosition(at: index)
    }
    
    public func resizeGrid(newTotal: Int) {
        try? dataManager.resizeGrid(newTotal: newTotal)
        currentPage = min(currentPage, max(0, totalPages - 1))
        if isGestureMode {
            if totalPages > 1 {
                gestureInputManager.setNavigationCombos(
                    prev: settings.navPrevCombo,
                    next: settings.navNextCombo
                )
            } else {
                gestureInputManager.setNavigationCombos(prev: nil, next: nil)
            }
            // Always set settings combo regardless of page count
            gestureInputManager.setSettingsCombo(settings.settingsCombo)
            // Always set edit layout combo regardless of page count
            gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            // Always sanitize conflicts if nav combos are configured (even with 1 page)
            sanitizeNavigationComboConflicts()
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }

    }

    // MARK: - Conflict Sanitization
    /// Replace any grid `ActionCombo` that equals a navigation combo.
    /// Ensures first page stays actionable and avoids duplicate combos on that page when possible.
    /// Runs even with 1 page if navigation combos are configured to prevent conflicts.
    private func sanitizeNavigationComboConflicts() {
        let navNext = settings.navNextCombo
        let navPrev = settings.navPrevCombo
        let settingsCombo = settings.settingsCombo
        let editLayoutCombo = settings.editLayoutCombo
        // Only sanitize if priority combos are actually configured
        guard navNext != nil || navPrev != nil || settingsCombo != nil || editLayoutCombo != nil else { return }

        func isNavCombo(_ c: ActionCombo) -> Bool {
            if let n = navNext, c.firstGesture == n.0 && c.secondGesture == n.1 { return true }
            if let p = navPrev, c.firstGesture == p.0 && c.secondGesture == p.1 { return true }
            if let s = settingsCombo, c.firstGesture == s.0 && c.secondGesture == s.1 { return true }
            if let e = editLayoutCombo, c.firstGesture == e.0 && c.secondGesture == e.1 { return true }
            return false
        }

        let allCombos = fetchAllActionCombos()
        var candidates = allCombos.filter { !isNavCombo($0) }

        // 1. Fix first page: assign safe, unique combos per slot
        var usedFirstPage = Set<String>()
        let firstPageEnd = min(pageSize, positions.count)
        if firstPageEnd > 0 {
            // First pass: collect all existing non-nav combos already on the first page
            for i in 0..<firstPageEnd {
                if let c = positions[i].actionCombo, !isNavCombo(c) {
                    let key = "\(c.firstGesture.rawValue)|\(c.secondGesture.rawValue)"
                    usedFirstPage.insert(key)
                }
            }
            
            // Second pass: replace nav combos with unique safe combos
            for i in 0..<firstPageEnd {
                let slotCombo = positions[i].actionCombo
                if let c = slotCombo, isNavCombo(c) {
                    // Replace nav combo with first unused safe combo that's not already assigned
                    if let replacement = candidates.first(where: { cand in
                        let key = "\(cand.firstGesture.rawValue)|\(cand.secondGesture.rawValue)"
                        return !usedFirstPage.contains(key)
                    }) {
                        positions[i].actionCombo = replacement
                        let key = "\(replacement.firstGesture.rawValue)|\(replacement.secondGesture.rawValue)"
                        usedFirstPage.insert(key)
                    } else {
                        // No available combo, clear it
                        positions[i].actionCombo = nil
                    }
                }
            }
        }
        // 2. Mirror combos from first page to every other page slot (if not navigation combo)
        // Only mirror if there are multiple pages
        if totalPages > 1 {
            let pageCount = totalPages
            for slotIdx in 0..<firstPageEnd {
                let comboToMirror = positions[slotIdx].actionCombo
                // Never mirror if it's a navigation combo or nil
                if let c = comboToMirror, !isNavCombo(c) {
                    for page in 1..<pageCount {
                        let idx = page * pageSize + slotIdx
                        if idx < positions.count {
                            positions[idx].actionCombo = c
                        }
                    }
                } else {
                    // If nil or nav combo, clear the slot on other pages
                    for page in 1..<pageCount {
                        let idx = page * pageSize + slotIdx
                        if idx < positions.count {
                            positions[idx].actionCombo = nil
                        }
                    }
                }
            }
        }
        try? modelContext.save()
    }
    
    // MARK: - Card Interaction Methods
    
    public func handleCardTap(for card: AACard) {
        // Increment usage
        incrementCardUsage(card)
        
        // Speak the card title
        speak(text: card.title)
        
        // You could also add haptic feedback here
        // let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        // impactFeedback.impactOccurred()
    }

    // MARK: - Paging Methods
    public func goToNextPage() {
        guard currentPage + 1 < totalPages else { return }
        withAnimation { currentPage += 1 }
    }
    
    public func goToPreviousPage() {
        guard currentPage > 0 else { return }
        withAnimation { currentPage -= 1 }
    }

    // MARK: - Speech Helpers

    private func speak(text: String, language: String? = nil) {
        speechService.speak(text, language: language)
    }

    public func speakSentence(_ text: String, language: String? = nil) {
        speak(text: text, language: language)
    }
    
    // MARK: - Menu-Specific Combo Management
    
    /// Set the current active menu and reload combos accordingly
    public func setCurrentMenu(_ menu: Tab) {
        currentMenu = menu
        reloadCombosForCurrentMenu()
    }
    
    /// Reload combos based on the current menu
    private func reloadCombosForCurrentMenu() {
        guard isGestureMode else { return }
        
        switch currentMenu {
        case .aac:
            // Load AAC combos from grid positions (these are stored in the database)
            // Make sure we're using the actual positions, not temporary ones
            if totalPages > 1 {
                gestureInputManager.setNavigationCombos(
                    prev: settings.navPrevCombo,
                    next: settings.navNextCombo
                )
            } else {
                gestureInputManager.setNavigationCombos(prev: nil, next: nil)
            }
            gestureInputManager.setSettingsCombo(settings.settingsCombo)
            gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            // Use the actual positions from the database - this is a computed property that fetches fresh
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
            
        case .settings, .keyboard:
            // Load menu-specific combos (stored in memory, separate from database positions)
            let menuName = currentMenu == .settings ? "settings" : "keyboard"
            let menuComboMap = menuCombos[menuName] ?? [:]
            
            // Convert menu combos directly to the format GestureInputManager expects
            // We'll create a custom loading method to avoid creating temporary GridPosition objects
            // that might interfere with the database
            gestureInputManager.setNavigationCombos(prev: nil, next: nil)
            gestureInputManager.setSettingsCombo(settings.settingsCombo)
            gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            
            // Load menu combos directly without creating temporary positions
            gestureInputManager.loadMenuCombos(menuComboMap)
            
        case .eyeTrackingAccessible, .eyeTrackingSimple:
            // Legacy tabs use AAC
            setCurrentMenu(.aac)
        }
    }
    
    /// Assign a combo to a menu-specific action (Settings, Keyboard)
    public func assignComboToMenu(_ combo: ActionCombo, menu: Tab, actionId: Int) {
        let menuName: String
        switch menu {
        case .settings:
            menuName = "settings"
        case .keyboard:
            menuName = "keyboard"
        default:
            print("⚠️ Cannot assign combo to menu \(menu). Only .settings and .keyboard are supported.")
            return
        }
        
        if menuCombos[menuName] == nil {
            menuCombos[menuName] = [:]
        }
        
        menuCombos[menuName]?[combo] = actionId
        print("✅ Assigned combo \(combo.name) to \(menuName) menu action \(actionId)")
        
        // Reload combos if this is the current menu
        if currentMenu == menu {
            reloadCombosForCurrentMenu()
        }
    }
    
    /// Get combos for a specific menu
    public func getCombosForMenu(_ menu: Tab) -> [ActionCombo: Int] {
        let menuName: String
        switch menu {
        case .settings:
            menuName = "settings"
        case .keyboard:
            menuName = "keyboard"
        default:
            return [:]
        }
        
        return menuCombos[menuName] ?? [:]
    }
}
