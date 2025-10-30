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

@Observable
public final class AACViewModel: ObservableObject {
    public let modelContext: ModelContext
    public let dataManager: DataManager
    public let gestureInputManager: GestureInputManager
    private let speechService: SpeechService
    
    // MARK: - UI State Properties
    public var columns: Int = 4
    public var rows: Int = 4
    public let settings = UserSettings()
    public var currentPage: Int = 0
    public var showingSettings = false
    public var isGestureMode = false
    public var selectedPosition: GridPosition?
    public var faceStatus = FaceStatus()
    public var isCalibrating = false
    public var lastDetectedGesture: GestureType?
    
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
            self?.handleComboMatched(combo: combo, slotIndex: slotIndex)
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
        if slotIndex == -1 { goToNextPage(); return }
        if slotIndex == -2 { goToPreviousPage(); return }

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
            gestureInputManager.loadCombosTemplate(from: positions, pageSize: pageSize)
        }
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
}
