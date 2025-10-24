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
        // Sample Cards - Essential Communication Words
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
            
            // Basic Needs
            AACard(title: "Water", imageData: nil),
            AACard(title: "Food", imageData: nil),
            AACard(title: "Bathroom", imageData: nil),
            AACard(title: "Sleep", imageData: nil),
            AACard(title: "Medicine", imageData: nil),
            AACard(title: "Pain", imageData: nil),
            AACard(title: "Tired", imageData: nil),
            
            // Emotions & Feelings
            AACard(title: "Happy", imageData: nil),
            AACard(title: "Sad", imageData: nil),
            AACard(title: "Angry", imageData: nil),
            AACard(title: "Scared", imageData: nil),
            AACard(title: "Love", imageData: nil),
            AACard(title: "Like", imageData: nil),
            AACard(title: "Don't Like", imageData: nil),
            
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
            AACard(title: "Again", imageData: nil)
        ]
        
        // Insert all cards
        for card in cards {
            context.insert(card)
        }
        
        // Sample Action Combos - Meaningful gesture combinations
        let combos = [
            // Basic Navigation
            ActionCombo(
                name: "Look Left + Right",
                firstGesture: .lookLeft,
                secondGesture: .lookRight
            ),
            ActionCombo(
                name: "Look Up + Down",
                firstGesture: .lookUp,
                secondGesture: .lookDown
            ),
            
            // Wink Combinations
            ActionCombo(
                name: "Wink Left + Look Right",
                firstGesture: .winkLeft,
                secondGesture: .lookRight
            ),
            ActionCombo(
                name: "Wink Right + Look Left",
                firstGesture: .winkRight,
                secondGesture: .lookLeft
            ),
            ActionCombo(
                name: "Wink Left + Look Up",
                firstGesture: .winkLeft,
                secondGesture: .lookUp
            ),
            ActionCombo(
                name: "Wink Right + Look Down",
                firstGesture: .winkRight,
                secondGesture: .lookDown
            ),
            
            // Blink Combinations
            ActionCombo(
                name: "Blink + Look Left",
                firstGesture: .blink,
                secondGesture: .lookLeft
            ),
            ActionCombo(
                name: "Blink + Look Right",
                firstGesture: .blink,
                secondGesture: .lookRight
            ),
            ActionCombo(
                name: "Blink + Look Up",
                firstGesture: .blink,
                secondGesture: .lookUp
            ),
            ActionCombo(
                name: "Blink + Look Down",
                firstGesture: .blink,
                secondGesture: .lookDown
            ),
            
            // Complex Patterns
            ActionCombo(
                name: "Look Up + Wink Left",
                firstGesture: .lookUp,
                secondGesture: .winkLeft
            ),
            ActionCombo(
                name: "Look Down + Wink Right",
                firstGesture: .lookDown,
                secondGesture: .winkRight
            ),
            ActionCombo(
                name: "Look Left + Blink",
                firstGesture: .lookLeft,
                secondGesture: .blink
            ),
            ActionCombo(
                name: "Look Right + Blink",
                firstGesture: .lookRight,
                secondGesture: .blink
            ),
            
            // Double Wink Patterns
            ActionCombo(
                name: "Wink Left + Wink Right",
                firstGesture: .winkLeft,
                secondGesture: .winkRight
            ),
            ActionCombo(
                name: "Wink Right + Wink Left",
                firstGesture: .winkRight,
                secondGesture: .winkLeft
            )
        ]
        
        // Insert all combos
        for combo in combos {
            context.insert(combo)
        }
        
        // Sample Grid - dynamic size based on gridSize parameter
        // Use the arrays we already created
        for index in 0..<gridSize {
            let position = GridPosition(order: index)
            
            // Assign cards cyclically - prioritize essential communication cards
            if index < cards.count {
                position.card = cards[index]
            }
            
            // Assign combos cyclically - prioritize basic navigation combos
            if index < combos.count {
                position.actionCombo = combos[index]
            }
            
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
