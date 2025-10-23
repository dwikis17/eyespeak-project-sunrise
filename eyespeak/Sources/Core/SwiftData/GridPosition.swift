import Foundation
import SwiftData

@Model
public class GridPosition {
    public var id: UUID
    var card: AACard?
    var actionCombo: ActionCombo?
    var order: Int
    
    init(order: Int) {
        self.id = UUID()
        self.order = order
    }
}
