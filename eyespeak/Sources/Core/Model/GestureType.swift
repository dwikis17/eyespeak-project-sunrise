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
    
    public var iconName: String {
        switch self {
        case .lookLeft: return "arrow.left"
        case .lookRight: return "arrow.right"
        case .lookUp: return "arrow.up"
        case .lookDown: return "arrow.down"
        case .winkLeft: return "eye.slash"
        case .winkRight: return "eye.slash.fill"
        case .blink: return "eye"
        }
    }
}
