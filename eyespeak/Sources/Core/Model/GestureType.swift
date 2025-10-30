//
//  GestureType.swift
//  eyespeak
//
//  Created by Dwiki on 17/10/25.
//

import Foundation

public enum GestureType: String, Codable, CaseIterable {
    case lookLeft = "Look Left"
    case lookRight = "Look Right"
    case lookUp = "Look Up"
    case lookDown = "Look Down"
    case winkLeft = "Wink Left"
    case winkRight = "Wink Right"
    case blink = "Blink"
    case mouthOpen = "Mouth Open"
    case raiseEyebrows = "Raise Eyebrows"
    case lipPuckerLeft = "Lip Pucker Left"
    case lipPuckerRight = "Lip Pucker Right"
    case smile = "Smile"
    
    public var iconName: String {
        switch self {
        case .lookLeft: return "arrow.left"
        case .lookRight: return "arrow.right"
        case .lookUp: return "arrow.up"
        case .lookDown: return "arrow.down"
        case .winkLeft: return "eye.square"         // Unique for left wink
        case .winkRight: return "eye.square.fill"   // Unique for right wink
        case .blink: return "eye.fill"              // Distinguish from open eye
        case .mouthOpen: return "mouth"             // Unique for open mouth
        case .raiseEyebrows: return "eyebrow"       // Use a custom or symbolic icon if available
        case .lipPuckerLeft: return "person.circle"    // Suggesting a left mouth pucker (custom, fallback to "mouth" if nonexistent)
        case .lipPuckerRight: return "person.circle.fill"  // Suggesting a right mouth pucker (custom, fallback to "mouth" if nonexistent)
        case .smile: return "face.smiling"          // Standard smile
        }
    }
    
    public var displayName: String {
        return self.rawValue
    }
}
