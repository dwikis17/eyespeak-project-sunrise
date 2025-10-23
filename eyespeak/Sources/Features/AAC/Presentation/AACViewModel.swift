//
//  AACViewModel.swift
//  eyespeak
//
//  Created by Dwiki on 22/10/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
public final class AACViewModel: ObservableObject {
    public let modelContext: ModelContext
    public let dataManager: DataManager
    public let gestureInputManager: GestureInputManager
    
    // MARK: - UI State Properties
    public var columns: Int = 5
    public var showingSettings = false
    public var isGestureMode = false
    public var selectedPosition: GridPosition?
    
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

    init(
        modelContext: ModelContext,
        dataManager: DataManager,
        gestureInputManager: GestureInputManager
    ) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        self.gestureInputManager = gestureInputManager
        setupGestureManager()
    }
    
    // MARK: - Convenience Initializer for Backward Compatibility
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        self.gestureInputManager = GestureInputManager()
        setupGestureManager()
    }
    
    // MARK: - Setup Methods
    
    private func setupGestureManager() {
        gestureInputManager.onComboMatched = { [weak self] combo, position in
            self?.handleComboMatched(combo: combo, position: position)
        }
    }
    
    public func setupManagers() {
        // Initialize grid if empty
        if positions.isEmpty {
            try? dataManager.initializeGrid(totalPositions: 9) // 3x3 default
        }
    }
    
    // MARK: - Gesture Mode Methods
    
    public func toggleGestureMode() {
        withAnimation {
            isGestureMode.toggle()
            if isGestureMode {
                gestureInputManager.loadCombos(from: positions)
            } else {
                gestureInputManager.reset()
            }
        }
    }
    
    public func resetGestureMode() {
        withAnimation {
            isGestureMode = false
            gestureInputManager.reset()
        }
    }
    
    // MARK: - Settings Methods
    
    public func showSettings() {
        showingSettings = true
    }
    
    public func hideSettings() {
        showingSettings = false
    }
    
    // MARK: - Grid Methods
    
    public func setColumns(_ newColumns: Int) {
        columns = newColumns
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
            print("🗣️ Speaking: \(card.title)")
            // TODO: Add text-to-speech here
        }
        
        // Reset highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation {
                self?.selectedPosition = nil
            }
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
    }
    
    public func assignComboToPosition(_ combo: ActionCombo, position: GridPosition) {
        try? dataManager.assignComboToPosition(combo, position: position)
    }
    
    public func fetchPosition(at index: Int) -> GridPosition? {
        return dataManager.fetchPosition(at: index)
    }
    
    public func resizeGrid(newTotal: Int) {
        try? dataManager.resizeGrid(newTotal: newTotal)
    }
    
    // MARK: - Card Interaction Methods
    
    public func handleCardTap(for card: AACard) {
        // Increment usage
        incrementCardUsage(card)
        
        // Speak the card title
        print("🗣️ Speaking: \(card.title)")
        // TODO: Add text-to-speech here
        
        // You could also add haptic feedback here
        // let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        // impactFeedback.impactOccurred()
    }
}
