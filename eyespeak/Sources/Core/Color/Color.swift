//
//  Color.swift
//  eyespeak
//
//  Created by Dwiki on 03/11/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors

    /// Energetic Orange - #FE773C
    static let energeticOrange = Color(hex: "#FE773C")!

    /// Old Hulk Green - #2FA553
    static let oldHulkGreen = Color(hex: "#2FA553")!

    /// Mellow Blue - #586C9D
    static let mellowBlue = Color(hex: "#586C9D")!

    /// Widow Purple - #AD6AE3
    static let widowPurple = Color(hex: "#AD6AE3")!

    /// Charming Yellow - #F6CA33
    static let charmingYellow = Color(hex: "#F6CA33")!

    // MARK: - Black, White, and Shades

    /// White White - #FFFFFF
    static let whiteWhite = Color(hex: "#FFFFFF")!

    /// Bone White - #F2F2F2
    static let boneWhite = Color(hex: "#F2F2F2")!

    /// Placeholder - #ACACAC
    static let placeholder = Color(hex: "#ACACAC")!

    /// Blueack - #363636
    static let blueack = Color(hex: "#363636")!

    // MARK: - Legacy Support

    /// Legacy alias for mellowBlue (backward compatibility)
    static let customBlue = Color.mellowBlue

    // Initialize from hex string like "#RRGGBB" or "RRGGBB"
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}


public enum CustomColor: String {
    case energeticOrange = "#FE773C"
    case oldHulkGreen = "#2FA553"
    case mellowBlue = "#586C9D"
    case widowPurple = "#AD6AE3"
    case charmingYellow = "#F6CA33"
    case whiteWhite = "#FFFFFF"
    case boneWhite = "#F2F2F2"
    case placeholder = "#ACACAC"
    case blueack = "#363636"

    var color: Color {
        Color(hex: rawValue) ?? .clear
    }
}
