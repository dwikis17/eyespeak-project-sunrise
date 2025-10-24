//
//  AppStateManager.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//
import Foundation
import SwiftData

@MainActor
@Observable
public class AppStateManager {
    var currentTab: Tab = .keyboard
    let settings = UserSettings()
    var hasCompletedOnboarding = false
    var showOnboarding = false
    
    func checkOnboardingStatus(modelContext: ModelContext) {
        // Check if user has any enabled gestures (indicates onboarding completion)
        let descriptor = FetchDescriptor<UserGesture>(
            predicate: #Predicate { $0.isEnabled == true }
        )
        
        if let enabledGestures = try? modelContext.fetch(descriptor) {
            hasCompletedOnboarding = !enabledGestures.isEmpty
            showOnboarding = !hasCompletedOnboarding
            print("Onboarding status - Completed: \(hasCompletedOnboarding), Show: \(showOnboarding), Enabled gestures: \(enabledGestures.count)")
        } else {
            // If we can't fetch, assume onboarding is needed
            showOnboarding = true
            print("Onboarding status - Error fetching gestures, showing onboarding")
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        showOnboarding = false
    }
    
    // For testing purposes - reset onboarding
    func resetOnboarding() {
        hasCompletedOnboarding = false
        showOnboarding = true
    }
}
