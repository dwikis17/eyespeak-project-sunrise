//
//  File.swift
//  eyespeak
//
//  Created by Dwiki on 30/10/25.
//

import Foundation
import SwiftUI

extension LinearGradient {
    /// Orange Gradient - From #F6924F to #E21E1E
    static let orangeGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#E21E1E")!,
            Color(hex: "#F6924F")!
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Legacy alias (backward compatibility)
    static let redOrange = LinearGradient.orangeGradient
}
