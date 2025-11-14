//
//  DataManager.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import Foundation
import SwiftData
import Observation

@Observable
public final class DataManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    
    func createActionCombo(
        name: String,
        firstGesture: GestureType,
        secondGesture: GestureType
    ) throws -> ActionCombo {
        
        // Check for duplicates (order matters)
        if isDuplicateCombo(first: firstGesture, second: secondGesture) {
            throw DataError.duplicateCombo
        }
        
        let combo = ActionCombo(
            name: name,
            firstGesture: firstGesture,
            secondGesture: secondGesture
        )
        
        modelContext.insert(combo)
        try modelContext.save()
        
        return combo
    }
    
    func isDuplicateCombo(first: GestureType, second: GestureType) -> Bool {
        let descriptor = FetchDescriptor<ActionCombo>()
        
        guard let allCombos = try? modelContext.fetch(descriptor) else {
            return false
        }
        
        // Order matters: lookLeft→lookRight is different from lookRight→lookLeft
        return allCombos.contains { combo in
            combo.firstGesture == first && combo.secondGesture == second
        }
    }
    
    func fetchAllActionCombos() -> [ActionCombo] {
        let descriptor = FetchDescriptor<ActionCombo>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchActionCombo(id: UUID) -> ActionCombo? {
        var descriptor = FetchDescriptor<ActionCombo>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    func fetchAllUserGestures() -> [UserGesture] {
        let descriptor = FetchDescriptor<UserGesture>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func updateUserGesture(userGesture: UserGesture, isEnabled: Bool) throws {
        userGesture.isEnabled = isEnabled
        try modelContext.save()
    }
    
    func deleteActionCombo(_ combo: ActionCombo) throws {
        modelContext.delete(combo)
        try modelContext.save()
    }
    
    // MARK: - AACard Methods
    
    func createCard(title: String, imageData: Data?) throws -> AACard {
        let card = AACard(title: title, imageData: imageData)
        modelContext.insert(card)
        try modelContext.save()
        return card
    }
    
    func fetchAllCards() -> [AACard] {
        let descriptor = FetchDescriptor<AACard>(
            sortBy: [SortDescriptor(\.title)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func incrementCardUsage(_ card: AACard) throws {
        card.timesPressed += 1
        try modelContext.save()
    }
    
    func deleteCard(_ card: AACard) throws {
        modelContext.delete(card)
        try modelContext.save()
    }
    
    // MARK: - GridPosition Methods
    
    func createGridPosition(index: Int) throws -> GridPosition {
        let position = GridPosition(order: index)
        modelContext.insert(position)
        try modelContext.save()
        return position
    }
    
    func assignCardToPosition(_ card: AACard, position: GridPosition) throws {
        position.card = card
        try modelContext.save()
    }
    
    func assignComboToPosition(_ combo: ActionCombo, position: GridPosition) throws {
        position.actionCombo = combo
        try modelContext.save()
    }
    
    func fetchAllGridPositions() -> [GridPosition] {
        let descriptor = FetchDescriptor<GridPosition>(
            sortBy: [SortDescriptor(\.order)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchPosition(at index: Int) -> GridPosition? {
        var descriptor = FetchDescriptor<GridPosition>(
            predicate: #Predicate { $0.order == index }
        )
        descriptor.fetchLimit = 1
        
        return try? modelContext.fetch(descriptor).first
    }
    
    func initializeGrid(totalPositions: Int) throws {
        // Check if grid already exists
        let existing = fetchAllGridPositions()
        guard existing.isEmpty else { return }
        
        // Create grid positions (0 to totalPositions-1)
        for index in 0..<totalPositions {
            let position = GridPosition(order: index)
            modelContext.insert(position)
        }
        
        try modelContext.save()
    }
    
    func resizeGrid(newTotal: Int) throws {
        let existing = fetchAllGridPositions()
        let currentTotal = existing.count
        
        if newTotal > currentTotal {
            // Add new positions
            for index in currentTotal..<newTotal {
                let position = GridPosition(order: index)
                modelContext.insert(position)
            }
        } else if newTotal < currentTotal {
            // Remove excess positions (from the end)
            let positionsToRemove = existing.suffix(currentTotal - newTotal)
            for position in positionsToRemove {
                modelContext.delete(position)
            }
        }
        
        try modelContext.save()
    }
    
    // Helper to calculate row/column from index
    func gridCoordinates(for index: Int, columns: Int) -> (row: Int, column: Int) {
        let row = index / columns
        let column = index % columns
        return (row, column)
    }
    
    // Helper to calculate index from row/column
    func gridIndex(row: Int, column: Int, columns: Int) -> Int {
        return row * columns + column
    }
}

// MARK: - Errors

enum DataError: LocalizedError {
    case duplicateCombo
    case cardNotFound
    case positionNotFound
    
    var errorDescription: String? {
        switch self {
        case .duplicateCombo:
            return "This gesture combination already exists"
        case .cardNotFound:
            return "Card not found"
        case .positionNotFound:
            return "Grid position not found"
        }
    }
}
