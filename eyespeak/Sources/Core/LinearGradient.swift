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
            Color(red: 226/255, green: 30/255, blue: 30/255),
            Color(red: 246/255, green: 146/255, blue: 79/255)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
}
