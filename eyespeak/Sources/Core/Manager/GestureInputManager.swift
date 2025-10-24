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
        
        // Matched combo callback
        var onComboMatched: ((ActionCombo, GridPosition) -> Void)?
        
        // Available combos from grid positions
        private var availableCombos: [ActionCombo: GridPosition] = [:]
        
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
        
        /// Load available combos from grid positions
        func loadCombos(from positions: [GridPosition]) {
            availableCombos.removeAll()
            
            for position in positions {
                if let combo = position.actionCombo, combo.isEnabled {
                    availableCombos[combo] = position
                }
            }
            
            print("✅ Loaded \(availableCombos.count) active combos")
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
            
            // Find matching combo
            for (combo, position) in availableCombos {
                if combo.firstGesture == first && combo.secondGesture == second {
                    print("✨ MATCH FOUND! Combo: \(combo.name)")
                    onComboMatched?(combo, position)
                    reset()
                    return
                }
            }
            
            print("❌ No match found")
        }
    }
