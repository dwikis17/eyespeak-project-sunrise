//
//  AvailableActionsView.swift
//  eyespeak
//
//  Created by Dwiki on 07/11/25.
//

import SwiftUI

struct AvailableActionsView: View {
    var body: some View {
        HStack {
            VStack(alignment:.leading, spacing: 15) {
                Text("Available Actions")
                    .font(Typography.boldHeader)
                Text("Select which movements you can do comfortably")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
               
                VStack {
                    NavigationCard(
                        title: "Edit Actions",
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
    AvailableActionsView()
}

