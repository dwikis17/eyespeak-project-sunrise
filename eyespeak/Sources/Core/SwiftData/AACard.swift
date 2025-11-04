//
//  AACard.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import Foundation
import SwiftData
import SwiftUI

@Model
public class AACard {
    public var id: UUID
    var title: String
    var colorHex: String
    @Attribute(.externalStorage) var imageData: Data?
    var timesPressed: Int
    var createdAt: Date
    
    // Convenience to access SwiftUI Color from stored hex
    var color: Color {
        Color(hex: colorHex) ?? Color(uiColor: .systemBackground)
    }
    
    init(title: String, imageData: Data? = nil, colorHex: String = "#3B82F6") {
        self.id = UUID()
        self.title = title
        self.colorHex = colorHex
        self.imageData = imageData
        self.timesPressed = 0
        self.createdAt = Date()
    }
}
