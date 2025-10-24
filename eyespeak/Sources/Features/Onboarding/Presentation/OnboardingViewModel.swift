//
//  OnboardingViewModel.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import Foundation
import SwiftData

@Observable
public final class OnboardingViewModel {
    private let modelContext: ModelContext
    private let dataManager: DataManager
    
    // Published properties for UI
    var userGestures: [UserGesture] = []
    var selectedGestures: Set<UUID> = []
    var isLoading = false
    var errorMessage: String?

    init(
        modelContext: ModelContext,
        dataManager: DataManager
    ) {
        self.modelContext = modelContext
        self.dataManager = dataManager
    }
    
    // MARK: - Convenience Initializer for Backward Compatibility
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    func loadUserGestures() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all user gestures (they should already be initialized by ModelContainer)
            userGestures = dataManager.fetchAllUserGestures()
            print("Loaded UserGestures:", userGestures.count)
            
            // Pre-select first 4 gestures as default
            let firstFour = Array(userGestures.prefix(4))
            selectedGestures = Set(firstFour.map { $0.id })
            
        } catch {
            errorMessage = "Failed to load gestures: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleGestureSelection(_ userGesture: UserGesture) {
        userGesture.isEnabled.toggle()
    }
    
    func isGestureSelected(_ userGesture: UserGesture) -> Bool {
        return selectedGestures.contains(userGesture.id)
    }
    
    func canSelectMoreGestures() -> Bool {
        return selectedGestures.count < 4
    }
    
    func getSelectedGestureCount() -> Int {
        return selectedGestures.count
    }
    
    func saveGestureSelection() async throws {
        // Since we're updating the model immediately on each tap,
        // this method now just ensures all changes are saved
        try modelContext.save()
        print("Gesture selection saved successfully")
    }
    
    // MARK: - Private Methods
    // (UserGestures are now initialized in ModelContainer.shared)
}
