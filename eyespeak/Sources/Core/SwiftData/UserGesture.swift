//
//  UserGesture.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import Foundation
import SwiftData

@Model
public class UserGesture {
    public var id: UUID
    var gestureType: GestureType
    var isEnabled: Bool
    var displayName: String
    var iconName: String
    var order: Int

    init(
        id: UUID,
        gestureType: GestureType,
        isEnabled: Bool,
        displayName: String,
        iconName: String,
        order: Int
    ) {
        self.id = id
        self.gestureType = gestureType
        self.isEnabled = isEnabled
        self.displayName = displayName
        self.iconName = iconName
        self.order = order
    }

    // Convenience initializer
    init(gestureType: GestureType, isEnabled: Bool = false, order: Int) {
        self.id = UUID()
        self.gestureType = gestureType
        self.isEnabled = isEnabled
        self.displayName = gestureType.rawValue
        self.iconName = gestureType.iconName
        self.order = order
    }
}
