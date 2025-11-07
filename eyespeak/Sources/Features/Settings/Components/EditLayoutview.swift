//
//  EditLayoutview.swift
//  eyespeak
//
//  Created by Dwiki on 07/11/25.
//

import SwiftUI

struct EditLayoutview: View {
    var body: some View {
        HStack {
            VStack(alignment:.leading, spacing: 15) {
                Text("Edit Layout")
                    .font(Typography.boldHeader)
                Text("Customize your own AAC Board Layout")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
               
                VStack {
                    NavigationCard(
                        title: "Edit Layout",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: nil,
                        secondCombo: nil
                    ) {
                        print("Hello")
                    }
                }
                .frame(width: 200)
                
            }
            Spacer()
        }
    }
}

#Preview {
    EditLayoutview()
}
