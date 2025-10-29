//
//  SampleData.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import Foundation
import SwiftData

struct SampleData {
    
    static func populate(context: ModelContext, gridSize: Int = 25) {
        // Sample Cards - Expanded Essential Communication Vocabulary
        let cards = [
            // Basic Communication
            AACard(title: "Hello", imageData: nil),
            AACard(title: "Yes", imageData: nil),
            AACard(title: "No", imageData: nil),
            AACard(title: "Help", imageData: nil),
            AACard(title: "Thank You", imageData: nil),
            AACard(title: "Please", imageData: nil),
            AACard(title: "Sorry", imageData: nil),
            AACard(title: "Goodbye", imageData: nil),
            AACard(title: "Excuse Me", imageData: nil),
            AACard(title: "Great", imageData: nil),
            AACard(title: "Okay", imageData: nil),
            
            // People & Pronouns
            AACard(title: "I", imageData: nil),
            AACard(title: "You", imageData: nil),
            AACard(title: "We", imageData: nil),
            AACard(title: "They", imageData: nil),
            AACard(title: "Mom", imageData: nil),
            AACard(title: "Dad", imageData: nil),
            AACard(title: "Friend", imageData: nil),
            AACard(title: "Teacher", imageData: nil),
            AACard(title: "Doctor", imageData: nil),
            
            // Basic Needs
            AACard(title: "Water", imageData: nil),
            AACard(title: "Food", imageData: nil),
            AACard(title: "Drink", imageData: nil),
            AACard(title: "Bathroom", imageData: nil),
            AACard(title: "Sleep", imageData: nil),
            AACard(title: "Medicine", imageData: nil),
            AACard(title: "Pain", imageData: nil),
            AACard(title: "Tired", imageData: nil),
            AACard(title: "Cold", imageData: nil),
            AACard(title: "Hot", imageData: nil),
            
            // Emotions & Feelings
            AACard(title: "Happy", imageData: nil),
            AACard(title: "Sad", imageData: nil),
            AACard(title: "Angry", imageData: nil),
            AACard(title: "Scared", imageData: nil),
            AACard(title: "Love", imageData: nil),
            AACard(title: "Like", imageData: nil),
            AACard(title: "Don't Like", imageData: nil),
            AACard(title: "Bored", imageData: nil),
            AACard(title: "Excited", imageData: nil),
            AACard(title: "Hurt", imageData: nil),
            
            // Activities & Actions
            AACard(title: "Play", imageData: nil),
            AACard(title: "Read", imageData: nil),
            AACard(title: "Watch TV", imageData: nil),
            AACard(title: "Listen", imageData: nil),
            AACard(title: "Go", imageData: nil),
            AACard(title: "Stop", imageData: nil),
            AACard(title: "Wait", imageData: nil),
            AACard(title: "More", imageData: nil),
            AACard(title: "All Done", imageData: nil),
            AACard(title: "Again", imageData: nil),
            AACard(title: "Open", imageData: nil),
            AACard(title: "Close", imageData: nil),
            AACard(title: "Come", imageData: nil),
            AACard(title: "Leave", imageData: nil),
            AACard(title: "Turn On", imageData: nil),
            AACard(title: "Turn Off", imageData: nil),
            
            // Descriptors
            AACard(title: "Big", imageData: nil),
            AACard(title: "Small", imageData: nil),
            AACard(title: "Fast", imageData: nil),
            AACard(title: "Slow", imageData: nil),
            AACard(title: "Loud", imageData: nil),
            AACard(title: "Quiet", imageData: nil),
            AACard(title: "Good", imageData: nil),
            AACard(title: "Bad", imageData: nil),
            
            // Places
            AACard(title: "Home", imageData: nil),
            AACard(title: "School", imageData: nil),
            AACard(title: "Hospital", imageData: nil),
            AACard(title: "Outside", imageData: nil),
            AACard(title: "Store", imageData: nil),
            
            // Time & Questions
            AACard(title: "Now", imageData: nil),
            AACard(title: "Later", imageData: nil),
            AACard(title: "Today", imageData: nil),
            AACard(title: "Tomorrow", imageData: nil),
            AACard(title: "Who?", imageData: nil),
            AACard(title: "What?", imageData: nil),
            AACard(title: "Where?", imageData: nil),
            AACard(title: "When?", imageData: nil),
            AACard(title: "Why?", imageData: nil),
            AACard(title: "How?", imageData: nil)
        ]
        
        // Insert all cards
        for card in cards {
            context.insert(card)
        }
        
        // Build combos dynamically from enabled user gestures when available
        let enabledDescriptor = FetchDescriptor<UserGesture>(
            predicate: #Predicate { $0.isEnabled == true }
        )
        let enabled = (try? context.fetch(enabledDescriptor)) ?? []

        var combos: [ActionCombo] = []
        let allowed: Set<GestureType>
        if !enabled.isEmpty {
            let selected = Set(enabled.map { $0.gestureType })
            // Only include gestures supported by our detector emissions (blink and wink are excluded)
            allowed = selected.intersection([
                .lookLeft, .lookRight, .lookUp, .lookDown,
                .lipPuckerLeft, .lipPuckerRight, .raiseEyebrows, .smile
            ])
        } else {
            // Fallback default before onboarding: basic gaze directions only
            allowed = [.lookLeft, .lookRight, .lookUp, .lookDown]
        }

        func makeName(_ a: GestureType, _ b: GestureType) -> String {
            "\(a.rawValue) + \(b.rawValue)"
        }

        // Prioritize directional navigation combos if available
        if allowed.contains(.lookLeft) && allowed.contains(.lookRight) {
            combos.append(ActionCombo(name: makeName(.lookLeft, .lookRight), firstGesture: .lookLeft, secondGesture: .lookRight))
            combos.append(ActionCombo(name: makeName(.lookRight, .lookLeft), firstGesture: .lookRight, secondGesture: .lookLeft))
        }
        if allowed.contains(.lookUp) && allowed.contains(.lookDown) {
            combos.append(ActionCombo(name: makeName(.lookUp, .lookDown), firstGesture: .lookUp, secondGesture: .lookDown))
            combos.append(ActionCombo(name: makeName(.lookDown, .lookUp), firstGesture: .lookDown, secondGesture: .lookUp))
        }

        // Fill remaining combos from ordered pairs of allowed gestures (excluding identical pairs)
        let allowedList = Array(allowed)
        for first in allowedList {
            for second in allowedList where first != second {
                // Skip if already present
                if combos.contains(where: { $0.firstGesture == first && $0.secondGesture == second }) {
                    continue
                }
                combos.append(ActionCombo(name: makeName(first, second), firstGesture: first, secondGesture: second))
            }
        }

        // Insert combos
        for combo in combos { context.insert(combo) }
        
        // Sample Grid - dynamic size based on gridSize parameter
        // Use the arrays we already created
        for index in 0..<gridSize {
            let position = GridPosition(order: index)
            
            // Assign cards cyclically - prioritize essential communication cards
            if index < cards.count {
                position.card = cards[index]
            }
            
            // Assign combos cyclically
            if !combos.isEmpty { position.actionCombo = combos[index % combos.count] }
            
            context.insert(position)
        }
        
        populateUserGesture(context:context)
        
        try? context.save()
    }
    
