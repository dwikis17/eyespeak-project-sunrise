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
            AACard(title: "HOW ARE YOU", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue),
            AACard(title: "YES", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue),
            AACard(title: "NO", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue),
            AACard(title: "THANK YOU", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue),
            AACard(title: "PLEASE", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue),
            
            // People & Pronouns
            AACard(title: "I'M GOOD", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue),
            AACard(title: "I LOVE YOU", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue),
            AACard(title: "I'M HAPPY", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue),
            AACard(title: "I'M SAD", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue),
            AACard(title: "I'M FRUSTRATED", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
            
            // Emotions & Feelings
            AACard(title: "THIRSTY", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
            AACard(title: "HUNGRY", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
            AACard(title: "BATHROOM", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),

            // Activities & Actions
            AACard(title: "FAMILY", imageData: nil, colorHex: CustomColor.widowPurple.rawValue),
            AACard(title: "FRIENDS", imageData: nil, colorHex: CustomColor.widowPurple.rawValue),

            
            // Descriptors
            AACard(title: "REPOSITION ME", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
            AACard(title: "TIRED", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
            AACard(title: "HOT/COLD", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue),
         
            
            // Places
            AACard(title: "DOCTOR", imageData: nil, colorHex: CustomColor.widowPurple.rawValue),
            AACard(title: "NURSE", imageData: nil, colorHex: CustomColor.widowPurple.rawValue),
   
            // Time & Questions
            AACard(title: "MORE", imageData: nil, colorHex: CustomColor.charmingYellow.rawValue),
            AACard(title: "LESS", imageData: nil, colorHex: CustomColor.charmingYellow.rawValue),
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
        let settings = UserSettings()
        let navNext = settings.navNextCombo
        let navPrev = settings.navPrevCombo
        for index in 0..<gridSize {
            let position = GridPosition(order: index)
            
            // Assign cards cyclically - prioritize essential communication cards
            if index < cards.count {
                position.card = cards[index]
            }
            
            // Assign combos cyclically, but avoid navigation combos if configured
            if !combos.isEmpty {
                var assigned = combos[index % combos.count]
                if let n = navNext, assigned.firstGesture == n.0 && assigned.secondGesture == n.1 {
                    // choose next non-conflicting combo
                    if let alt = combos.first(where: { c in
                        !(navNext?.0 == c.firstGesture && navNext?.1 == c.secondGesture) &&
                        !(navPrev?.0 == c.firstGesture && navPrev?.1 == c.secondGesture)
                    }) { assigned = alt }
                } else if let p = navPrev, assigned.firstGesture == p.0 && assigned.secondGesture == p.1 {
                    if let alt = combos.first(where: { c in
                        !(navNext?.0 == c.firstGesture && navNext?.1 == c.secondGesture) &&
                        !(navPrev?.0 == c.firstGesture && navPrev?.1 == c.secondGesture)
                    }) { assigned = alt }
                }
                position.actionCombo = assigned
            }
            
            context.insert(position)
        }
        
        populateUserGesture(context:context)
        
        try? context.save()
    }
    
    private static func populateUserGesture(context: ModelContext) {
        let descriptor = FetchDescriptor<UserGesture>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            for (index, gestureType) in GestureType.allCases.enumerated() {
                let userGesture = UserGesture(gestureType: gestureType, isEnabled: true, order: index)
                context.insert(userGesture)
            }
            
        }
    }
}


extension SampleData {
    static var sampleCards: [AACard] = [
        AACard(title: "Hello", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Yes", imageData: nil, colorHex: "#22C55E"),
        AACard(title: "No", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "Help", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "Thank You", imageData: nil, colorHex: "#22C55E"),
        AACard(title: "Please", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Sorry", imageData: nil, colorHex: "#A855F7"),
        AACard(title: "Goodbye", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Excuse Me", imageData: nil, colorHex: "#A855F7"),
        AACard(title: "Okay", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Water", imageData: nil, colorHex: "#06B6D4"),
        AACard(title: "Food", imageData: nil, colorHex: "#F97316"),
        AACard(title: "Bathroom", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Sleep", imageData: nil, colorHex: "#6366F1"),
        AACard(title: "Medicine", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "Pain", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "Happy", imageData: nil, colorHex: "#F59E0B"),
        AACard(title: "Sad", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Angry", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "Love", imageData: nil, colorHex: "#EC4899"),
        AACard(title: "Play", imageData: nil, colorHex: "#F97316"),
        AACard(title: "Read", imageData: nil, colorHex: "#A855F7"),
        AACard(title: "Watch TV", imageData: nil, colorHex: "#3B82F6"),
        AACard(title: "Listen", imageData: nil, colorHex: "#06B6D4"),
        AACard(title: "Go", imageData: nil, colorHex: "#22C55E"),
        AACard(title: "Stop", imageData: nil, colorHex: "#EF4444"),
        AACard(title: "More", imageData: nil, colorHex: "#22C55E"),
        AACard(title: "All Done", imageData: nil, colorHex: "#22C55E")
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
