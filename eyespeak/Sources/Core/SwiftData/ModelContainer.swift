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
            SampleData.populate(context: context)  // 3x3 grid
            
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
