//
//  ActionListSelection.swift
//  eyespeak
//
//  Created by Dwiki on 12/11/25.
//

import SwiftUI

struct ActionListSelection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Available Actions")
                .font(Typography.boldHeader)
            Text("Select which movements you can do comfortably")
                .font(Typography.regularTitle)
                .foregroundStyle(Color.placeholder)
        }
    }
}

#Preview {
    ActionListSelection()
}