    private static func populateUserGesture(context: ModelContext) {
        let descriptor = FetchDescriptor<UserGesture>()
        let existing = (try? context.fetch(descriptor)) ?? []
        print(existing,"EXSGIN")
        if existing.isEmpty {
            for (index, gestureType) in GestureType.allCases.enumerated() {
                let userGesture = UserGesture(gestureType: gestureType, isEnabled: false, order: index)
                print(userGesture,"USER")
                context.insert(userGesture)
            }
            
        }
    }
}


extension SampleData {
    static var sampleCards: [AACard] = [
        AACard(title: "Hello", imageData: nil),
        AACard(title: "Yes", imageData: nil),
        AACard(title: "No", imageData: nil),
        AACard(title: "Help", imageData: nil),
        AACard(title: "Thank You", imageData: nil),
        AACard(title: "Please", imageData: nil),
        AACard(title: "Sorry", imageData: nil),
        AACard(title: "Goodbye", imageData: nil),
        AACard(title: "Excuse Me", imageData: nil),
        AACard(title: "Okay", imageData: nil),
        AACard(title: "Water", imageData: nil),
        AACard(title: "Food", imageData: nil),
        AACard(title: "Bathroom", imageData: nil),
        AACard(title: "Sleep", imageData: nil),
        AACard(title: "Medicine", imageData: nil),
        AACard(title: "Pain", imageData: nil),
        AACard(title: "Happy", imageData: nil),
        AACard(title: "Sad", imageData: nil),
        AACard(title: "Angry", imageData: nil),
        AACard(title: "Love", imageData: nil),
        AACard(title: "Play", imageData: nil),
        AACard(title: "Read", imageData: nil),
        AACard(title: "Watch TV", imageData: nil),
        AACard(title: "Listen", imageData: nil),
        AACard(title: "Go", imageData: nil),
        AACard(title: "Stop", imageData: nil),
        AACard(title: "More", imageData: nil),
        AACard(title: "All Done", imageData: nil)
    ]

    static var sampleCombos: [ActionCombo] = [
        ActionCombo(name: "Look Left + Right", firstGesture: .lookLeft, secondGesture: .lookRight),
        ActionCombo(name: "Look Up + Down", firstGesture: .lookUp, secondGesture: .lookDown),
        ActionCombo(name: "Wink Left + Look Right", firstGesture: .winkLeft, secondGesture: .lookRight),
        ActionCombo(name: "Wink Right + Look Left", firstGesture: .winkRight, secondGesture: .lookLeft),
        ActionCombo(name: "Wink Left + Look Up", firstGesture: .winkLeft, secondGesture: .lookUp),
        ActionCombo(name: "Wink Right + Look Down", firstGesture: .winkRight, secondGesture: .lookDown),
    ]

    static var sampleGridPositions: [GridPosition] = [
        GridPosition(order: 0),
        GridPosition(order: 1),
        GridPosition(order: 2),
        GridPosition(order: 3),
        GridPosition(order: 4),
        GridPosition(order: 5),
        GridPosition(order: 6),
    ]

 
}
