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
        
        /// Reset gesture sequence
        func reset() {
            print("🔄 Resetting gesture sequence")
            gestureSequence.removeAll()
            lastGestureTime = nil
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
            
            // 2) Find matching combo by template
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
