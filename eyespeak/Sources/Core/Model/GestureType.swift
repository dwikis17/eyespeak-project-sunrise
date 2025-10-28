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
        case .winkLeft: return "eye.slash"
        case .winkRight: return "eye.slash.fill"
        case .blink: return "eye"
        case .mouthOpen: return "face.smiling"
        case .raiseEyebrows: return "face.smiling.fill"
        case .lipPuckerLeft: return "mouth"
        case .lipPuckerRight: return "mouth"
        case .smile: return "face.smiling"
        }
    }
}
