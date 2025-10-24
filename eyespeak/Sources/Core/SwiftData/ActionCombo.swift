import Foundation
import SwiftData

@Model
public class ActionCombo {
    public var id: UUID
    var name: String
    var firstGesture: GestureType
    var secondGesture: GestureType
    var isEnabled: Bool

    init(name: String, firstGesture: GestureType, secondGesture: GestureType) {
        self.id = UUID()
        self.name = name
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
        self.isEnabled = true
    }
}
