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
            AACard(title: "HOW ARE YOU", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue, image: "questionmark"),
            AACard(title: "YES", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue, image:"yes"),
            AACard(title: "NO", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue,image:"no"),
            AACard(title: "THANK YOU", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue, image: "thankyou"),
            AACard(title: "PLEASE", imageData: nil, colorHex: CustomColor.oldHulkGreen.rawValue, image: "questionmark"),
            
            // People & Pronouns
            AACard(title: "I'M GOOD", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue, image: "imgood"),
            AACard(title: "I LOVE YOU", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue, image: "iloveyou"),
            AACard(title: "I'M HAPPY", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue,image: "imhappy"),
            AACard(title: "I'M SAD", imageData: nil, colorHex: CustomColor.mellowBlue.rawValue, image: "imsad"),
            AACard(title: "I'M FRUSTRATED", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "imfrustrated"),
            
            // Emotions & Feelings
            AACard(title: "THIRSTY", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "thirsty"),
            AACard(title: "HUNGRY", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "hungry"),
            AACard(title: "BATHROOM", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "bathroom"),

            // Activities & Actions
            AACard(title: "FAMILY", imageData: nil, colorHex: CustomColor.widowPurple.rawValue, image: "family"),
            AACard(title: "FRIENDS", imageData: nil, colorHex: CustomColor.widowPurple.rawValue, image: "friends"),

            
            // Descriptors
            AACard(title: "REPOSITION ME", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "reposition"),
            AACard(title: "TIRED", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "tired"),
            AACard(title: "HOT/COLD", imageData: nil, colorHex: CustomColor.energeticOrange.rawValue, image: "hotcold"),
         
            
            // Places
            AACard(title: "DOCTOR", imageData: nil, colorHex: CustomColor.widowPurple.rawValue, image: "doctor"),
            AACard(title: "NURSE", imageData: nil, colorHex: CustomColor.widowPurple.rawValue, image: "nurse"),
   
            // Time & Questions
            AACard(title: "MORE", imageData: nil, colorHex: CustomColor.charmingYellow.rawValue, image: "more"),
            AACard(title: "LESS", imageData: nil, colorHex: CustomColor.charmingYellow.rawValue, image: "less"),
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
        let settingsCombo = settings.settingsCombo
        let editLayoutCombo = settings.editLayoutCombo
        let swapCombo = settings.swapCombo
        let deleteCombo = settings.deleteCombo
        let decrementTimerCombo = settings.decrementTimerCombo
        let incrementTimerCombo = settings.incrementTimerCombo
        let fontSmallCombo = settings.fontSmallCombo
        let fontMediumCombo = settings.fontMediumCombo
        let fontBigCombo = settings.fontBigCombo
        
        for index in 0..<gridSize {
            let position = GridPosition(order: index)
            
            // Assign cards cyclically - prioritize essential communication cards
            if index < cards.count {
                position.card = cards[index]
            }
            
            // Assign combos cyclically, but avoid priority combos (nav, settings, edit layout) if configured
            if !combos.isEmpty {
                var assigned = combos[index % combos.count]
                let isNavNext = navNext != nil && assigned.firstGesture == navNext!.0 && assigned.secondGesture == navNext!.1
                let isNavPrev = navPrev != nil && assigned.firstGesture == navPrev!.0 && assigned.secondGesture == navPrev!.1
                let isSettings = settingsCombo != nil && assigned.firstGesture == settingsCombo!.0 && assigned.secondGesture == settingsCombo!.1
                let isEditLayout = editLayoutCombo != nil && assigned.firstGesture == editLayoutCombo!.0 && assigned.secondGesture == editLayoutCombo!.1
                let isSwap = swapCombo != nil && assigned.firstGesture == swapCombo!.0 && assigned.secondGesture == swapCombo!.1
                let isDelete = deleteCombo != nil && assigned.firstGesture == deleteCombo!.0 && assigned.secondGesture == deleteCombo!.1
                let isDecrementTimer = decrementTimerCombo != nil && assigned.firstGesture == decrementTimerCombo!.0 && assigned.secondGesture == decrementTimerCombo!.1
                let isIncrementTimer = incrementTimerCombo != nil && assigned.firstGesture == incrementTimerCombo!.0 && assigned.secondGesture == incrementTimerCombo!.1
                let isFontSmall = fontSmallCombo != nil && assigned.firstGesture == fontSmallCombo!.0 && assigned.secondGesture == fontSmallCombo!.1
                let isFontMedium = fontMediumCombo != nil && assigned.firstGesture == fontMediumCombo!.0 && assigned.secondGesture == fontMediumCombo!.1
                let isFontBig = fontBigCombo != nil && assigned.firstGesture == fontBigCombo!.0 && assigned.secondGesture == fontBigCombo!.1
                if isNavNext || isNavPrev || isSettings || isEditLayout || isSwap || isDelete || isDecrementTimer || isIncrementTimer || isFontSmall || isFontMedium || isFontBig {
                    // choose next non-conflicting combo
                    if let alt = combos.first(where: { c in
                        let isNavNextAlt = navNext != nil && c.firstGesture == navNext!.0 && c.secondGesture == navNext!.1
                        let isNavPrevAlt = navPrev != nil && c.firstGesture == navPrev!.0 && c.secondGesture == navPrev!.1
                        let isSettingsAlt = settingsCombo != nil && c.firstGesture == settingsCombo!.0 && c.secondGesture == settingsCombo!.1
                        let isEditLayoutAlt = editLayoutCombo != nil && c.firstGesture == editLayoutCombo!.0 && c.secondGesture == editLayoutCombo!.1
                        let isSwapAlt = swapCombo != nil && c.firstGesture == swapCombo!.0 && c.secondGesture == swapCombo!.1
                        let isDeleteAlt = deleteCombo != nil && c.firstGesture == deleteCombo!.0 && c.secondGesture == deleteCombo!.1
                        let isDecrementTimerAlt = decrementTimerCombo != nil && c.firstGesture == decrementTimerCombo!.0 && c.secondGesture == decrementTimerCombo!.1
                        let isIncrementTimerAlt = incrementTimerCombo != nil && c.firstGesture == incrementTimerCombo!.0 && c.secondGesture == incrementTimerCombo!.1
                        let isFontSmallAlt = fontSmallCombo != nil && c.firstGesture == fontSmallCombo!.0 && c.secondGesture == fontSmallCombo!.1
                        let isFontMediumAlt = fontMediumCombo != nil && c.firstGesture == fontMediumCombo!.0 && c.secondGesture == fontMediumCombo!.1
                        let isFontBigAlt = fontBigCombo != nil && c.firstGesture == fontBigCombo!.0 && c.secondGesture == fontBigCombo!.1
                        return !isNavNextAlt && !isNavPrevAlt && !isSettingsAlt && !isEditLayoutAlt && !isSwapAlt && !isDeleteAlt && !isDecrementTimerAlt && !isIncrementTimerAlt && !isFontSmallAlt && !isFontMediumAlt && !isFontBigAlt
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
