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

    // Swap mode state
    public var isSwapMode = false
    public var firstSwapPosition: GridPosition?

    // Edit actions mode for settings
    public var isEditActionsMode = false
    public var editActionsGestures: [UserGesture] = []

    // Menu-specific combo storage (for Settings and Keyboard menus)
    // Key: menu name ("settings", "keyboard"), Value: Dictionary of combo -> action ID
    private var menuCombos: [String: [ActionCombo: Int]] = [:]

    // Callback to navigate to settings (needs to be set by parent view)
    public var onNavigateToSettings: (() -> Void)?

    // Callback to navigate to AAC (needs to be set by parent view)
    public var onNavigateToAAC: (() -> Void)?

    public var onNavigateToKeyboard: (() -> Void)?

    // Callback for menu-specific combo matches (Settings, Keyboard)
    public var onMenuComboMatched: ((String, ActionCombo, Int) -> Void)?

    // Published trigger for menu-specific actions (for UI updates)
    public var menuActionTrigger: MenuActionTrigger? = nil

    // MARK: - Manager Access
    public var dataManagerInstance: DataManager { dataManager }
    public var gestureInputManagerInstance: GestureInputManager {
        gestureInputManager
    }

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
        restoreMenuCombosFromStorage()
    }

    // MARK: - Convenience Initializer for Backward Compatibility
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        self.gestureInputManager = GestureInputManager()
        self.speechService = SpeechService.shared
        setupGestureManager()
        restoreMenuCombosFromStorage()
    }

    // MARK: - Setup Methods

    private func setupGestureManager() {
        gestureInputManager.onComboMatchedBySlot = {
            [weak self] combo, slotIndex in
            guard let self = self else { return }

            // Check if we're in a menu that has its own combos (Settings, Keyboard)
            if self.currentMenu == .settings || self.currentMenu == .keyboard {
                let menuName =
                    self.currentMenu == .settings ? "settings" : "keyboard"

                // First check if this is the settings navigation combo (works from any menu)
                if let settingsCombo = self.settings.settingsCombo,
                    combo.firstGesture == settingsCombo.0
                        && combo.secondGesture == settingsCombo.1
                {
                    // Settings combo - navigate bidirectionally
                    print(
                        "✨ Settings navigation combo matched in \(menuName) menu"
                    )
                    if self.currentMenu != .settings {
                        self.onNavigateToSettings?()
                    } else if self.currentMenu == .settings {
                        self.onNavigateToAAC?()
                    }
                    return
                }

                if let keyboardCombo = self.settings.keyboardCombo,
                    combo.firstGesture == keyboardCombo.0
                        && combo.secondGesture == keyboardCombo.1
                {
                    print("✨ Keyboard combo matched in \(menuName) menu")
                    self.onNavigateToKeyboard?()
                    print("HERE")
                    return
                }

                if self.currentMenu == .settings {
                    if let incrementTimerCombo = self.settings
                        .incrementTimerCombo,
                        combo.firstGesture == incrementTimerCombo.0
                            && combo.secondGesture == incrementTimerCombo.1
                    {
                        print(
                            "✨ Increment Timer combo matched in \(menuName) menu"
                        )
                        self.settings.timerSpeed = min(
                            5.0,
                            self.settings.timerSpeed + 1.0
                        )
                        return
                    }

                    if let decrementTimerCombo = self.settings
                        .decrementTimerCombo,
                        combo.firstGesture == decrementTimerCombo.0
                            && combo.secondGesture == decrementTimerCombo.1
                    {
                        print(
                            "✨ Decrement Timer combo matched in \(menuName) menu"
                        )
                        self.settings.timerSpeed = max(
                            0.5,
                            self.settings.timerSpeed - 1.0
                        )
                        return
                    }

                    // Font size combos
                    if let fontSmallCombo = self.settings.fontSmallCombo,
                        combo.firstGesture == fontSmallCombo.0
                            && combo.secondGesture == fontSmallCombo.1
                    {
                        print("✨ Font Small combo matched in \(menuName) menu")
                        self.settings.fontScale = .small
                        return
                    }

                    if let fontMediumCombo = self.settings.fontMediumCombo,
                        combo.firstGesture == fontMediumCombo.0
                            && combo.secondGesture == fontMediumCombo.1
                    {
                        print("✨ Font Medium combo matched in \(menuName) menu")
                        self.settings.fontScale = .medium
                        return
                    }

                    if let fontBigCombo = self.settings.fontBigCombo,
                        combo.firstGesture == fontBigCombo.0
                            && combo.secondGesture == fontBigCombo.1
                    {
                        print("✨ Font Big combo matched in \(menuName) menu")
                        self.settings.fontScale = .big
                        return
                    }

                }

                // IMPORTANT: Check menuCombos FIRST when in edit actions mode
                // This ensures edit actions combos (like Save) take priority over editLayoutCombo
                // Find the combo in menuCombos by matching the gesture pattern
                if let menuComboMap = self.menuCombos[menuName] {
                    // Search for matching combo by gesture pattern (not by object reference)
                    for (menuCombo, actionId) in menuComboMap {
                        // Match by gesture pattern to avoid invalidated combo references
                        if menuCombo.firstGesture == combo.firstGesture
                            && menuCombo.secondGesture == combo.secondGesture
                        {
                            // Match found in menu-specific combos
                            print(
                                "✨ Menu combo matched: \(combo.name) in \(menuName) menu -> actionId \(actionId)"
                            )

                            // Trigger the callback
                            self.onMenuComboMatched?(
                                menuName,
                                menuCombo,
                                actionId
                            )

                            // Also set the published trigger for UI updates
                            self.menuActionTrigger = MenuActionTrigger(
                                menu: menuName,
                                actionId: actionId
                            )

                            return
                        }
                    }
                }

                // Only check editLayoutCombo if NOT in edit actions mode
                // This prevents conflicts when save combo matches editLayoutCombo
                if !self.isEditActionsMode,
                    let editLayoutCombo = self.settings.editLayoutCombo,
                    combo.firstGesture == editLayoutCombo.0
                        && combo.secondGesture == editLayoutCombo.1
                {
                    print("✨ Edit Layout combo matched in \(menuName) menu")
                    self.toggleEditMode()
                    onNavigateToAAC?()
                    return
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
            // Set timing window from settings
            gestureInputManager.setTimingWindow(settings.timerSpeed)
            gestureInputManager.setKeyboardCombo(settings.keyboardCombo)
            // Set timer combos (always available)
            gestureInputManager.setDecrementTimerCombo(
                settings.decrementTimerCombo
            )
            gestureInputManager.setIncrementTimerCombo(
                settings.incrementTimerCombo
            )
            // Set font size combos (always available)
            gestureInputManager.setFontSmallCombo(settings.fontSmallCombo)
            gestureInputManager.setFontMediumCombo(settings.fontMediumCombo)
            gestureInputManager.setFontBigCombo(settings.fontBigCombo)
            print("settings.editLayoutCombo: \(settings.editLayoutCombo)")
            // Only set edit layout combo as priority when in edit mode or Settings menu
            // Otherwise, let it be used normally for card activation
            // if isEditMode || currentMenu == .settings {
            //     gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            // } else {
            //     gestureInputManager.setEditLayoutCombo(nil)
            // }
            // Set swap combo when in edit mode
            if isEditMode {
                gestureInputManager.setSwapCombo(settings.swapCombo)
                gestureInputManager.setChangeColorCombo(
                    settings.changeColorCombo
                )
            } else {
                gestureInputManager.setChangeColorCombo(nil)
                gestureInputManager.setSwapCombo(nil)
            }
            // Always sanitize conflicts if nav combos are configured (even with 1 page)
            sanitizeNavigationComboConflicts()
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
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
                    gestureInputManager.setNavigationCombos(
                        prev: nil,
                        next: nil
                    )
                }
                // Always set settings combo regardless of page count
                gestureInputManager.setSettingsCombo(settings.settingsCombo)
                // Set timing window from settings
                gestureInputManager.setTimingWindow(settings.timerSpeed)
                // Only set edit layout combo as priority when in edit mode or Settings menu
                // if isEditMode || currentMenu == .settings {
                //     gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
                // } else {
                //     gestureInputManager.setEditLayoutCombo(nil)
                // }
                // Set swap and delete combos when in edit mode
                if isEditMode {
                    gestureInputManager.setSwapCombo(settings.swapCombo)
                    gestureInputManager.setDeleteCombo(settings.deleteCombo)
                    gestureInputManager.setChangeColorCombo(
                        settings.changeColorCombo
                    )
                } else {
                    gestureInputManager.setSwapCombo(nil)
                    gestureInputManager.setDeleteCombo(nil)
                    gestureInputManager.setChangeColorCombo(nil)
                }
                // Always sanitize conflicts if nav combos are configured (even with 1 page)
                sanitizeNavigationComboConflicts()
                gestureInputManager.loadCombosTemplate(
                    from: positions,
                    pageSize: pageSize
                )
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

    public func performSwapAction() {
        // Enter swap mode: lock AAC and wait for second selection
        print("🔄 Swap mode activated - waiting for second card selection")
        if let selectedPosition = selectedPosition {
            withAnimation {
                isSwapMode = true
                firstSwapPosition = selectedPosition
            }
            print("First position selected: \(selectedPosition.order)")
        } else {
            print("⚠️ No position selected for swap")
        }
    }

    private func performSwap(first: GridPosition, second: GridPosition) {
        print(
            "🔄 Swapping cards between positions \(first.order) and \(second.order)"
        )

        // Swap the cards
        let firstCard = first.card
        let secondCard = second.card

        first.card = secondCard
        second.card = firstCard

        // Save changes
        try? modelContext.save()

        // Exit swap mode
        withAnimation {
            isSwapMode = false
            firstSwapPosition = nil
            selectedPosition = second  // Highlight the second position after swap
        }

        print("✅ Swap completed")
        toggleEditMode()

        // Reset selection after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation {
                self?.selectedPosition = nil
            }
        }
    }

    public func cancelSwapMode() {
        withAnimation {
            isSwapMode = false
            firstSwapPosition = nil
        }
        print("❌ Swap mode cancelled")
    }

    public func performDeleteAction() {
        // Delete the selected card
        print("🗑️ Delete action triggered")
        if let position = selectedPosition,
            let card = position.card
        {
            // Remove card from position
            position.card = nil
            // Delete the card from database
            deleteCard(card)
            // Clear selection
            withAnimation {
                selectedPosition = nil
            }
            print("✅ Card deleted: \(card.title)")
            self.toggleEditMode()
            resizeGrid(newTotal: positions.count)
        } else {
            print("⚠️ No card selected for deletion")
        }
    }

    public func performChangeColorAction() {
        // Change the color of the selected card
        print("🎨 Change color action triggered")
        let colors: [Color] = [
            .energeticOrange, .oldHulkGreen, .mellowBlue, .widowPurple,
            .charmingYellow,
        ]
        let colorHexes: [String] = [
            "#FE773C", "#2FA553", "#586C9D", "#AD6AE3", "#F6CA33",
        ]

        if let position = selectedPosition,
            let card = position.card
        {
            let currentColor = card.color
            var currentIndex = colors.firstIndex(of: currentColor)
            if currentIndex == nil {
                currentIndex = 0
            }
            let nextIndex = (currentIndex! + 1) % colors.count
            let nextColorHex = colorHexes[nextIndex]
            card.colorHex = nextColorHex
            // Save the changes
            try? modelContext.save()

            withAnimation {
                selectedPosition = nil
            }
            self.toggleEditMode()
        }
    }

    public func toggleEditMode() {
        withAnimation {
            isEditMode.toggle()
            // Update editLayoutCombo priority when edit mode changes
            if isGestureMode {
                if isEditMode {
                    // When entering edit mode, set editLayoutCombo as priority (to allow exit)
                    gestureInputManager.setEditLayoutCombo(
                        settings.editLayoutCombo
                    )
                    // Set swap and delete combos when entering edit mode
                    gestureInputManager.setSwapCombo(settings.swapCombo)
                    gestureInputManager.setDeleteCombo(settings.deleteCombo)
                    gestureInputManager.setChangeColorCombo(
                        settings.changeColorCombo
                    )
                } else {
                    // When exiting edit mode, remove priority so combo can be used normally
                    gestureInputManager.setEditLayoutCombo(nil)
                    // Remove swap and delete combos when exiting edit mode
                    gestureInputManager.setSwapCombo(nil)
                    gestureInputManager.setDeleteCombo(nil)
                    gestureInputManager.setChangeColorCombo(nil)
                    // Clear selection and swap mode when exiting edit mode
                    selectedPosition = nil
                    cancelSwapMode()
                }
                // Reload combos to reflect the change
                if currentMenu == .aac {
                    gestureInputManager.loadCombosTemplate(
                        from: positions,
                        pageSize: pageSize
                    )
                }
            }
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
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
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

    @discardableResult
    public func addCardFromKeyboard(text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let card = createCard(title: trimmed, imageData: nil) else {
            return false
        }

        if let emptySlot = positions.first(where: { $0.card == nil }) {
            assignCardToPosition(card, position: emptySlot)
            return true
        }

        do {
            let newPosition = try dataManager.createGridPosition(
                index: positions.count
            )
            assignCardToPosition(card, position: newPosition)
            return true
        } catch {
            // Cleanup the card if we failed to place it
            try? dataManager.deleteCard(card)
            return false
        }
    }

    // MARK: - Combo Handling

    private func handleComboMatched(combo: ActionCombo, position: GridPosition)
    {
        print("🎯 Combo matched: \(combo.name) at position \(position.order)")
        recordRecentCombo(combo)

        // Check if we're in swap mode
        if isSwapMode, let firstPosition = firstSwapPosition {
            // This is the second selection for swap
            if firstPosition.id == position.id {
                // Same position selected - cancel swap mode
                cancelSwapMode()
                return
            }

            // Perform the swap
            performSwap(first: firstPosition, second: position)
            return
        }

        // Highlight the matched position
        withAnimation {
            selectedPosition = position
        }

        // In edit mode, don't trigger card action and keep selection persistent
        // But allow swap mode to work
        if isEditMode && !isSwapMode {
            // Selection persists in edit mode for editing actions
            return
        }

        // If in swap mode but no first position, enter swap mode with this position
        if isSwapMode && firstSwapPosition == nil {
            firstSwapPosition = position
            return
        }

        // Trigger card action (only when not in edit mode or swap mode)
        if !isEditMode && !isSwapMode {
            if let card = position.card {
                incrementCardUsage(card)
                speak(text: card.title)
            }

            // Reset highlight after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                [weak self] in
                guard let self = self else { return }
                withAnimation {
                    self.selectedPosition = nil
                }
            }
        }
    }

    private func performKeyboardAction() {
        print("🎯 Keyboard action triggered")
        onNavigateToKeyboard?()
    }

    private func handleComboMatched(combo: ActionCombo, slotIndex: Int) {
        // Special negative indices reserved for navigation from the matcher
        if slotIndex == -1 {
            recordRecentCombo(combo)
            goToNextPage()
            return
        }
        if slotIndex == -2 {
            recordRecentCombo(combo)
            goToPreviousPage()
            return
        }
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
            // This only triggers when priority is set (Settings menu or when already in edit mode)
            recordRecentCombo(combo)
            if currentMenu == .settings {
                print("toggleEditMode")
                toggleEditMode()
            }
            return
        }
        if slotIndex == -5 {
            // Swap combo - perform swap action in edit mode
            recordRecentCombo(combo)
            if isEditMode {
                performSwapAction()
            }
            return
        }
        if slotIndex == -6 {
            // Delete combo - perform delete action in edit mode
            recordRecentCombo(combo)
            if isEditMode {
                performDeleteAction()
            }
            return
        }

        if slotIndex == -9 {
            if isEditMode {
                performChangeColorAction()
            }

            return
        }
        if slotIndex == -12 {
            recordRecentCombo(combo)
            performKeyboardAction()
            return
        }

        let index = currentPage * pageSize + slotIndex
        guard index >= 0, index < positions.count else {
            print("⚠️ Slot index out of bounds for current page: \(slotIndex)")
            return
        }
        // Navigation combos (dynamic based on onboarding selection)
        if let (ng1, ng2) = settings.navNextCombo,
            combo.firstGesture == ng1, combo.secondGesture == ng2
        {
            goToNextPage()
            return
        }
        if let (pg1, pg2) = settings.navPrevCombo,
            combo.firstGesture == pg1, combo.secondGesture == pg2
        {
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
        let gestures = dataManager.fetchAllUserGestures()
        print(gestures.count, "count")
        gestures.forEach { body in
            print(body.gestureType, body.isEnabled, "body")
        }
        return gestures
    }

    // MARK: - Grid Position Methods

    public func assignCardToPosition(_ card: AACard, position: GridPosition) {
        try? dataManager.assignCardToPosition(card, position: position)
        if isGestureMode {
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
        }
    }

    public func assignComboToPosition(
        _ combo: ActionCombo,
        position: GridPosition
    ) {
        // Prevent assigning navigation-priority combos to positions when paging is available
        if totalPages > 1 {
            if let n = settings.navNextCombo,
                combo.firstGesture == n.0 && combo.secondGesture == n.1
            {
                print(
                    "⛔️ Not assigning navigation NEXT combo to a grid position"
                )
                return
            }
            if let p = settings.navPrevCombo,
                combo.firstGesture == p.0 && combo.secondGesture == p.1
            {
                print(
                    "⛔️ Not assigning navigation PREV combo to a grid position"
                )
                return
            }
        }
        try? dataManager.assignComboToPosition(combo, position: position)
        if isGestureMode {
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
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
            // Set timing window from settings
            gestureInputManager.setTimingWindow(settings.timerSpeed)
            // Set timer combos (always available)
            gestureInputManager.setDecrementTimerCombo(
                settings.decrementTimerCombo
            )
            gestureInputManager.setIncrementTimerCombo(
                settings.incrementTimerCombo
            )
            // Set font size combos (always available)
            gestureInputManager.setFontSmallCombo(settings.fontSmallCombo)
            gestureInputManager.setFontMediumCombo(settings.fontMediumCombo)
            gestureInputManager.setFontBigCombo(settings.fontBigCombo)
            // Only set edit layout combo as priority when in edit mode or Settings menu
            if isEditMode || currentMenu == .settings {
                gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            } else {
                gestureInputManager.setEditLayoutCombo(nil)
            }
            // Set swap and delete combos when in edit mode
            if isEditMode {
                gestureInputManager.setSwapCombo(settings.swapCombo)
                gestureInputManager.setDeleteCombo(settings.deleteCombo)
                gestureInputManager.setChangeColorCombo(
                    settings.changeColorCombo
                )
            } else {
                gestureInputManager.setSwapCombo(nil)
                gestureInputManager.setDeleteCombo(nil)
                gestureInputManager.setChangeColorCombo(nil)
            }
            // Always sanitize conflicts if nav combos are configured (even with 1 page)
            sanitizeNavigationComboConflicts()
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
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
        let swapCombo = settings.swapCombo
        let changeColorCombo = settings.changeColorCombo
        let deleteCombo = settings.deleteCombo
        let decrementTimerCombo = settings.decrementTimerCombo
        let incrementTimerCombo = settings.incrementTimerCombo
        // Only sanitize if priority combos are actually configured
        guard
            navNext != nil || navPrev != nil || settingsCombo != nil
                || editLayoutCombo != nil || swapCombo != nil
                || deleteCombo != nil || decrementTimerCombo != nil
                || incrementTimerCombo != nil || changeColorCombo != nil
        else { return }

        func isNavCombo(_ c: ActionCombo) -> Bool {
            if let n = navNext, c.firstGesture == n.0 && c.secondGesture == n.1
            {
                return true
            }
            if let p = navPrev, c.firstGesture == p.0 && c.secondGesture == p.1
            {
                return true
            }
            if let s = settingsCombo,
                c.firstGesture == s.0 && c.secondGesture == s.1
            {
                return true
            }
            if let e = editLayoutCombo,
                c.firstGesture == e.0 && c.secondGesture == e.1
            {
                return true
            }
            if let sw = swapCombo,
                c.firstGesture == sw.0 && c.secondGesture == sw.1
            {
                return true
            }
            if let d = deleteCombo,
                c.firstGesture == d.0 && c.secondGesture == d.1
            {
                return true
            }
            if let dt = decrementTimerCombo,
                c.firstGesture == dt.0 && c.secondGesture == dt.1
            {
                return true
            }
            if let it = incrementTimerCombo,
                c.firstGesture == it.0 && c.secondGesture == it.1
            {
                return true
            }
            if let cc = changeColorCombo,
                c.firstGesture == cc.0 && c.secondGesture == cc.1
            {
                return true
            }
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
                    let key =
                        "\(c.firstGesture.rawValue)|\(c.secondGesture.rawValue)"
                    usedFirstPage.insert(key)
                }
            }

            // Second pass: replace nav combos with unique safe combos
            for i in 0..<firstPageEnd {
                let slotCombo = positions[i].actionCombo
                if let c = slotCombo, isNavCombo(c) {
                    // Replace nav combo with first unused safe combo that's not already assigned
                    if let replacement = candidates.first(where: { cand in
                        let key =
                            "\(cand.firstGesture.rawValue)|\(cand.secondGesture.rawValue)"
                        return !usedFirstPage.contains(key)
                    }) {
                        positions[i].actionCombo = replacement
                        let key =
                            "\(replacement.firstGesture.rawValue)|\(replacement.secondGesture.rawValue)"
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
    public func reloadCombosForCurrentMenu() {
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
            gestureInputManager.setKeyboardCombo(settings.keyboardCombo)
            // Set timing window from settings
            gestureInputManager.setTimingWindow(settings.timerSpeed)
            // Set timer combos (always available)
            gestureInputManager.setDecrementTimerCombo(
                settings.decrementTimerCombo
            )
            gestureInputManager.setIncrementTimerCombo(
                settings.incrementTimerCombo
            )
            // Set font size combos (always available)
            gestureInputManager.setFontSmallCombo(settings.fontSmallCombo)
            gestureInputManager.setFontMediumCombo(settings.fontMediumCombo)
            gestureInputManager.setFontBigCombo(settings.fontBigCombo)
            // Only set editLayoutCombo as priority when in edit mode (to allow exit)
            // Otherwise, let it be used normally for card activation
            if isEditMode {
                gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            } else {
                gestureInputManager.setEditLayoutCombo(nil)
            }
            // Set swap and delete combos when in edit mode
            if isEditMode {
                gestureInputManager.setSwapCombo(settings.swapCombo)
                gestureInputManager.setDeleteCombo(settings.deleteCombo)
                gestureInputManager.setChangeColorCombo(
                    settings.changeColorCombo
                )
            } else {
                gestureInputManager.setSwapCombo(nil)
                gestureInputManager.setDeleteCombo(nil)
                gestureInputManager.setChangeColorCombo(nil)
            }
            // Use the actual positions from the database - this is a computed property that fetches fresh
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )

        case .settings, .keyboard:
            // Load menu-specific combos (stored in memory, separate from database positions)
            let menuName = currentMenu == .settings ? "settings" : "keyboard"
            let menuComboMap = menuCombos[menuName] ?? [:]

            // Convert menu combos directly to the format GestureInputManager expects
            // We'll create a custom loading method to avoid creating temporary GridPosition objects
            // that might interfere with the database
            gestureInputManager.setNavigationCombos(prev: nil, next: nil)
            gestureInputManager.setSettingsCombo(settings.settingsCombo)
            gestureInputManager.setKeyboardCombo(settings.keyboardCombo)
            // Set timing window from settings
            gestureInputManager.setTimingWindow(settings.timerSpeed)
            // Set timer combos (always available)
            gestureInputManager.setDecrementTimerCombo(
                settings.decrementTimerCombo
            )
            gestureInputManager.setIncrementTimerCombo(
                settings.incrementTimerCombo
            )
            // Set font size combos (always available)
            gestureInputManager.setFontSmallCombo(settings.fontSmallCombo)
            gestureInputManager.setFontMediumCombo(settings.fontMediumCombo)
            gestureInputManager.setFontBigCombo(settings.fontBigCombo)
            // In Settings menu, always allow editLayoutCombo to work (unless in edit actions mode)
            if !isEditActionsMode {
                gestureInputManager.setEditLayoutCombo(settings.editLayoutCombo)
            } else {
                gestureInputManager.setEditLayoutCombo(nil)
            }

            // Load menu combos directly without creating temporary positions
            gestureInputManager.loadMenuCombos(menuComboMap)

        case .eyeTrackingAccessible, .eyeTrackingSimple:
            // Legacy tabs use AAC
            setCurrentMenu(.aac)
        }
    }

    /// Assign a combo to a menu-specific action (Settings, Keyboard)
    /// Uses gesture pattern matching instead of object reference to avoid invalidated combo issues
    public func assignComboToMenu(
        _ combo: ActionCombo,
        menu: Tab,
        actionId: Int
    ) {
        let menuName: String
        switch menu {
        case .settings:
            menuName = "settings"
        case .keyboard:
            menuName = "keyboard"
        default:
            print(
                "⚠️ Cannot assign combo to menu \(menu). Only .settings and .keyboard are supported."
            )
            return
        }

        storeMenuCombo(
            combo,
            menuName: menuName,
            actionId: actionId,
            persist: true
        )
        print(
            "✅ Assigned combo \(combo.name) to \(menuName) menu action \(actionId)"
        )

        if currentMenu == menu {
            reloadCombosForCurrentMenu()
        }
    }

    /// Get combos for a specific menu
    public func getCombosForMenu(_ menu: Tab) -> [ActionCombo: Int] {
        guard let menuName = menuName(for: menu) else {
            return [:]
        }

        return menuCombos[menuName] ?? [:]
    }

    // MARK: - Menu Combo Persistence Helpers

    private func restoreMenuCombosFromStorage() {
        let assignments = settings.allMenuComboAssignments()
        guard !assignments.isEmpty else { return }

        for assignment in assignments {
            guard tab(for: assignment.menuName) != nil,
                let combo = dataManager.fetchActionCombo(id: assignment.comboId)
            else {
                continue
            }
            storeMenuCombo(
                combo,
                menuName: assignment.menuName,
                actionId: assignment.actionId,
                persist: false
            )
        }
    }

    private func storeMenuCombo(
        _ combo: ActionCombo,
        menuName: String,
        actionId: Int,
        persist: Bool
    ) {
        var mapping = menuCombos[menuName] ?? [:]
        for (existingCombo, id) in mapping where id == actionId {
            mapping.removeValue(forKey: existingCombo)
        }
        mapping[combo] = actionId
        menuCombos[menuName] = mapping

        if persist {
            settings.setMenuComboAssignment(
                menuName: menuName,
                actionId: actionId,
                comboId: combo.id
            )
        }
    }

    private func menuName(for menu: Tab) -> String? {
        switch menu {
        case .settings:
            return "settings"
        case .keyboard:
            return "keyboard"
        default:
            return nil
        }
    }

    private func tab(for menuName: String) -> Tab? {
        switch menuName {
        case "settings":
            return .settings
        case "keyboard":
            return .keyboard
        default:
            return nil
        }
    }

    // MARK: - Edit Actions Combo Management

    /// Generate combos for edit actions mode
    /// Action IDs: 0 = Edit Actions, 1-12 = gesture toggles, 13 = Cancel, 14 = Save
    /// Excludes priority combos used in InformationView (settings, delete, swap, changeColor, editLayout, timer combos, nav combos)
    public func generateEditActionsCombos() {
        // Get all available combos
        let allCombos = fetchAllActionCombos()
        guard !allCombos.isEmpty else {
            print("⚠️ No combos available for edit actions")
            return
        }

        // Get priority combos that should NOT be used for edit actions
        let navNext = settings.navNextCombo
        let navPrev = settings.navPrevCombo
        let settingsCombo = settings.settingsCombo
        let keyboardCombo = settings.keyboardCombo
        let editLayoutCombo = settings.editLayoutCombo
        let swapCombo = settings.swapCombo
        let deleteCombo = settings.deleteCombo
        let changeColorCombo = settings.changeColorCombo
        let decrementTimerCombo = settings.decrementTimerCombo
        let incrementTimerCombo = settings.incrementTimerCombo
        let fontSmallCombo = settings.fontSmallCombo
        let fontMediumCombo = settings.fontMediumCombo
        let fontBigCombo = settings.fontBigCombo

        // Filter out priority combos to avoid conflicts with InformationView
        let availableCombos = allCombos.filter { combo in
            let isNavNext =
                navNext != nil && combo.firstGesture == navNext!.0
                && combo.secondGesture == navNext!.1
            let isNavPrev =
                navPrev != nil && combo.firstGesture == navPrev!.0
                && combo.secondGesture == navPrev!.1
            let isSettings =
                settingsCombo != nil && combo.firstGesture == settingsCombo!.0
                && combo.secondGesture == settingsCombo!.1
            let isEditLayout =
                editLayoutCombo != nil
                && combo.firstGesture == editLayoutCombo!.0
                && combo.secondGesture == editLayoutCombo!.1
            let isSwap =
                swapCombo != nil && combo.firstGesture == swapCombo!.0
                && combo.secondGesture == swapCombo!.1
            let isDelete =
                deleteCombo != nil && combo.firstGesture == deleteCombo!.0
                && combo.secondGesture == deleteCombo!.1
            let isChangeColor =
                changeColorCombo != nil
                && combo.firstGesture == changeColorCombo!.0
                && combo.secondGesture == changeColorCombo!.1
            let isDecrementTimer =
                decrementTimerCombo != nil
                && combo.firstGesture == decrementTimerCombo!.0
                && combo.secondGesture == decrementTimerCombo!.1
            let isIncrementTimer =
                incrementTimerCombo != nil
                && combo.firstGesture == incrementTimerCombo!.0
                && combo.secondGesture == incrementTimerCombo!.1
            let isFontSmall =
                fontSmallCombo != nil && combo.firstGesture == fontSmallCombo!.0
                && combo.secondGesture == fontSmallCombo!.1
            let isFontMedium =
                fontMediumCombo != nil
                && combo.firstGesture == fontMediumCombo!.0
                && combo.secondGesture == fontMediumCombo!.1
            let isFontBig =
                fontBigCombo != nil && combo.firstGesture == fontBigCombo!.0
                && combo.secondGesture == fontBigCombo!.1
            let isKeyboard =
                keyboardCombo != nil && combo.firstGesture == keyboardCombo!.0
                && combo.secondGesture == keyboardCombo!.1

            return !isNavNext && !isNavPrev && !isSettings && !isEditLayout
                && !isSwap && !isDelete && !isChangeColor && !isDecrementTimer
                && !isIncrementTimer && !isFontSmall && !isFontMedium
                && !isFontBig && !isKeyboard
        }

        guard !availableCombos.isEmpty else {
            print("⚠️ No available combos after filtering priority combos")
            return
        }

        // Clear existing settings menu combos
        menuCombos["settings"] = [:]

        var comboIndex = 0
        let maxCombos = availableCombos.count

        // Action ID 0: Edit Actions (to enter edit mode)
        if comboIndex < maxCombos {
            let combo = availableCombos[comboIndex]
            assignComboToMenu(combo, menu: .settings, actionId: 0)
            comboIndex += 1
        }

        // Action IDs 1-12: Gesture toggles (one per gesture)
        let gestures = fetchAllUserGestures().sorted { $0.order < $1.order }
        for (index, _) in gestures.enumerated() {
            if comboIndex < maxCombos {
                let combo = availableCombos[comboIndex]
                assignComboToMenu(combo, menu: .settings, actionId: index + 1)
                comboIndex += 1
            }
        }

        // Action ID 13: Cancel
        if comboIndex < maxCombos {
            let combo = availableCombos[comboIndex]
            assignComboToMenu(combo, menu: .settings, actionId: 13)
            comboIndex += 1
        }

        // Action ID 14: Save
        if comboIndex < maxCombos {
            let combo = availableCombos[comboIndex]
            assignComboToMenu(combo, menu: .settings, actionId: 14)
        }

        print(
            "✅ Generated edit actions combos (excluded \(allCombos.count - availableCombos.count) priority combos)"
        )
    }

    /// Regenerate combos after saving gesture changes
    public func regenerateCombosForEditActions() {
        // Regenerate all combos based on enabled gestures (similar to onboarding)
        let enabledDescriptor = FetchDescriptor<UserGesture>(
            predicate: #Predicate { $0.isEnabled == true }
        )
        let enabled = (try? modelContext.fetch(enabledDescriptor)) ?? []

        let selected = Set(enabled.map { $0.gestureType })
        let supportedSelected: [GestureType] = Array(selected)

        guard !supportedSelected.isEmpty else { return }

        // Dynamically resize grid based on enabled gestures (mirrors onboarding logic).
        let gestureCount = supportedSelected.count
        let desiredDimensions: (rows: Int, columns: Int)
        if gestureCount >= 7 {
            desiredDimensions = (5, 5)
        } else if gestureCount >= 5 {
            desiredDimensions = (4, 4)
        } else {
            desiredDimensions = (3, 3)
        }

        let desiredRows = desiredDimensions.rows
        let desiredColumns = desiredDimensions.columns
        let desiredPageSize = max(1, desiredRows * desiredColumns)

        if rows != desiredRows || columns != desiredColumns {
            rows = desiredRows
            columns = desiredColumns
        }

        if settings.gridRows != desiredRows {
            settings.gridRows = desiredRows
        }
        if settings.gridColumns != desiredColumns {
            settings.gridColumns = desiredColumns
        }

        let positionDescriptor = FetchDescriptor<GridPosition>(
            sortBy: [SortDescriptor(\.order)]
        )
        let existingPositions =
            (try? modelContext.fetch(positionDescriptor)) ?? []
        let pageCount = max(
            1,
            Int(
                ceil(
                    Double(existingPositions.count)
                        / Double(desiredPageSize)
                )
            )
        )
        let newTotalPositions = pageCount * desiredPageSize
        if existingPositions.count != newTotalPositions {
            try? dataManager.resizeGrid(newTotal: newTotalPositions)
        }
        let currentPositions =
            ((try? modelContext.fetch(positionDescriptor))
                ?? [])

        // Clear current grid combo references to avoid invalidated objects.
        if !currentPositions.isEmpty {
            for position in currentPositions {
                position.actionCombo = nil
            }
            try? modelContext.save()
        }

        // Clear menu combos BEFORE deleting old combos to avoid invalidated references
        menuCombos["settings"] = [:]

        // Delete existing combos
        let existingCombos =
            (try? modelContext.fetch(FetchDescriptor<ActionCombo>())) ?? []
        for combo in existingCombos { modelContext.delete(combo) }
        try? modelContext.save()

        // Build new combos
        func makeName(_ a: GestureType, _ b: GestureType) -> String {
            "\(a.rawValue) + \(b.rawValue)"
        }
        var combos: [ActionCombo] = []

        // Prioritize navigation pairs
        if supportedSelected.contains(.lookLeft)
            && supportedSelected.contains(.lookRight)
        {
            combos.append(
                ActionCombo(
                    name: makeName(.lookLeft, .lookRight),
                    firstGesture: .lookLeft,
                    secondGesture: .lookRight
                )
            )
            combos.append(
                ActionCombo(
                    name: makeName(.lookRight, .lookLeft),
                    firstGesture: .lookRight,
                    secondGesture: .lookLeft
                )
            )
        }
        if supportedSelected.contains(.lookUp)
            && supportedSelected.contains(.lookDown)
        {
            combos.append(
                ActionCombo(
                    name: makeName(.lookUp, .lookDown),
                    firstGesture: .lookUp,
                    secondGesture: .lookDown
                )
            )
            combos.append(
                ActionCombo(
                    name: makeName(.lookDown, .lookUp),
                    firstGesture: .lookDown,
                    secondGesture: .lookUp
                )
            )
        }

        // Fill remaining ordered pairs
        for first in supportedSelected {
            for second in supportedSelected where first != second {
                if combos.contains(where: {
                    $0.firstGesture == first && $0.secondGesture == second
                }) {
                    continue
                }
                combos.append(
                    ActionCombo(
                        name: makeName(first, second),
                        firstGesture: first,
                        secondGesture: second
                    )
                )
            }
        }

        // Insert combos
        for combo in combos { modelContext.insert(combo) }
        try? modelContext.save()

        func comboKey(_ first: GestureType, _ second: GestureType) -> String {
            "\(first.rawValue)|\(second.rawValue)"
        }
        func comboKey(_ pair: (GestureType, GestureType)) -> String {
            comboKey(pair.0, pair.1)
        }

        // Determine priority combos similar to onboarding flow.
        var navNext: (GestureType, GestureType)?
        var navPrev: (GestureType, GestureType)?
        if supportedSelected.contains(.lookLeft)
            && supportedSelected.contains(.lookRight)
        {
            navNext = (.lookLeft, .lookRight)
            navPrev = (.lookRight, .lookLeft)
        } else if supportedSelected.contains(.lookUp)
            && supportedSelected.contains(.lookDown)
        {
            navNext = (.lookUp, .lookDown)
            navPrev = (.lookDown, .lookUp)
        }
        if navNext == nil, let c = combos.first {
            navNext = (c.firstGesture, c.secondGesture)
        }
        if navPrev == nil, let c = combos.dropFirst().first {
            navPrev = (c.firstGesture, c.secondGesture)
        }

        settings.navNextCombo = navNext
        settings.navPrevCombo = navPrev

        var reservedPairs = Set<String>()
        if let navNext { reservedPairs.insert(comboKey(navNext)) }
        if let navPrev { reservedPairs.insert(comboKey(navPrev)) }

        func nextPriorityCombo() -> (GestureType, GestureType)? {
            for combo in combos {
                let pair = (combo.firstGesture, combo.secondGesture)
                let key = comboKey(pair)
                if !reservedPairs.contains(key) {
                    reservedPairs.insert(key)
                    return pair
                }
            }
            return nil
        }

        settings.settingsCombo = nextPriorityCombo()
        settings.keyboardCombo = nextPriorityCombo()
        settings.editLayoutCombo = nextPriorityCombo()
        settings.swapCombo = nextPriorityCombo()
        settings.deleteCombo = nextPriorityCombo()
        settings.decrementTimerCombo = nextPriorityCombo()
        settings.incrementTimerCombo = nextPriorityCombo()
        settings.changeColorCombo = nextPriorityCombo()

        // Assign remaining combos to grid positions (per-slot template replicated across pages).
        let assignmentOrder = combos.filter { combo in
            let key = comboKey(combo.firstGesture, combo.secondGesture)
            return !reservedPairs.contains(key)
        }

        if !currentPositions.isEmpty {
            let itemsPerPage = max(1, pageSize)
            for (index, position) in currentPositions.enumerated() {
                let slotIndex = index % itemsPerPage
                if slotIndex < assignmentOrder.count {
                    position.actionCombo = assignmentOrder[slotIndex]
                } else {
                    position.actionCombo = nil
                }
            }
            try? modelContext.save()
        }

        // keep AAC grid inputs in sync immediately
        sanitizeNavigationComboConflicts()
        if isGestureMode {
            gestureInputManager.loadCombosTemplate(
                from: positions,
                pageSize: pageSize
            )
        }

        // Small delay to ensure SwiftData has fully processed the deletions/insertions
        // This helps avoid accessing invalidated combos
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Regenerate edit actions combos with new combos (this will rebuild menuCombos)
            self.generateEditActionsCombos()

            self.sanitizeNavigationComboConflicts()
            if self.isGestureMode {
                self.gestureInputManager.loadCombosTemplate(
                    from: self.positions,
                    pageSize: self.pageSize
                )
            }

            // Reload combos for current menu
            self.reloadCombosForCurrentMenu()
        }
    }
}
