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
    private let settings = UserSettings()
    
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
        if selectedGestures.contains(userGesture.id) {
            selectedGestures.remove(userGesture.id)
            userGesture.isEnabled = false
        } else {
            selectedGestures.insert(userGesture.id)
            userGesture.isEnabled = true
        }
    }
    
    func isGestureSelected(_ userGesture: UserGesture) -> Bool {
        return selectedGestures.contains(userGesture.id)
    }
    
    func canSelectMoreGestures() -> Bool { true }
    
    func getSelectedGestureCount() -> Int {
        return selectedGestures.count
    }
    
    func saveGestureSelection() async throws {
        // Configure grid size dynamically based on the number of enabled gestures (actions)
        // Assume 2 combos are reserved for navigation (next/prev page)
        let gesturesCount = selectedGestures.count
        let reservedForNavigation = 2
        let maxUsableCombos = max(0, gesturesCount * (gesturesCount - 1) - reservedForNavigation)

        // Fit the largest page size with no duplicates given the available unique ordered pairs
        if maxUsableCombos >= 25 { // enough for full 5x5
            settings.gridRows = 5
            settings.gridColumns = 5
        } else if maxUsableCombos >= 16 { // enough for 4x4
            settings.gridRows = 4
            settings.gridColumns = 4
        } else { // fallback to 3x3
            settings.gridRows = 3
            settings.gridColumns = 3
        }

        // Persist selection to model (sync selectedGestures → UserGesture.isEnabled)
        let descriptor = FetchDescriptor<UserGesture>()
        if let all = try? modelContext.fetch(descriptor) {
            let selectedIds = selectedGestures
            for ug in all {
                ug.isEnabled = selectedIds.contains(ug.id)
            }
            // Ensure blink is disabled regardless of selection
            for ug in all where ug.gestureType == .blink {
                ug.isEnabled = false
            }
        }

        // Rebuild ActionCombos from enabled gestures and assign to positions
        regenerateCombosFromEnabledGestures()

        try modelContext.save()
        print("Gesture selection saved successfully; grid set to \(settings.gridColumns)x\(settings.gridRows) and combos regenerated")
    }

    // MARK: - Combo Regeneration
    private func regenerateCombosFromEnabledGestures() {
        // Fetch enabled gestures
        let enabledDescriptor = FetchDescriptor<UserGesture>(
            predicate: #Predicate { $0.isEnabled == true }
        )
        let enabled = (try? modelContext.fetch(enabledDescriptor)) ?? []
    

        // Use the user's selected gestures, filtered to only supported ones (exclude blink/wink)
        let selected = Set(enabled.map { $0.gestureType })
        let supportedSelected: [GestureType] = Array(selected)
        
        print(supportedSelected, "SUPPORTED_SELECTED")

        guard !supportedSelected.isEmpty else { return }

        // Delete existing combos
        let existingCombos = (try? modelContext.fetch(FetchDescriptor<ActionCombo>())) ?? []
        for combo in existingCombos { modelContext.delete(combo) }

        // Build new combos
        func makeName(_ a: GestureType, _ b: GestureType) -> String { "\(a.rawValue) + \(b.rawValue)" }
        var combos: [ActionCombo] = []

        // Prioritize navigation pairs
        if supportedSelected.contains(.lookLeft) && supportedSelected.contains(.lookRight) {
            combos.append(ActionCombo(name: makeName(.lookLeft, .lookRight), firstGesture: .lookLeft, secondGesture: .lookRight))
            combos.append(ActionCombo(name: makeName(.lookRight, .lookLeft), firstGesture: .lookRight, secondGesture: .lookLeft))
        }
        if supportedSelected.contains(.lookUp) && supportedSelected.contains(.lookDown) {
            combos.append(ActionCombo(name: makeName(.lookUp, .lookDown), firstGesture: .lookUp, secondGesture: .lookDown))
            combos.append(ActionCombo(name: makeName(.lookDown, .lookUp), firstGesture: .lookDown, secondGesture: .lookUp))
        }

        // Fill remaining ordered pairs
        for first in supportedSelected {
            for second in supportedSelected where first != second {
                if combos.contains(where: { $0.firstGesture == first && $0.secondGesture == second }) { continue }
                combos.append(ActionCombo(name: makeName(first, second), firstGesture: first, secondGesture: second))
            }
        }

        // Insert combos
        for combo in combos { modelContext.insert(combo) }

        // Assign combos without duplicates per page; leave overflow slots empty
        let positions = (try? modelContext.fetch(FetchDescriptor<GridPosition>(sortBy: [SortDescriptor(\.order)]))) ?? []
        guard !positions.isEmpty else { return }

        let pageSize = max(1, settings.gridRows * settings.gridColumns)

        let updatedPositions = (try? modelContext.fetch(FetchDescriptor<GridPosition>(sortBy: [SortDescriptor(\.order)]))) ?? []

        // Choose and store navigation combos based on selected gestures
        var navNext: (GestureType, GestureType)?
        var navPrev: (GestureType, GestureType)?
        if supportedSelected.contains(.lookLeft) && supportedSelected.contains(.lookRight) {
            navNext = (.lookLeft, .lookRight)
            navPrev = (.lookRight, .lookLeft)
        } else if supportedSelected.contains(.lookUp) && supportedSelected.contains(.lookDown) {
            navNext = (.lookUp, .lookDown)
            navPrev = (.lookDown, .lookUp)
        }
        // Fallback to first two distinct combos if directional pairs aren't available
        if navNext == nil, let c = combos.first {
            navNext = (c.firstGesture, c.secondGesture)
        }
        if navPrev == nil, let c = combos.dropFirst().first {
            navPrev = (c.firstGesture, c.secondGesture)
        }
        settings.navNextCombo = navNext
        settings.navPrevCombo = navPrev
        
        // Assign settings combo (priority 3) - use next available combo that's not nav
        var settingsCombo: (GestureType, GestureType)?
        for combo in combos {
            let isNavNext = navNext != nil && combo.firstGesture == navNext!.0 && combo.secondGesture == navNext!.1
            let isNavPrev = navPrev != nil && combo.firstGesture == navPrev!.0 && combo.secondGesture == navPrev!.1
            if !isNavNext && !isNavPrev {
                settingsCombo = (combo.firstGesture, combo.secondGesture)
                break
            }
        }
        // Fallback: if no combo found, use first combo that's not nav
        if settingsCombo == nil {
            if let firstNonNav = combos.first(where: { c in
                let isNavNext = navNext != nil && c.firstGesture == navNext!.0 && c.secondGesture == navNext!.1
                let isNavPrev = navPrev != nil && c.firstGesture == navPrev!.0 && c.secondGesture == navPrev!.1
                return !isNavNext && !isNavPrev
            }) {
                settingsCombo = (firstNonNav.firstGesture, firstNonNav.secondGesture)
            }
        }
        settings.settingsCombo = settingsCombo

        // Assign edit layout combo (priority 4) - use next available combo that's not nav or settings
        var editLayoutCombo: (GestureType, GestureType)?
        for combo in combos {
            let isNavNext = navNext != nil && combo.firstGesture == navNext!.0 && combo.secondGesture == navNext!.1
            let isNavPrev = navPrev != nil && combo.firstGesture == navPrev!.0 && combo.secondGesture == navPrev!.1
            let isSettings = settingsCombo != nil && combo.firstGesture == settingsCombo!.0 && combo.secondGesture == settingsCombo!.1
            if !isNavNext && !isNavPrev && !isSettings {
                editLayoutCombo = (combo.firstGesture, combo.secondGesture)
                break
            }
        }
        // Fallback: if no combo found, use first combo that's not nav or settings
        if editLayoutCombo == nil {
            if let firstNonPriority = combos.first(where: { c in
                let isNavNext = navNext != nil && c.firstGesture == navNext!.0 && c.secondGesture == navNext!.1
                let isNavPrev = navPrev != nil && c.firstGesture == navPrev!.0 && c.secondGesture == navPrev!.1
                let isSettings = settingsCombo != nil && c.firstGesture == settingsCombo!.0 && c.secondGesture == settingsCombo!.1
                return !isNavNext && !isNavPrev && !isSettings
            }) {
                editLayoutCombo = (firstNonPriority.firstGesture, firstNonPriority.secondGesture)
            }
        }
        settings.editLayoutCombo = editLayoutCombo

        // Assign swap combo (priority 5) - use next available combo that's not nav, settings, or edit layout
        var swapCombo: (GestureType, GestureType)?
        for combo in combos {
            let isNavNext = navNext != nil && combo.firstGesture == navNext!.0 && combo.secondGesture == navNext!.1
            let isNavPrev = navPrev != nil && combo.firstGesture == navPrev!.0 && combo.secondGesture == navPrev!.1
            let isSettings = settingsCombo != nil && combo.firstGesture == settingsCombo!.0 && combo.secondGesture == settingsCombo!.1
            let isEditLayout = editLayoutCombo != nil && combo.firstGesture == editLayoutCombo!.0 && combo.secondGesture == editLayoutCombo!.1
            if !isNavNext && !isNavPrev && !isSettings && !isEditLayout {
                swapCombo = (combo.firstGesture, combo.secondGesture)
                break
            }
        }
        // Fallback: if no combo found, use first combo that's not nav, settings, or edit layout
        if swapCombo == nil {
            if let firstNonPriority = combos.first(where: { c in
                let isNavNext = navNext != nil && c.firstGesture == navNext!.0 && c.secondGesture == navNext!.1
                let isNavPrev = navPrev != nil && c.firstGesture == navPrev!.0 && c.secondGesture == navPrev!.1
                let isSettings = settingsCombo != nil && c.firstGesture == settingsCombo!.0 && c.secondGesture == settingsCombo!.1
                let isEditLayout = editLayoutCombo != nil && c.firstGesture == editLayoutCombo!.0 && c.secondGesture == editLayoutCombo!.1
                return !isNavNext && !isNavPrev && !isSettings && !isEditLayout
            }) {
                swapCombo = (firstNonPriority.firstGesture, firstNonPriority.secondGesture)
            }
        }
        settings.swapCombo = swapCombo

        // Build assignment order, excluding priority combos (nav, settings, edit layout, and swap)
        var assignmentOrder = combos.filter { combo in
            let isNavNext = navNext != nil && combo.firstGesture == navNext!.0 && combo.secondGesture == navNext!.1
            let isNavPrev = navPrev != nil && combo.firstGesture == navPrev!.0 && combo.secondGesture == navPrev!.1
            let isSettings = settingsCombo != nil && combo.firstGesture == settingsCombo!.0 && combo.secondGesture == settingsCombo!.1
            let isEditLayout = editLayoutCombo != nil && combo.firstGesture == editLayoutCombo!.0 && combo.secondGesture == editLayoutCombo!.1
            let isSwap = swapCombo != nil && combo.firstGesture == swapCombo!.0 && combo.secondGesture == swapCombo!.1
            return !isNavNext && !isNavPrev && !isSettings && !isEditLayout && !isSwap
        }

        for (index, position) in updatedPositions.enumerated() {
            let slotInPage = index % pageSize
            if slotInPage < assignmentOrder.count {
                position.actionCombo = assignmentOrder[slotInPage]
            } else {
                position.actionCombo = nil
            }
        }
    }
    
    // MARK: - Private Methods
    // (UserGestures are now initialized in ModelContainer.shared)
}
