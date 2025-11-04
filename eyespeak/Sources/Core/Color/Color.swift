//
//  Color.swift
//  eyespeak
//
//  Created by Dwiki on 03/11/25.
//

import SwiftUI

extension Color {
    static let customBlue = Color(red: 88/255, green: 108/255, blue: 157/255, opacity: 1.0)

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
    case blue = "#586C9D"
    case green = "#2FA553"
    case orange = "FE773C"
    case purple = "AD6AE3"
    case yellow = "F6CA33"
}