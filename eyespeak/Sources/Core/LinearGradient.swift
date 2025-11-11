//
//  File.swift
//  eyespeak
//
//  Created by Dwiki on 30/10/25.
//

import Foundation
import SwiftUI

extension LinearGradient {
    static let redOrange = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#E21E1E")!,
            Color(hex: "#F6924F")!
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
}
