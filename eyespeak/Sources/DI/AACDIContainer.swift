//
//  AACDIContainer.swift
//  eyespeak
//
//  Created by Dwiki on 22/10/25.
//

import Foundation
import SwiftData

/**
 * AACDIContainer - Dependency Injection Container for AAC Module
 *
 * This container manages all dependencies for the AAC (Augmentative and Alternative Communication) module,
 * providing a centralized way to create and manage ViewModels, Managers, and other dependencies.
 *
 * ## Features:
 * - Singleton pattern for shared access
 * - Lazy initialization of shared managers
 * - Factory methods for creating new instances
 * - Dependency resolution for complex views
 * - Preview support for SwiftUI previews
 *
 * ## Usage Examples:
 *
 * ```swift
 * // Create ViewModels
 * let container = AACDIContainer.shared
 * let aacViewModel = container.makeAACViewModel()
 * let onboardingViewModel = container.makeOnboardingViewModel()
 *
 * // Create Views with DI
 * let aacView = AACView(container: container)
 *
 * // Access shared managers
 * let dataManager = container.dataManager
 * let gestureManager = container.gestureInputManager
 * ```
 */
public final class AACDIContainer {
    
    // MARK: - Singleton
    public static let shared = AACDIContainer()
    
    private let injectedModelContext: ModelContext?
    
    /// Default initializer uses the shared persistent container
    private init() {
        self.injectedModelContext = nil
    }
    
    /// Designated initializer for previews/tests to inject a custom ModelContext
    public init(modelContext: ModelContext) {
        self.injectedModelContext = modelContext
    }
    
    // MARK: - Core Dependencies
    @MainActor
    public static var modelContext: ModelContext {
        ModelContainer.shared.mainContext
    }
    
    /// Resolves to injected context if provided, otherwise falls back to shared
    @MainActor
    private var resolvedModelContext: ModelContext {
        injectedModelContext ?? ModelContainer.shared.mainContext
    }
    
    // MARK: - Lazy Singletons for Managers
    @MainActor
    private lazy var _dataManager: DataManager = {
        DataManager(modelContext: resolvedModelContext)
    }()
    
    private lazy var _gestureInputManager: GestureInputManager = {
        GestureInputManager()
    }()
    
    @MainActor
    private lazy var _speechService: SpeechService = {
        SpeechService.shared
    }()
    
    // MARK: - Manager Factories
    
    /// Creates a new DataManager instance
    @MainActor
    public func makeDataManager() -> DataManager {
        DataManager(modelContext: resolvedModelContext)
    }
    
    /// Creates a new GestureInputManager instance
    @MainActor
    public func makeGestureInputManager() -> GestureInputManager {
        GestureInputManager()
    }
    
    @MainActor
    public func makeSpeechService() -> SpeechService {
        SpeechService.shared
    }
    
    /// Gets the shared DataManager instance
    @MainActor
    public var dataManager: DataManager {
        return _dataManager
    }
    
    /// Gets the shared GestureInputManager instance
    @MainActor
    public var gestureInputManager: GestureInputManager {
        return _gestureInputManager
    }
    
    @MainActor
    public var speechService: SpeechService {
        return _speechService
    }
    
    // MARK: - ViewModel Factories
    
    /// Creates a new AACViewModel instance
    @MainActor
    public func makeAACViewModel() -> AACViewModel {
        AACViewModel(
            modelContext: resolvedModelContext,
            dataManager: makeDataManager(),
            gestureInputManager: makeGestureInputManager(),
            speechService: makeSpeechService()
        )
    }
    
    /// Creates a new OnboardingViewModel instance
    @MainActor
    public func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            modelContext: resolvedModelContext,
            dataManager: makeDataManager()
        )
    }
    
    // MARK: - Dependency Resolution
    
    /// Resolves all dependencies for AACView
    @MainActor
    public func resolveAACDependencies() -> (
        modelContext: ModelContext,
        dataManager: DataManager,
        gestureInputManager: GestureInputManager,
        speechService: SpeechService
    ) {
        return (
            modelContext: resolvedModelContext,
            dataManager: makeDataManager(),
            gestureInputManager: makeGestureInputManager(),
            speechService: makeSpeechService()
        )
    }
    
    /// Resolves all dependencies for OnboardingView
    @MainActor
    public func resolveOnboardingDependencies() -> (
        modelContext: ModelContext,
        dataManager: DataManager
    ) {
        return (
            modelContext: resolvedModelContext,
            dataManager: makeDataManager()
        )
    }
    
    // MARK: - Preview Support
    
    /// Creates a preview container for SwiftUI previews
    @MainActor
    public static func makePreviewContainer() -> ModelContainer {
        return ModelContainer.preview
    }
    
    /// Creates a preview container with specific grid size
    @MainActor
    public static func makePreviewContainer(gridSize: Int) -> ModelContainer {
        return ModelContainer.preview(gridSize: gridSize)
    }
    
    /// Helper to build a DI container bound to a specific preview ModelContainer
    @MainActor
    public static func makePreviewDI(modelContainer: ModelContainer) -> AACDIContainer {
        AACDIContainer(modelContext: modelContainer.mainContext)
    }
}
