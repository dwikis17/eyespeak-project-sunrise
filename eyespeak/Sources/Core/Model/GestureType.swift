//
//  GestureType.swift
//  eyespeak
//
//  Created by Dwiki on 17/10/25.
//

import Foundation

public enum GestureType: String, Codable, CaseIterable, Hashable {
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
        case .winkLeft: return "L"
        case .winkRight: return "R"
        case .blink: return "B"
        case .mouthOpen: return "M"
        case .raiseEyebrows: return "raise_eyebrow"
        case .lipPuckerLeft: return "LL"
        case .lipPuckerRight: return "LR"
        case .smile: return "face.smiling"
        }
    }

    /// Returns the asset name used in the legend for gestures that have custom artwork.
    public var legendAssetName: String? {
        switch self {
        case .lookLeft: return "LeftArrow"
        case .lookRight: return "RightArrow"
        case .lookUp: return "UpArrow"
        case .lookDown: return "DownArrow"
        case .winkLeft: return "L"
        case .winkRight: return "R"
        case .blink: return "B"
        case .mouthOpen: return "M"
        case .raiseEyebrows: return "raise_eyebrow"
        case .lipPuckerLeft: return "LL"
        case .lipPuckerRight: return "LR"
        default: return nil
        }
    }
    
    public var displayName: String {
        return self.rawValue
    }
}
