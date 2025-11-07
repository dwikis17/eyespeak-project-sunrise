//
//  GestureInputManager.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import Foundation
import Observation

    @Observable
    public final class GestureInputManager {
        // Current gesture sequence
        private(set) var gestureSequence: [GestureType] = []
        private(set) var lastGesture: GestureType?
        
        // Timestamp of last gesture
        private var lastGestureTime: Date?
        
        // Timing window (how long between gestures)
        var timingWindow: TimeInterval = 2.0
        
        // Matched combo callback (page-relative by slot index)
        var onComboMatchedBySlot: ((ActionCombo, Int) -> Void)?
        
        // Available combos mapped to slot index within a page (0-based)
        private var availableCombosBySlot: [ActionCombo: Int] = [:]
        
        // Optional high-priority navigation combos (prev/next page)
        private var navNext: (GestureType, GestureType)?
        private var navPrev: (GestureType, GestureType)?
        // Settings combo (priority 3)
        private var settingsCombo: (GestureType, GestureType)?
        // Edit Layout combo (priority 4)
        private var editLayoutCombo: (GestureType, GestureType)?
        // Swap combo (priority 5)
        private var swapCombo: (GestureType, GestureType)?
        
        // MARK: - Public Methods
        
        /// Register a gesture input
        func registerGesture(_ gesture: GestureType) {
            let now = Date()
            lastGesture = gesture
            
            // Check if previous gesture timed out
            if let lastTime = lastGestureTime,
               now.timeIntervalSince(lastTime) > timingWindow {
                // Reset if too much time passed
                gestureSequence.removeAll()
            }
            
            // Add gesture to sequence (limit to two most recent)
            gestureSequence.append(gesture)
            if gestureSequence.count > 2 {
                gestureSequence = Array(gestureSequence.suffix(2))
            }
            lastGestureTime = now
            
            print("📍 Gesture registered: \(gesture.rawValue)")
            print("📊 Current sequence: \(gestureSequence.map { $0.rawValue })")
            
            // Check for matches after we have 2 gestures
            if gestureSequence.count >= 2 {
                print("checking for match")
                checkForMatch()
            }
            
            // Auto-clear after timing window
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timingWindow * 1_000_000_000))
                if gestureSequence.count > 0 && Date().timeIntervalSince(lastGestureTime ?? now) >= timingWindow {
                    reset()
                }
            }
        }
        
        /// Load available combos template from the first page's positions.
        /// Only the first `pageSize` positions are considered the template for mapping combos → slot index.
        func loadCombosTemplate(from positions: [GridPosition], pageSize: Int) {
            availableCombosBySlot.removeAll()
            guard pageSize > 0 else { return }
            let end = min(pageSize, positions.count)
            if end == 0 { return }
            for slotIndex in 0..<end {
                let position = positions[slotIndex]
                if let combo = position.actionCombo, combo.isEnabled {
                    // Skip combos reserved for navigation priority
                    if let n = navNext, combo.firstGesture == n.0 && combo.secondGesture == n.1 { continue }
                    if let p = navPrev, combo.firstGesture == p.0 && combo.secondGesture == p.1 { continue }
                    if let s = settingsCombo, combo.firstGesture == s.0 && combo.secondGesture == s.1 { continue }
                    if let e = editLayoutCombo, combo.firstGesture == e.0 && combo.secondGesture == e.1 { continue }
                    if let sw = swapCombo, combo.firstGesture == sw.0 && combo.secondGesture == sw.1 { continue }
                    availableCombosBySlot[combo] = slotIndex
                }
            }
            print("✅ Loaded template with \(availableCombosBySlot.count) active combos for first page (pageSize=\(pageSize))")
        }
        
        /// Configure navigation combos that should take precedence over card combos.
        func setNavigationCombos(prev: (GestureType, GestureType)?, next: (GestureType, GestureType)?) {
            self.navPrev = prev
            self.navNext = next
        }
        
        /// Configure settings combo (priority 3, after nav prev/next)
        func setSettingsCombo(_ combo: (GestureType, GestureType)?) {
            self.settingsCombo = combo
        }
        
        /// Configure edit layout combo (priority 4, after settings)
        func setEditLayoutCombo(_ combo: (GestureType, GestureType)?) {
            self.editLayoutCombo = combo
        }
        
        /// Configure swap combo (priority 5, after edit layout)
        func setSwapCombo(_ combo: (GestureType, GestureType)?) {
            self.swapCombo = combo
        }
        
        /// Load menu-specific combos directly (for Settings/Keyboard menus)
        /// This avoids creating temporary GridPosition objects that might interfere with the database
        func loadMenuCombos(_ menuComboMap: [ActionCombo: Int]) {
            availableCombosBySlot.removeAll()
            guard !menuComboMap.isEmpty else { return }
            
            // Sort by actionId to ensure consistent slot mapping
            let sortedCombos = menuComboMap.sorted { $0.value < $1.value }
            
            for (index, (combo, actionId)) in sortedCombos.enumerated() {
                if combo.isEnabled {
                    // Skip combos reserved for navigation priority
                    if let n = navNext, combo.firstGesture == n.0 && combo.secondGesture == n.1 { continue }
                    if let p = navPrev, combo.firstGesture == p.0 && combo.secondGesture == p.1 { continue }
                    if let s = settingsCombo, combo.firstGesture == s.0 && combo.secondGesture == s.1 { continue }
                    if let e = editLayoutCombo, combo.firstGesture == e.0 && combo.secondGesture == e.1 { continue }
                    if let sw = swapCombo, combo.firstGesture == sw.0 && combo.secondGesture == sw.1 { continue }
                    // Use the index as the slot (0-based)
                    availableCombosBySlot[combo] = index
                }
            }
            print("✅ Loaded \(availableCombosBySlot.count) menu-specific combos")
        }
        
        /// Reset gesture sequence
        func reset() {
            print("🔄 Resetting gesture sequence")
            gestureSequence.removeAll()
            lastGestureTime = nil
        }
        
        /// Return remaining time fraction (1.0 → just registered, 0.0 → expired)
        /// Safe to call from UI refresh timers to drive countdown visuals.
        func remainingTimeFraction(referenceDate: Date = Date()) -> Double {
            guard let last = lastGestureTime, timingWindow > 0 else { return 0 }
            let elapsed = referenceDate.timeIntervalSince(last)
            let remaining = max(0, timingWindow - elapsed)
            return max(0, min(1, remaining / timingWindow))
        }
        
        // MARK: - Private Methods
        
        private func checkForMatch() {
            // Get last 2 gestures
            let recent = gestureSequence.suffix(2)
            guard recent.count == 2 else { return }
            
            let first = recent[recent.startIndex]
            let second = recent[recent.index(after: recent.startIndex)]
            
            print("🔍 Checking for match: \(first.rawValue) → \(second.rawValue)")
            
            // 1) High-priority navigation combos
            if let n = navNext, first == n.0 && second == n.1 {
                let combo = ActionCombo(name: "Navigate Next", firstGesture: n.0, secondGesture: n.1)
                onComboMatchedBySlot?(combo, -1) // special slot index for navigation
                reset()
                return
            }
            if let p = navPrev, first == p.0 && second == p.1 {
                let combo = ActionCombo(name: "Navigate Previous", firstGesture: p.0, secondGesture: p.1)
                onComboMatchedBySlot?(combo, -2)
                reset()
                return
            }
            // 2) Settings combo (priority 3)
            if let s = settingsCombo, first == s.0 && second == s.1 {
                let combo = ActionCombo(name: "Settings", firstGesture: s.0, secondGesture: s.1)
                onComboMatchedBySlot?(combo, -3) // special slot index for settings
                reset()
                return
            }
            // 3) Edit Layout combo (priority 4)
            print("editLayoutCombo: \(editLayoutCombo)")
            if let e = editLayoutCombo, first == e.0 && second == e.1 {
                let combo = ActionCombo(name: "Edit Layout", firstGesture: e.0, secondGesture: e.1)
                onComboMatchedBySlot?(combo, -4) // special slot index for edit layout
                reset()
                return
            }
            // 4) Swap combo (priority 5)
            if let sw = swapCombo, first == sw.0 && second == sw.1 {
                let combo = ActionCombo(name: "Swap", firstGesture: sw.0, secondGesture: sw.1)
                onComboMatchedBySlot?(combo, -5) // special slot index for swap
                reset()
                return
            }
            
            // 4) Find matching combo by template
            for (combo, slotIndex) in availableCombosBySlot {
                if combo.firstGesture == first && combo.secondGesture == second {
                    print("✨ MATCH FOUND! Combo: \(combo.name) at slot #\(slotIndex)")
                    onComboMatchedBySlot?(combo, slotIndex)
                    reset()
                    return
                }
            }
            
            print("❌ No match found")
        }
    }
