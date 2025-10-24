//
//  AACard.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import Foundation
import SwiftData

@Model
public class AACard {
    public var id: UUID
    var title: String
    @Attribute(.externalStorage) var imageData: Data?
    var timesPressed: Int
    var createdAt: Date
    
    init(title: String, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.imageData = imageData
        self.timesPressed = 0
        self.createdAt = Date()
    }
}
