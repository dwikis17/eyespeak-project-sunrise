//
//  ModelContainer+Extension.swift
//  eyespeak
//

import Foundation
import SwiftData

extension ModelContainer {
    
    /// Shared container for the entire app
    @MainActor
    static var shared: ModelContainer = {
        let schema = Schema([
            AACard.self,
            ActionCombo.self,
            GridPosition.self,
            UserGesture.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Initialize UserGestures and sample data on first launch
            let context = container.mainContext
            initializeUserGesturesIfNeeded(context: context)
            initializeSampleDataIfNeeded(context: context)
            // Ensure no initial grid combos clash with navigation combos
            sanitizeNavigationComboConflicts(context: context)
            
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    /// Initialize UserGestures if they don't exist
    private static func initializeUserGesturesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<UserGesture>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            // Initialize all gesture types
            for (index, gestureType) in GestureType.allCases.enumerated() {
                let userGesture = UserGesture(
                    gestureType: gestureType,
                    isEnabled: false,
                    order: index
                )
                context.insert(userGesture)
            }
            
            try? context.save()
            print("Initialized UserGestures on first launch")
        }
    }
    
    /// Initialize sample data if it doesn't exist
    private static func initializeSampleDataIfNeeded(context: ModelContext) {
        // Check if we already have sample data
        let cardDescriptor = FetchDescriptor<AACard>()
        let existingCards = (try? context.fetch(cardDescriptor)) ?? []
        
        if existingCards.isEmpty {
            // Add sample data using the existing SampleData.populate method
            SampleData.populate(context: context)
            print("Initialized sample data on first launch")
        }
    }
    
    /// Replace any grid `ActionCombo` that matches navigation combos so that
    /// navigation gestures do not overlap with card activation combos.
    private static func sanitizeNavigationComboConflicts(context: ModelContext) {
        let settings = UserSettings()
        let navNext = settings.navNextCombo
        let navPrev = settings.navPrevCombo
        let settingsCombo = settings.settingsCombo
        let editLayoutCombo = settings.editLayoutCombo
        let swapCombo = settings.swapCombo
        guard navNext != nil || navPrev != nil || settingsCombo != nil || editLayoutCombo != nil || swapCombo != nil else { return }

        func isNavCombo(_ c: ActionCombo) -> Bool {
            if let n = navNext, c.firstGesture == n.0 && c.secondGesture == n.1 { return true }
            if let p = navPrev, c.firstGesture == p.0 && c.secondGesture == p.1 { return true }
            if let s = settingsCombo, c.firstGesture == s.0 && c.secondGesture == s.1 { return true }
            if let e = editLayoutCombo, c.firstGesture == e.0 && c.secondGesture == e.1 { return true }
            if let sw = swapCombo, c.firstGesture == sw.0 && c.secondGesture == sw.1 { return true }
            return false
        }

        // Fetch data
        let posDescriptor = FetchDescriptor<GridPosition>(sortBy: [SortDescriptor(\.order)])
        let allPositions = (try? context.fetch(posDescriptor)) ?? []
        let comboDescriptor = FetchDescriptor<ActionCombo>()
        let allCombos = (try? context.fetch(comboDescriptor)) ?? []
        var candidates = allCombos.filter { !isNavCombo($0) }

        // Work only on first page to ensure it's fully actionable
        // We infer the page size from the smallest square >= first page count; fallback to 16
        let pageSize = max(1, Int(min(16, allPositions.count)))
        let firstPageEnd = min(pageSize, allPositions.count)

        // Track used combos on the first page
        var usedFirstPage = Set<String>()
        if firstPageEnd > 0 {
            for i in 0..<firstPageEnd {
                if let c = allPositions[i].actionCombo, !isNavCombo(c) {
                    usedFirstPage.insert("\(c.firstGesture.rawValue)|\(c.secondGesture.rawValue)")
                }
            }
        }

        var changed = false
        if firstPageEnd > 0 {
            for i in 0..<firstPageEnd {
                guard let c = allPositions[i].actionCombo else { continue }
                if isNavCombo(c) {
                    if let replacement = candidates.first(where: { cand in
                        let key = "\(cand.firstGesture.rawValue)|\(cand.secondGesture.rawValue)"
                        return !usedFirstPage.contains(key)
                    }) {
                        allPositions[i].actionCombo = replacement
                        usedFirstPage.insert("\(replacement.firstGesture.rawValue)|\(replacement.secondGesture.rawValue)")
                        changed = true
                    } else {
                        allPositions[i].actionCombo = nil
                        changed = true
                    }
                }
            }
        }

        if changed { try? context.save() }
    }
    
    /// Preview container for SwiftUI previews (in-memory only)
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            AACard.self,
            ActionCombo.self,
            GridPosition.self,
            UserGesture.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Add sample data for previews
            let context = container.mainContext
            
            SampleData.populate(context: context)
            
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
    
    /// Preview container with different grid size
    @MainActor
    static func preview(gridSize: Int) -> ModelContainer {
        let schema = Schema([
            AACard.self,
            ActionCombo.self,
            GridPosition.self,
            UserGesture.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            let context = container.mainContext
            SampleData.populate(context: context, gridSize: gridSize)
            
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}
