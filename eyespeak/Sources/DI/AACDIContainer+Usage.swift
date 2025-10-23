//
//  AACDIContainer+Usage.swift
//  eyespeak
//
//  Created by Dwiki on 22/10/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Usage Examples for AACDIContainer

extension AACDIContainer {
    
    /// Example: How to use the DI container in your views
    @MainActor static func usageExamples() {
        let container = AACDIContainer.shared
        
        // MARK: - 1. Creating ViewModels with DI
        
        // Method 1: Using the container directly
        let aacViewModel = container.makeAACViewModel()
        let onboardingViewModel = container.makeOnboardingViewModel()
        
        // Method 2: Using shared instances for managers
        let dataManager = container.dataManager
        let gestureManager = container.gestureInputManager
        
        // MARK: - 2. Creating Views with DI
        
        // Method 1: Using the container initializer
        let aacView = AACView(container: container)
        
        // Method 2: Using the traditional modelContext initializer (still works)
        let modelContext = AACDIContainer.modelContext
        let aacViewWithContext = AACView()
        
        // MARK: - 3. Resolving Dependencies for Complex Views
        
        let dependencies = container.resolveAACDependencies()
        // Use dependencies.modelContext, dependencies.dataManager, dependencies.gestureInputManager
        
        // MARK: - 4. Preview Support
        
        let previewContainer = AACDIContainer.makePreviewContainer()
        let previewContainerWithGrid = AACDIContainer.makePreviewContainer(gridSize: 4)
    }
}

// MARK: - Example View using DI Container

struct ExampleAACView: View {
    @StateObject private var viewModel: AACViewModel
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        _viewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }
    
    var body: some View {
        VStack {
            Text("AAC View with DI")
            // Your view content here
        }
    }
}

// MARK: - Example View with Manual Dependency Injection

struct ExampleManualDIView: View {
    private let dataManager: DataManager
    private let gestureManager: GestureInputManager
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        self.dataManager = container.makeDataManager()
        self.gestureManager = container.makeGestureInputManager()
    }
    
    var body: some View {
        VStack {
            Text("Manual DI View")
            // Use dataManager and gestureManager directly
        }
    }
}

// MARK: - Example Preview with DI

#Preview("AAC View with DI") {
    ExampleAACView()
        .modelContainer(AACDIContainer.makePreviewContainer())
}

#Preview("Manual DI View") {
    ExampleManualDIView()
        .modelContainer(AACDIContainer.makePreviewContainer())
}
